"""Cliente simples para testar o WebSocket /ws/detectar sem o app.

Exemplos:
    python cliente_teste.py                                  # imagem de exemplo (ônibus) em loop, 8 FPS, 15 s
    python cliente_teste.py --fonte webcam --mostrar         # webcam do Mac com as caixas desenhadas
    python cliente_teste.py --fonte fotos/ --fps 10          # pasta de imagens em loop
    python cliente_teste.py --url ws://192.168.0.20:8000/ws/detectar
    python cliente_teste.py --sem-controle --fps 30          # rajada sem esperar resposta: mostra os descartes

Mede FPS, latência (captura → detecções de volta) e tempo de inferência, como o app faz:
um quadro em trânsito por vez, latência medida no relógio do próprio cliente.
"""

import argparse
import asyncio
import json
import statistics
import sys
import time
from pathlib import Path

import cv2
import numpy as np
import websockets

sys.path.insert(0, str(Path(__file__).resolve().parent))
from app.protocolo import montar_quadro  # noqa: E402


def abrir_fonte(fonte: str):
    """Devolve uma função que entrega o próximo quadro BGR."""
    if fonte == "webcam":
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            sys.exit("Não consegui abrir a webcam. No macOS, permita o acesso à câmera para o Terminal.")
        return lambda: cap.read()[1]
    if fonte == "exemplo":
        import ultralytics

        caminhos = [Path(ultralytics.__file__).parent / "assets" / "bus.jpg"]
    else:
        p = Path(fonte)
        caminhos = sorted(x for x in (p.iterdir() if p.is_dir() else [p]) if x.suffix.lower() in (".jpg", ".jpeg", ".png"))
        if not caminhos:
            sys.exit(f"Nenhuma imagem encontrada em {fonte}")
    imagens = [cv2.imread(str(c)) for c in caminhos]
    i = 0

    def proximo():
        nonlocal i
        img = imagens[i % len(imagens)]
        i += 1
        return img

    return proximo


def preparar(img: np.ndarray, largura: int, altura: int, qualidade: int) -> bytes:
    """Redimensiona mantendo a proporção (corte central) e comprime em JPEG."""
    h, w = img.shape[:2]
    escala = max(largura / w, altura / h)
    img = cv2.resize(img, (round(w * escala), round(h * escala)))
    h, w = img.shape[:2]
    x, y = (w - largura) // 2, (h - altura) // 2
    img = img[y : y + altura, x : x + largura]
    return cv2.imencode(".jpg", img, [cv2.IMWRITE_JPEG_QUALITY, qualidade])[1].tobytes()


def desenhar(jpeg: bytes, resp: dict) -> None:
    img = cv2.imdecode(np.frombuffer(jpeg, np.uint8), cv2.IMREAD_COLOR)
    h, w = img.shape[:2]
    for d in resp.get("deteccoes", []):
        c = d["caixa"]
        p1, p2 = (int(c["x1"] * w), int(c["y1"] * h)), (int(c["x2"] * w), int(c["y2"] * h))
        cv2.rectangle(img, p1, p2, (61, 112, 194), 2)
        cv2.putText(img, f'{d["classe"]} {d["confianca"]:.0%}', (p1[0], max(14, p1[1] - 6)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
    cv2.imshow("TracePro · cliente de teste (q para sair)", img)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        raise KeyboardInterrupt


async def rodar(a: argparse.Namespace) -> None:
    proximo = abrir_fonte(a.fonte)
    intervalo = 1 / a.fps
    lat, inf, recebidas, descartes, erros = [], [], 0, 0, 0
    print(f"Conectando em {a.url} …")
    async with websockets.connect(a.url, max_size=None) as ws:
        await ws.send(json.dumps({"tipo": "status"}))
        st = json.loads(await ws.recv())
        print(f"Servidor: modelo {st.get('modelo')} em {st.get('dispositivo')} · versão {st.get('versao')}")
        if a.confianca is not None or a.classes is not None:
            cfg = {"tipo": "config", "confianca": a.confianca, "classes": [int(x) for x in a.classes.split(",")] if a.classes else None}
            await ws.send(json.dumps(cfg))
            print("Parâmetros:", json.loads(await ws.recv()))

        fim = time.monotonic() + a.segundos
        seq, ultimo_envio, ultimo_relatorio = 0, 0.0, time.monotonic()
        enviados: dict[int, bytes] = {}
        em_transito = 0
        while time.monotonic() < fim:
            agora = time.monotonic()
            pode_enviar = agora - ultimo_envio >= intervalo and (a.sem_controle or em_transito == 0)
            if pode_enviar:
                seq += 1
                quadro = preparar(proximo(), a.largura, a.altura, a.qualidade)
                await ws.send(montar_quadro(seq, quadro, capturado_em=time.time() * 1000))
                enviados[seq] = quadro
                em_transito += 1
                ultimo_envio = agora
            try:
                msg = json.loads(await asyncio.wait_for(ws.recv(), timeout=max(0.001, intervalo - (time.monotonic() - ultimo_envio))))
            except asyncio.TimeoutError:
                continue
            tipo = msg.get("tipo")
            if tipo in ("deteccoes", "descartado", "erro") and msg.get("seq") in enviados:
                em_transito = max(0, em_transito - 1)
            if tipo == "deteccoes":
                recebidas += 1
                lat.append(time.time() * 1000 - msg["capturado_em"])
                inf.append(msg["inferencia_ms"])
                if a.mostrar:
                    desenhar(enviados[msg["seq"]], msg)
                enviados = {k: v for k, v in enviados.items() if k > msg["seq"]}
            elif tipo == "descartado":
                descartes += 1
            elif tipo == "erro":
                erros += 1
                print("Erro:", msg)
            if time.monotonic() - ultimo_relatorio >= 1 and lat:
                rec = lat[-a.fps * 2 :]
                print(f"FPS {recebidas / (time.monotonic() - (fim - a.segundos)):4.1f} · latência {statistics.mean(rec):5.0f} ms · "
                      f"inferência {statistics.mean(inf[-len(rec):]):4.0f} ms · descartados {descartes}")
                ultimo_relatorio = time.monotonic()

    if lat:
        lat.sort()
        p95 = lat[int(len(lat) * 0.95) - 1] if len(lat) > 1 else lat[0]
        print(f"\nResumo: {recebidas} respostas em {a.segundos} s · latência média {statistics.mean(lat):.0f} ms · "
              f"p95 {p95:.0f} ms · inferência média {statistics.mean(inf):.0f} ms · descartados {descartes} · erros {erros}")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--url", default="ws://localhost:8000/ws/detectar")
    p.add_argument("--fonte", default="exemplo", help='"exemplo", "webcam", uma imagem ou uma pasta')
    p.add_argument("--fps", type=int, default=8)
    p.add_argument("--largura", type=int, default=640)
    p.add_argument("--altura", type=int, default=480)
    p.add_argument("--qualidade", type=int, default=70)
    p.add_argument("--segundos", type=int, default=15)
    p.add_argument("--confianca", type=float)
    p.add_argument("--classes", help="ids separados por vírgula, ex.: 0,5")
    p.add_argument("--mostrar", action="store_true", help="abre uma janela com as caixas")
    p.add_argument("--sem-controle", action="store_true", help="envia sem esperar resposta (para ver os descartes)")
    try:
        asyncio.run(rodar(p.parse_args()))
    except KeyboardInterrupt:
        pass
    except OSError as e:
        sys.exit(f"Não consegui conectar: {e}. A API está rodando (python -m app)?")


if __name__ == "__main__":
    main()

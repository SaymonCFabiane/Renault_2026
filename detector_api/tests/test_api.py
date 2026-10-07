"""Testes da API: protocolo, HTTP e WebSocket (com o YOLO real e com um detector lento falso)."""

import asyncio
import time
from pathlib import Path

import cv2
import numpy as np
import pytest
import ultralytics
from fastapi.testclient import TestClient

from app.config import Config
from app.main import criar_app
from app.protocolo import Codigo, ErroProtocolo, Parametros, Resultado, ler_quadro, montar_quadro

BUS = Path(ultralytics.__file__).parent / "assets" / "bus.jpg"  # 810×1080, pessoas e um ônibus


def jpeg(img: np.ndarray, q: int = 70) -> bytes:
    return cv2.imencode(".jpg", img, [cv2.IMWRITE_JPEG_QUALITY, q])[1].tobytes()


def bus_640x480() -> bytes:
    img = cv2.imread(str(BUS))
    return jpeg(cv2.resize(img, (480, 640)))  # retrato 480×640, como a câmera "em pé"


# ===== Protocolo =====
def test_quadro_valido():
    q = ler_quadro(montar_quadro(7, b"\xff\xd8abc", 123.0, 90), 10_000)
    assert (q.seq, q.capturado_em, q.rotacao, q.jpeg) == (7, 123.0, 90, b"\xff\xd8abc")


@pytest.mark.parametrize(
    "dados,codigo",
    [
        (b"\x00", Codigo.CABECALHO_INVALIDO),
        ((9999).to_bytes(4, "big") + b"{}", Codigo.CABECALHO_INVALIDO),
        ((2).to_bytes(4, "big") + b"{}" + b"\xff\xd8xx", Codigo.CABECALHO_INVALIDO),
        (montar_quadro(1, b"nao e jpeg"), Codigo.IMAGEM_INVALIDA),
        (montar_quadro(1, b"\xff\xd8xx", rotacao=45), Codigo.PARAMETRO_INVALIDO),
    ],
)
def test_quadro_invalido(dados, codigo):
    with pytest.raises(ErroProtocolo) as e:
        ler_quadro(dados, 10_000)
    assert e.value.codigo == codigo


def test_quadro_grande_demais():
    with pytest.raises(ErroProtocolo) as e:
        ler_quadro(montar_quadro(1, b"\xff\xd8" + b"x" * 200), 100)
    assert e.value.codigo == Codigo.IMAGEM_GRANDE_DEMAIS


def test_parametros():
    p = Parametros(0.25, None, 640)
    assert p.com_ajustes({"confianca": 0.5, "classes": [5, 0, 5], "imgsz": 320}, 80).como_dict() == {"confianca": 0.5, "classes": [0, 5], "imgsz": 320}
    for ruim in ({"confianca": 2}, {"classes": [80]}, {"imgsz": 300}, {"classes": "a,b"}):
        with pytest.raises(ErroProtocolo):
            p.com_ajustes(ruim, 80)


# ===== API com o YOLO real =====
@pytest.fixture(scope="module")
def cliente():
    with TestClient(criar_app(Config())) as c:
        yield c


def test_status(cliente):
    s = cliente.get("/status").json()
    assert s["status"] == "ok" and s["modelo"] == "yolo11n.pt"
    assert s["dispositivo"] in ("mps", "cuda", "cpu")
    assert s["classes"]["0"] == "person" and s["versao"]


def test_detectar_http(cliente):
    r = cliente.post("/detectar", files={"imagem": ("bus.jpg", BUS.read_bytes(), "image/jpeg")})
    assert r.status_code == 200, r.text
    d = r.json()
    nomes = {x["classe"] for x in d["deteccoes"]}
    assert {"person", "bus"} <= nomes
    for x in d["deteccoes"]:
        c = x["caixa"]
        assert 0 <= c["x1"] < c["x2"] <= 1 and 0 <= c["y1"] < c["y2"] <= 1
    assert (d["largura"], d["altura"]) == (810, 1080) and d["inferencia_ms"] > 0


def test_detectar_http_filtro_e_erros(cliente):
    so_onibus = cliente.post("/detectar?classes=5", files={"imagem": ("bus.jpg", BUS.read_bytes(), "image/jpeg")}).json()
    assert {x["classe"] for x in so_onibus["deteccoes"]} == {"bus"}
    r = cliente.post("/detectar", files={"imagem": ("x.jpg", b"lixo", "image/jpeg")})
    assert r.status_code == 400 and r.json()["erro"]["codigo"] == "IMAGEM_INVALIDA"
    r = cliente.post("/detectar?classes=999", files={"imagem": ("bus.jpg", BUS.read_bytes(), "image/jpeg")})
    assert r.status_code == 422 and r.json()["erro"]["codigo"] == "PARAMETRO_INVALIDO"
    r = cliente.post("/detectar?confianca=3", files={"imagem": ("bus.jpg", BUS.read_bytes(), "image/jpeg")})
    assert r.status_code == 422 and r.json()["erro"]["codigo"] == "PARAMETRO_INVALIDO"
    r = cliente.post("/detectar")
    assert r.status_code == 422 and "imagem" in r.json()["erro"]["mensagem"]


def test_websocket(cliente):
    retrato = bus_640x480()
    with cliente.websocket_connect("/ws/detectar") as ws:
        ws.send_bytes(montar_quadro(1, retrato, capturado_em=1000.0))
        r = ws.receive_json()
        assert r["tipo"] == "deteccoes" and r["seq"] == 1 and r["capturado_em"] == 1000.0
        assert (r["largura"], r["altura"]) == (480, 640) and r["deteccoes"]
        assert r["processamento_ms"] >= r["inferencia_ms"] > 0

        # Mesma imagem deitada + rotacao=90: a API gira e devolve as medidas "em pé".
        deitada = jpeg(cv2.rotate(cv2.imdecode(np.frombuffer(retrato, np.uint8), cv2.IMREAD_COLOR), cv2.ROTATE_90_COUNTERCLOCKWISE))
        ws.send_bytes(montar_quadro(2, deitada, rotacao=90))
        r2 = ws.receive_json()
        assert (r2["largura"], r2["altura"]) == (480, 640)
        assert {x["classe"] for x in r2["deteccoes"]} == {x["classe"] for x in r["deteccoes"]}

        ws.send_text('{"tipo": "config", "confianca": 0.9, "classes": [5]}')
        assert ws.receive_json() == {"tipo": "config_ok", "parametros": {"confianca": 0.9, "classes": [5], "imgsz": 640}}
        ws.send_bytes(montar_quadro(3, retrato))
        assert {x["classe"] for x in ws.receive_json()["deteccoes"]} <= {"bus"}

        ws.send_bytes(b"\x00\x00")
        e = ws.receive_json()
        assert e["tipo"] == "erro" and e["codigo"] == "CABECALHO_INVALIDO"
        ws.send_bytes(montar_quadro(4, b"\xff\xd8corrompido"))
        e = ws.receive_json()
        assert (e["codigo"], e["seq"]) == ("IMAGEM_INVALIDA", 4)
        ws.send_text('{"tipo": "config", "imgsz": 333}')
        assert ws.receive_json()["codigo"] == "PARAMETRO_INVALIDO"
        ws.send_text('{"tipo": "dancar"}')
        assert ws.receive_json()["codigo"] == "MENSAGEM_DESCONHECIDA"
        ws.send_text('{"tipo": "status"}')
        st = ws.receive_json()
        assert st["tipo"] == "status" and st["conexoes_ativas"] == 1


# ===== Controle de fluxo com um detector lento =====
class DetectorLento:
    nomes = {0: "person"}

    def parametros_padrao(self):
        return Parametros(0.25, None, 640)

    async def detectar(self, jpeg, rotacao, p):
        await asyncio.sleep(0.2)
        return Resultado(640, 480, 200.0)

    def info(self):
        return {"modelo": "falso", "dispositivo": "cpu", "classes": self.nomes, "versoes": {}}


def test_processa_sempre_o_mais_recente():
    with TestClient(criar_app(Config(), detector=DetectorLento())) as c, c.websocket_connect("/ws/detectar") as ws:
        for seq in range(1, 7):  # 6 quadros em rajada, bem mais rápido que a inferência
            ws.send_bytes(montar_quadro(seq, b"\xff\xd8xxxx"))
        respostas = []
        inicio = time.perf_counter()
        while not any(r.get("seq") == 6 and r["tipo"] == "deteccoes" for r in respostas):
            respostas.append(ws.receive_json())
        tempo = time.perf_counter() - inicio
        processados = [r["seq"] for r in respostas if r["tipo"] == "deteccoes"]
        descartados = [r["seq"] for r in respostas if r["tipo"] == "descartado"]
        # Nenhum quadro some sem aviso, e no máximo 2 inferências (a que já estava rodando + a mais recente).
        assert sorted(processados + descartados) == [1, 2, 3, 4, 5, 6]
        assert processados[-1] == 6 and len(processados) <= 2
        assert tempo < 0.6  # latência não acumulou (6 inferências levariam 1,2 s)

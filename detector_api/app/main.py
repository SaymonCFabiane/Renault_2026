"""API TracePro de detecção de objetos em tempo real (Ultralytics YOLO).

Rodar:  python -m app   (ou)   uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

import asyncio
import json
import logging
import time
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, File, Query, Request, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from .config import VERSAO, Config
from .dataset import Dataset
from .rotas_dataset import rotas as rotas_dataset
from .rotas_treino import rotas as rotas_treino
from .sugestor import Tarefa
from .treino import Treinos
from .protocolo import Codigo, ErroProtocolo, Parametros, Quadro, erro_http, erro_ws, ler_quadro, validar_rotacao

log = logging.getLogger("tracepro.api")
STATUS_HTTP = {
    Codigo.CABECALHO_INVALIDO: 400,
    Codigo.IMAGEM_INVALIDA: 400,
    Codigo.PARAMETRO_INVALIDO: 422,
    Codigo.MENSAGEM_DESCONHECIDA: 400,
    Codigo.IMAGEM_GRANDE_DEMAIS: 413,
    Codigo.MODELO_INDISPONIVEL: 503,
    Codigo.ERRO_INTERNO: 500,
}


def criar_app(config: Config | None = None, detector: Any = None) -> FastAPI:
    """`detector` pode ser injetado (testes); senão o YOLO é carregado na inicialização."""
    config = config or Config()

    @asynccontextmanager
    async def ciclo(app: FastAPI):
        app.state.erro_modelo = None
        # Uma única thread para toda a GPU: detecção ao vivo e sugestões de caixas se revezam nela.
        app.state.gpu = ThreadPoolExecutor(max_workers=1, thread_name_prefix="gpu")
        app.state.dataset = Dataset(config.dados_dir)
        app.state.sugestor = None
        app.state.tarefa_sugestao = Tarefa()
        app.state.treinos = Treinos(app.state.dataset, config.dados_dir / "treinos", config.modelos_dir)
        # O modelo ativado no painel vale também depois de reiniciar a API.
        app.state.modelo_ativo = modelo_salvo(config) or config.modelo
        if detector is not None:
            app.state.detector = detector
        else:
            try:
                from .detector import Detector

                cfg = config.model_copy(update={"modelo": app.state.modelo_ativo})
                loop = asyncio.get_running_loop()
                app.state.detector = await loop.run_in_executor(app.state.gpu, Detector, cfg, app.state.gpu)
            except Exception as e:  # a API sobe mesmo sem modelo, e o /status explica o motivo
                log.exception("falha ao carregar o modelo")
                app.state.detector = None
                app.state.erro_modelo = str(e)
        yield
        if app.state.tarefa_sugestao._tarefa is not None:
            app.state.tarefa_sugestao._tarefa.cancel()
        if app.state.detector is not None and hasattr(app.state.detector, "fechar"):
            app.state.detector.fechar()
        app.state.gpu.shutdown(wait=False, cancel_futures=True)
        app.state.dataset.fechar()

    app = FastAPI(title="TracePro · API de detecção", version=VERSAO, lifespan=ciclo)
    app.state.config = config
    app.state.conexoes = 0
    app.add_middleware(CORSMiddleware, allow_origins=config.cors_origens, allow_methods=["*"], allow_headers=["*"])
    app.include_router(rotas_dataset)
    app.include_router(rotas_treino)

    # ===== Erros no formato padronizado {"erro": {"codigo", "mensagem"}} =====
    @app.exception_handler(ErroProtocolo)
    async def _erro_protocolo(_: Request, e: ErroProtocolo):
        return JSONResponse(erro_http(e.codigo, e.mensagem), status_code=STATUS_HTTP.get(e.codigo, 400))

    @app.exception_handler(RequestValidationError)
    async def _erro_validacao(_: Request, e: RequestValidationError):
        partes = []
        for x in e.errors():
            onde = ".".join(str(p) for p in x.get("loc", ())[1:]) or "requisição"
            partes.append(f"{onde}: {x.get('msg')}")
        return JSONResponse(erro_http(Codigo.PARAMETRO_INVALIDO, "; ".join(partes)), status_code=422)

    @app.exception_handler(StarletteHTTPException)
    async def _erro_http(_: Request, e: StarletteHTTPException):
        codigo = Codigo.MENSAGEM_DESCONHECIDA if e.status_code in (404, 405) else Codigo.ERRO_INTERNO
        return JSONResponse(erro_http(codigo, str(e.detail)), status_code=e.status_code)

    def detector_ou_erro(app_: FastAPI):
        d = app_.state.detector
        if d is None:
            raise ErroProtocolo(Codigo.MODELO_INDISPONIVEL, f"modelo não carregado: {app_.state.erro_modelo}")
        return d

    def status_dict() -> dict[str, Any]:
        d = app.state.detector
        base = {
            "status": "ok" if d is not None else "erro",
            "versao": VERSAO,
            "conexoes_ativas": app.state.conexoes,
            "parametros": {"confianca": config.confianca, "classes": config.classes, "imgsz": config.imgsz, "iou": config.iou},
        }
        if d is None:
            base.update({"modelo": getattr(app.state, "modelo_ativo", config.modelo), "dispositivo": None, "erro": app.state.erro_modelo})
        else:
            base.update(d.info())
        return base

    # ===== HTTP =====
    @app.get("/")
    async def raiz():
        return {"nome": "TracePro · API de detecção", "versao": VERSAO, "rotas": ["/status", "/detectar", "/ws/detectar", "/dataset/...", "/docs"]}

    @app.get("/status")
    async def status():
        return status_dict()

    @app.post("/detectar")
    async def detectar(
        imagem: UploadFile = File(..., description="Imagem JPEG ou PNG"),
        confianca: float | None = Query(None, ge=0, le=1),
        classes: str | None = Query(None, description="ids separados por vírgula, ex.: 0,67"),
        imgsz: int | None = Query(None, ge=32, le=1920),
        rotacao: int = Query(0, description="0, 90, 180 ou 270 (sentido horário)"),
    ):
        det = detector_ou_erro(app)
        dados = await imagem.read(config.max_bytes_imagem + 1)
        if len(dados) > config.max_bytes_imagem:
            raise ErroProtocolo(Codigo.IMAGEM_GRANDE_DEMAIS, f"imagem acima de {config.max_bytes_imagem} bytes")
        if not dados:
            raise ErroProtocolo(Codigo.IMAGEM_INVALIDA, "arquivo vazio")
        ajustes: dict[str, Any] = {"confianca": confianca, "imgsz": imgsz}
        if classes is not None:
            ajustes["classes"] = classes
        params = det.parametros_padrao().com_ajustes(ajustes, len(det.nomes))
        t0 = time.perf_counter()
        res = await det.detectar(dados, validar_rotacao(rotacao), params)
        return res.como_dict(processamento_ms=(time.perf_counter() - t0) * 1000)

    # ===== WebSocket =====
    @app.websocket("/ws/detectar")
    async def ws_detectar(ws: WebSocket):
        await ws.accept()
        app.state.conexoes += 1
        trava_envio = asyncio.Lock()
        sessao = Sessao()

        async def enviar(msg: dict[str, Any]) -> None:
            async with trava_envio:
                await ws.send_text(json.dumps(msg, ensure_ascii=False))

        det = app.state.detector
        if det is None:
            await enviar(erro_ws(Codigo.MODELO_INDISPONIVEL, f"modelo não carregado: {app.state.erro_modelo}"))
        sessao.params = det.parametros_padrao() if det is not None else None

        async def processar() -> None:
            # Consome sempre o quadro mais recente; nunca existe fila.
            while True:
                await sessao.novo.wait()
                sessao.novo.clear()
                q, sessao.pendente = sessao.pendente, None
                if q is None:
                    continue
                d = app.state.detector
                if d is None:
                    await enviar(erro_ws(Codigo.MODELO_INDISPONIVEL, "modelo não carregado", q.seq))
                    continue
                try:
                    res = await d.detectar(q.jpeg, q.rotacao, sessao.params)
                except ErroProtocolo as e:
                    await enviar(erro_ws(e.codigo, e.mensagem, q.seq))
                    continue
                except Exception as e:
                    log.exception("falha na inferência")
                    await enviar(erro_ws(Codigo.ERRO_INTERNO, f"falha na inferência: {e}", q.seq))
                    continue
                proc_ms = (time.perf_counter() - q.recebido_em) * 1000
                await enviar(res.como_dict(seq=q.seq, capturado_em=q.capturado_em, processamento_ms=proc_ms))

        tarefa = asyncio.create_task(processar())
        try:
            while True:
                msg = await ws.receive()
                if msg["type"] == "websocket.disconnect":
                    break
                if msg.get("bytes") is not None:
                    try:
                        q = ler_quadro(msg["bytes"], config.max_bytes_imagem)
                    except ErroProtocolo as e:
                        await enviar(erro_ws(e.codigo, e.mensagem, e.seq))
                        continue
                    q.recebido_em = time.perf_counter()
                    if sessao.pendente is not None:
                        # Chegou um quadro mais novo antes da inferência pegar o anterior: descarta o antigo.
                        sessao.descartados += 1
                        await enviar({"tipo": "descartado", "seq": sessao.pendente.seq})
                    sessao.pendente = q
                    sessao.novo.set()
                elif msg.get("text") is not None:
                    await tratar_texto(msg["text"], sessao, enviar)
        except WebSocketDisconnect:
            pass
        finally:
            tarefa.cancel()
            app.state.conexoes -= 1

    async def tratar_texto(texto: str, sessao: "Sessao", enviar) -> None:
        try:
            dados = json.loads(texto)
        except json.JSONDecodeError:
            await enviar(erro_ws(Codigo.MENSAGEM_DESCONHECIDA, "mensagem de texto precisa ser JSON"))
            return
        tipo = dados.get("tipo") if isinstance(dados, dict) else None
        if tipo == "status":
            await enviar({"tipo": "status", **status_dict()})
        elif tipo == "config":
            det = app.state.detector
            if det is None or sessao.params is None:
                await enviar(erro_ws(Codigo.MODELO_INDISPONIVEL, "modelo não carregado"))
                return
            try:
                sessao.params = sessao.params.com_ajustes(dados, len(det.nomes))
            except ErroProtocolo as e:
                await enviar(erro_ws(e.codigo, e.mensagem))
                return
            await enviar({"tipo": "config_ok", "parametros": sessao.params.como_dict()})
        else:
            await enviar(erro_ws(Codigo.MENSAGEM_DESCONHECIDA, f"tipo de mensagem desconhecido: {tipo!r}"))

    return app


def modelo_salvo(config: Config) -> str | None:
    """Modelo ativado pelo painel (dados/modelo_ativo.txt), se o arquivo ainda existir."""
    p = config.dados_dir / "modelo_ativo.txt"
    if p.exists():
        nome = p.read_text(encoding="utf-8").strip()
        if nome and config.caminho_modelo(nome).exists():
            return nome
    return None


class Sessao:
    """Estado de uma conexão WebSocket: parâmetros e o único quadro pendente."""

    def __init__(self) -> None:
        self.params: Parametros | None = None
        self.pendente: Quadro | None = None
        self.novo = asyncio.Event()
        self.descartados = 0


app = criar_app()

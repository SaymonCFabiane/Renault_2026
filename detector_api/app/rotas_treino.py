"""Rotas de treino (/treinos) e de modelos (/modelos)."""

import asyncio

from fastapi import APIRouter, Request
from pydantic import BaseModel

from .protocolo import Codigo, ErroProtocolo
from .treino import BASES, catalogo_modelos, validar_para_treino

rotas = APIRouter(tags=["treino"])


class PedidoTreino(BaseModel):
    base: str = "yolo11n.pt"
    epocas: int = 80
    imgsz: int = 640


def _dispositivo(req: Request) -> str:
    st = req.app.state
    if getattr(st.detector, "dispositivo", None):
        return st.detector.dispositivo
    from .detector import escolher_dispositivo

    return escolher_dispositivo(st.config.dispositivo)


@rotas.get("/treinos")
def listar_treinos(req: Request):
    st = req.app.state
    return {
        "rodando": st.treinos.rodando(),
        "problemas": validar_para_treino(st.dataset),
        "bases": [b for b in BASES if st.config.caminho_modelo(b).exists()],
        "dataset": st.dataset.resumo(),
        "itens": st.treinos.listar(),
    }


@rotas.post("/treinos", status_code=201)
def iniciar_treino(req: Request, corpo: PedidoTreino):
    return req.app.state.treinos.iniciar(corpo.base, corpo.epocas, corpo.imgsz, _dispositivo(req))


@rotas.get("/treinos/{tid}")
def obter_treino(req: Request, tid: str):
    return req.app.state.treinos.obter(tid)


@rotas.post("/treinos/{tid}/cancelar")
def cancelar_treino(req: Request, tid: str):
    return req.app.state.treinos.cancelar(tid)


@rotas.get("/modelos")
def listar_modelos(req: Request):
    st = req.app.state
    return catalogo_modelos(st.config.modelos_dir, st.modelo_ativo)


@rotas.post("/modelos/{arquivo}/ativar")
async def ativar_modelo(req: Request, arquivo: str):
    """Troca o modelo da detecção sem reiniciar. Vale para o app, o painel e as próximas inicializações."""
    st = req.app.state
    if arquivo not in {m["arquivo"] for m in catalogo_modelos(st.config.modelos_dir, st.modelo_ativo)}:
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"modelo {arquivo} não encontrado em modelos/")
    from .detector import Detector

    cfg = st.config.model_copy(update={"modelo": arquivo})
    loop = asyncio.get_running_loop()
    try:
        novo = await loop.run_in_executor(st.gpu, Detector, cfg, st.gpu)  # carrega e aquece na thread da GPU
    except Exception as e:
        raise ErroProtocolo(Codigo.MODELO_INDISPONIVEL, f"não consegui carregar {arquivo}: {e}") from None
    antigo, st.detector = st.detector, novo
    st.modelo_ativo = arquivo
    st.erro_modelo = None
    (st.config.dados_dir / "modelo_ativo.txt").write_text(arquivo, encoding="utf-8")
    if antigo is not None and hasattr(antigo, "fechar"):
        antigo.fechar()
    return {"ativo": arquivo, "classes": novo.nomes, "dispositivo": novo.dispositivo}

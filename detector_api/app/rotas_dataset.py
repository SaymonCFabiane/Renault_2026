"""Rotas do dataset de treino (/dataset/...): classes, fotos, caixas e sugestões automáticas."""

import asyncio
from typing import Any

from fastapi import APIRouter, File, Form, Query, Request, UploadFile
from fastapi.responses import FileResponse
from pydantic import BaseModel

from .protocolo import Codigo, ErroProtocolo
from .sugestor import SugestorVisual, Tarefa, sugerir_em_lote

rotas = APIRouter(prefix="/dataset", tags=["dataset"])


class NovaClasse(BaseModel):
    nome: str
    rotulo: str | None = None


class AjusteClasse(BaseModel):
    rotulo: str | None = None
    cor: str | None = None


class Caixas(BaseModel):
    caixas: list[dict[str, Any]]
    status: str | None = None


class AjusteImagem(BaseModel):
    status: str | None = None
    divisao: str | None = None


class PedidoSugestao(BaseModel):
    todas: bool = False  # True refaz também as fotos que já têm sugestão


def _ds(req: Request):
    return req.app.state.dataset


@rotas.get("/resumo")
def resumo(req: Request):
    return _ds(req).resumo()


@rotas.get("/classes")
def classes(req: Request):
    return _ds(req).classes()


@rotas.post("/classes", status_code=201)
def criar_classe(req: Request, corpo: NovaClasse):
    return _ds(req).criar_classe(corpo.nome, corpo.rotulo)


@rotas.put("/classes/{classe_id}")
def ajustar_classe(req: Request, classe_id: int, corpo: AjusteClasse):
    return _ds(req).atualizar_classe(classe_id, corpo.rotulo, corpo.cor)


@rotas.get("/imagens")
def listar(
    req: Request,
    status: str | None = Query(None, description="um ou mais, separados por vírgula: pendente,sugerida,revisada,descartada"),
    classe_id: int | None = None,
    divisao: str | None = None,
    limite: int = Query(500, ge=1, le=2000),
    desloc: int = Query(0, ge=0),
):
    return _ds(req).listar([s for s in status.split(",") if s] if status else None, classe_id, divisao, limite, desloc)


@rotas.post("/imagens", status_code=201)
async def enviar_imagem(
    req: Request,
    imagem: UploadFile = File(...),
    origem: str = Form("painel"),
    classe_id: int | None = Form(None),
):
    config = req.app.state.config
    dados = await imagem.read(config.max_bytes_imagem * 4 + 1)
    if len(dados) > config.max_bytes_imagem * 4:
        raise ErroProtocolo(Codigo.IMAGEM_GRANDE_DEMAIS, "foto acima de 16 MB")
    if origem not in ("painel", "app"):
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "origem deve ser painel ou app")
    if classe_id is not None:
        _ds(req).classe(classe_id)
    item, nova = await asyncio.to_thread(_ds(req).adicionar_imagem, dados, origem, imagem.filename, classe_id)
    return {**item, "nova": nova}


@rotas.get("/imagens/{imagem_id}")
def obter(req: Request, imagem_id: str):
    return _ds(req).imagem(imagem_id)


@rotas.get("/imagens/{imagem_id}/arquivo")
def arquivo(req: Request, imagem_id: str):
    return FileResponse(_ds(req).caminho_imagem(imagem_id), media_type="image/jpeg", headers={"Cache-Control": "max-age=86400"})


@rotas.get("/imagens/{imagem_id}/miniatura")
def miniatura(req: Request, imagem_id: str):
    return FileResponse(_ds(req).caminho_imagem(imagem_id, miniatura=True), media_type="image/jpeg", headers={"Cache-Control": "max-age=86400"})


@rotas.put("/imagens/{imagem_id}/caixas")
def salvar_caixas(req: Request, imagem_id: str, corpo: Caixas):
    return _ds(req).salvar_caixas(imagem_id, corpo.caixas, corpo.status)


@rotas.patch("/imagens/{imagem_id}")
def ajustar_imagem(req: Request, imagem_id: str, corpo: AjusteImagem):
    return _ds(req).atualizar_imagem(imagem_id, corpo.status, corpo.divisao)


def _sugestor(req: Request) -> SugestorVisual:
    st = req.app.state
    if st.sugestor is None:
        from .detector import escolher_dispositivo

        disp = st.detector.dispositivo if st.detector is not None else escolher_dispositivo(st.config.dispositivo)
        st.sugestor = SugestorVisual(st.config, disp)
    return st.sugestor


@rotas.post("/sugestoes", status_code=202)
async def iniciar_sugestoes(req: Request, corpo: PedidoSugestao | None = None):
    st = req.app.state
    tarefa: Tarefa = st.tarefa_sugestao
    if not tarefa.rodando:
        tarefa.rodando = True  # marca já, para um segundo clique não abrir outra tarefa
        tarefa._tarefa = asyncio.create_task(sugerir_em_lote(st.dataset, _sugestor(req), st.gpu, tarefa, bool(corpo and corpo.todas)))
    return tarefa.como_dict()


@rotas.get("/sugestoes")
def estado_sugestoes(req: Request):
    return req.app.state.tarefa_sugestao.como_dict()

"""Testes do dataset de treino, das rotas /dataset e das sugestões de caixas."""

import time
from pathlib import Path

import cv2
import numpy as np
import pytest
import ultralytics
from fastapi.testclient import TestClient

from app.config import Config
from app.dataset import Dataset
from app.main import criar_app
from app.protocolo import ErroProtocolo
from app.sugestor import SugestorVisual
from tests.test_api import DetectorLento

BUS = Path(ultralytics.__file__).parent / "assets" / "bus.jpg"


def foto(cor: int, w: int = 400, h: int = 300) -> bytes:
    img = np.full((h, w, 3), cor, np.uint8)
    cv2.rectangle(img, (100, 80), (250, 200), (255 - cor, 80, 40), -1)
    return cv2.imencode(".jpg", img)[1].tobytes()


@pytest.fixture
def midia(tmp_path):
    raiz = tmp_path / "midia"
    for i, classe in enumerate(["engrenagem", "pinca_de_freio"]):
        (raiz / classe).mkdir(parents=True)
        for j in range(5):
            (raiz / classe / f"f{j}.jpg").write_bytes(foto(20 + i * 100 + j * 10))
    (raiz / "engrenagem" / "copia.jpg").write_bytes(foto(20))  # repetida de f0
    (raiz / "engrenagem" / "notas.txt").write_text("não é foto")
    return raiz


def test_importacao(tmp_path, midia):
    ds = Dataset(tmp_path / "dados")
    r = ds.importar_pasta(midia, {"pinca_de_freio": "Pinça de freio"})
    assert (r["novas"], r["repetidas"]) == (10, 1)
    classes = {c["nome"]: c for c in ds.classes()}
    assert classes["pinca_de_freio"]["rotulo"] == "Pinça de freio" and classes["engrenagem"]["rotulo"] == "Engrenagem"
    assert classes["engrenagem"]["imagens"] == 5
    assert ds.importar_pasta(midia)["novas"] == 0  # reimportar não duplica
    itens = ds.listar()["itens"]
    assert {i["status"] for i in itens} == {"pendente"} and {i["divisao"] for i in itens} <= {"treino", "validacao"}
    assert all((ds.pasta_imagens / f"{i['id']}.jpg").exists() and (ds.pasta_miniaturas / f"{i['id']}.jpg").exists() for i in itens)


def test_caixas_e_referencias(tmp_path, midia):
    ds = Dataset(tmp_path / "dados")
    ds.importar_pasta(midia)
    eng = ds.classes()[0]["id"]
    a, b = [i["id"] for i in ds.listar(classe_id=eng)["itens"][:2]]
    ds.salvar_caixas(a, [{"classe_id": eng, "x1": 0.1, "y1": 0.2, "x2": 0.5, "y2": 0.6, "origem": "semente"}])
    assert ds.imagem(a)["status"] == "sugerida"
    assert [r[1] for r in ds.referencias(eng)] == [[0.1, 0.2, 0.5, 0.6]]  # sem revisadas: usa a semente
    # Caixa invertida e fora da imagem é corrigida; a revisada passa a ser a referência.
    ds.salvar_caixas(b, [{"classe_id": eng, "x1": 0.9, "y1": 1.4, "x2": 0.3, "y2": 0.2}], status="revisada")
    img = ds.imagem(b)
    assert img["status"] == "revisada" and img["caixas"][0] | {"origem": "manual"} == img["caixas"][0]
    assert (img["caixas"][0]["x1"], img["caixas"][0]["y2"]) == (0.3, 1.0)
    assert ds.referencias(eng)[0][0].stem == b
    for ruim in ([{"classe_id": 99, "x1": 0, "y1": 0, "x2": 1, "y2": 1}], [{"classe_id": eng, "x1": 0.5, "y1": 0.5, "x2": 0.501, "y2": 0.9}], [{"x1": 0}]):
        with pytest.raises(ErroProtocolo):
            ds.salvar_caixas(a, ruim)
    ds.atualizar_imagem(a, status="descartada", divisao="validacao")
    assert ds.resumo()["imagens"]["descartada"] == 1
    assert ds.ids_para_sugerir() == sorted(ds.ids_para_sugerir())[:0] or a not in ds.ids_para_sugerir()


class SugestorFalso:
    def __init__(self):
        self.chamadas = 0

    def sugerir(self, alvo, refs):
        self.chamadas += 1
        return (0.8, [0.2, 0.2, 0.7, 0.7]) if self.chamadas % 2 else None


def test_rotas_dataset(tmp_path, midia):
    app = criar_app(Config(dados_dir=tmp_path / "dados"), detector=DetectorLento())
    with TestClient(app) as c:
        app.state.dataset.importar_pasta(midia)
        r = c.get("/dataset/resumo").json()
        assert r["imagens"]["total"] == 10 and len(r["classes"]) == 2
        eng = r["classes"][0]["id"]
        lista = c.get(f"/dataset/imagens?status=pendente&classe_id={eng}").json()
        assert lista["total"] == 5
        i = lista["itens"][0]["id"]
        assert c.get(f"/dataset/imagens/{i}/arquivo").headers["content-type"] == "image/jpeg"
        assert c.get(f"/dataset/imagens/{i}/miniatura").status_code == 200
        r = c.put(f"/dataset/imagens/{i}/caixas", json={"caixas": [{"classe_id": eng, "x1": 0.1, "y1": 0.1, "x2": 0.4, "y2": 0.5}], "status": "revisada"})
        assert r.status_code == 200 and r.json()["status"] == "revisada"
        r = c.put(f"/dataset/imagens/{i}/caixas", json={"caixas": [{"classe_id": 999, "x1": 0, "y1": 0, "x2": 1, "y2": 1}]})
        assert r.status_code == 422 and r.json()["erro"]["codigo"] == "PARAMETRO_INVALIDO"
        assert c.patch(f"/dataset/imagens/{i}", json={"divisao": "lixo"}).status_code == 422
        assert c.get("/dataset/imagens/naoexiste").status_code == 422
        # Envio de foto pelo painel/app, com repetida
        novo = c.post("/dataset/imagens", files={"imagem": ("x.jpg", foto(200), "image/jpeg")}, data={"origem": "app", "classe_id": str(eng)}).json()
        assert novo["nova"] and novo["origem"] == "app"
        assert c.post("/dataset/imagens", files={"imagem": ("x.jpg", foto(200), "image/jpeg")}, data={"origem": "app"}).json()["nova"] is False
        assert c.post("/dataset/imagens", files={"imagem": ("x.jpg", b"lixo", "image/jpeg")}).json()["erro"]["codigo"] == "IMAGEM_INVALIDA"
        # Classes
        nova = c.post("/dataset/classes", json={"nome": "Suporte do motor", "rotulo": "Suporte do motor"}).json()
        assert nova["nome"] == "suporte_do_motor"
        assert c.put(f"/dataset/classes/{nova['id']}", json={"rotulo": "Suporte"}).json()["rotulo"] == "Suporte"
        assert c.post("/dataset/classes", json={"nome": "çã!"}).status_code == 422
        # Sugestões em lote (sugestor falso): só fotos sem caixa e não revisadas
        falso = SugestorFalso()
        app.state.sugestor = falso
        app.state.dataset.salvar_caixas(lista["itens"][1]["id"], [{"classe_id": eng, "x1": 0.1, "y1": 0.1, "x2": 0.5, "y2": 0.5, "origem": "semente"}])
        assert c.post("/dataset/sugestoes").status_code == 202
        for _ in range(50):
            st = c.get("/dataset/sugestoes").json()
            if not st["rodando"]:
                break
            time.sleep(0.05)
        assert st["erro"] is None and st["total"] == 9 and st["feitas"] == 9  # 11 fotos − revisada − a da semente
        assert st["com_caixa"] + st["sem_caixa"] == 9
        assert c.get(f"/dataset/imagens/{i}").json()["caixas"][0]["origem"] == "manual"  # revisada não foi tocada
        sug = c.get("/dataset/imagens?status=sugerida").json()["itens"]
        assert any(x["caixas"] and x["caixas"][0]["origem"] == "sugestao" and x["caixas"][0]["confianca"] == 0.8 for x in sug)


def test_sugestor_yoloe_real(tmp_path):
    """Exemplo visual: o ônibus marcado numa foto é encontrado na mesma foto espelhada."""
    alvo = tmp_path / "espelhada.jpg"
    cv2.imwrite(str(alvo), cv2.flip(cv2.imread(str(BUS)), 1))
    s = SugestorVisual(Config(), "mps" if __import__("torch").backends.mps.is_available() else "cpu")
    achado = s.sugerir(alvo, [(BUS, [0.01, 0.21, 0.99, 0.69])])
    assert achado is not None and achado[0] > 0.5
    x1, y1, x2, y2 = achado[1]
    assert x1 < 0.1 and x2 > 0.9 and 0.15 < y1 < 0.3 and 0.6 < y2 < 0.8  # caixa do ônibus inteiro

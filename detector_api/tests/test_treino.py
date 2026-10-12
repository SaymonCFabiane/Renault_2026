"""Testes do treino: exportação YOLO, validações e um treino curto de verdade com ativação do modelo."""

import random
import time
from pathlib import Path

import cv2
import numpy as np
import pytest
from fastapi.testclient import TestClient

from app.config import RAIZ, Config
from app.dataset import Dataset
from app.main import criar_app
from app.treino import exportar_yolo, validar_para_treino
from tests.test_api import DetectorLento


def dataset_sintetico(pasta: Path, n: int = 14) -> Dataset:
    """Círculos vermelhos ("Peça redonda") e quadrados azuis ("Peça quadrada"), com as caixas certas."""
    ds = Dataset(pasta)
    redonda = ds.criar_classe("peca_redonda", "Peça redonda")["id"]
    quadrada = ds.criar_classe("peca_quadrada", "Peça quadrada")["id"]
    rnd = random.Random(1)
    for i in range(n):
        img = np.full((480, 640, 3), rnd.randint(150, 230), np.uint8)
        cx, cy, r = rnd.randint(120, 520), rnd.randint(120, 360), rnd.randint(50, 90)
        classe = redonda if i % 2 else quadrada
        if classe == redonda:
            cv2.circle(img, (cx, cy), r, (30, 30, 200), -1)
        else:
            cv2.rectangle(img, (cx - r, cy - r), (cx + r, cy + r), (200, 60, 30), -1)
        item, _ = ds.adicionar_imagem(cv2.imencode(".jpg", img)[1].tobytes(), "importacao", f"{i}.jpg", classe)
        caixa = {"classe_id": classe, "x1": (cx - r) / 640, "y1": (cy - r) / 480, "x2": (cx + r) / 640, "y2": (cy + r) / 480}
        ds.salvar_caixas(item["id"], [caixa], status="revisada")
    ds.rebalancear_divisao()
    return ds


def test_exportacao(tmp_path):
    ds = dataset_sintetico(tmp_path / "dados")
    r = exportar_yolo(ds, tmp_path / "yolo")
    assert r["classes"] == ["Peça redonda", "Peça quadrada"]
    assert r["divisoes"]["treino"]["fotos"] + r["divisoes"]["validacao"]["fotos"] == 14
    assert r["divisoes"]["validacao"]["fotos"] >= 2
    yaml = (tmp_path / "yolo" / "data.yaml").read_text(encoding="utf-8")
    assert '0: "Peça redonda"' in yaml and "train: images/train" in yaml
    rotulo = next((tmp_path / "yolo" / "labels" / "train").glob("*.txt")).read_text().split()
    assert len(rotulo) == 5 and rotulo[0] in ("0", "1") and all(0 <= float(v) <= 1 for v in rotulo[1:])
    img = next((tmp_path / "yolo" / "images" / "train").glob("*.jpg"))
    assert img.is_symlink() and img.resolve().exists()


def test_validacao_para_treino(tmp_path):
    ds = Dataset(tmp_path / "dados")
    ds.criar_classe("peca", "Peça")
    problemas = validar_para_treino(ds)
    assert len(problemas) == 3 and any("Peça" in p for p in problemas)
    assert validar_para_treino(dataset_sintetico(tmp_path / "outro")) == []


@pytest.fixture
def modelos(tmp_path):
    pasta = tmp_path / "modelos"
    pasta.mkdir()
    (pasta / "yolo11n.pt").symlink_to(RAIZ / "modelos" / "yolo11n.pt")
    return pasta


def test_treino_real_e_ativacao(tmp_path, modelos):
    dataset_sintetico(tmp_path / "dados").fechar()
    app = criar_app(Config(dados_dir=tmp_path / "dados", modelos_dir=modelos))
    with TestClient(app) as c:
        t = c.get("/treinos").json()
        assert t["rodando"] is None and t["problemas"] == [] and t["bases"] == ["yolo11n.pt"]
        assert c.post("/treinos", json={"epocas": 2}).json()["erro"]["codigo"] == "PARAMETRO_INVALIDO"
        r = c.post("/treinos", json={"epocas": 5, "imgsz": 320})
        assert r.status_code == 201, r.text
        tid = r.json()["id"]
        assert c.post("/treinos", json={"epocas": 5, "imgsz": 320}).json()["erro"]["mensagem"] == "já existe um treino em andamento"
        for _ in range(300):
            info = c.get(f"/treinos/{tid}").json()
            if info["situacao"] not in ("preparando", "treinando"):
                break
            time.sleep(1)
        assert info["situacao"] == "concluido", info.get("log")
        assert info["epoca"] >= 1 and info["historico"][0]["map50"] is not None and info["melhor"]
        assert [h["epoca"] for h in info["historico"]] == list(range(1, info["epoca"] + 1)) and info["epoca"] <= 5
        arquivo = info["modelo"]
        assert (modelos / arquivo).exists() and (modelos / arquivo).with_suffix(".json").exists()
        catalogo = {m["arquivo"]: m for m in c.get("/modelos").json()}
        assert catalogo[arquivo]["tipo"] == "treinado" and catalogo["yolo11n.pt"]["ativo"]
        # Ativa sem reiniciar: o /status passa a mostrar as classes novas.
        r = c.post(f"/modelos/{arquivo}/ativar").json()
        assert r["ativo"] == arquivo and set(r["classes"].values()) == {"Peça redonda", "Peça quadrada"}
        s = c.get("/status").json()
        assert s["modelo"] == arquivo and s["classes"]["0"] == "Peça redonda"
        assert c.post("/modelos/naoexiste.pt/ativar").status_code == 422
    # Ao subir de novo, a API lembra do modelo ativado.
    with TestClient(criar_app(Config(dados_dir=tmp_path / "dados", modelos_dir=modelos))) as c:
        assert c.get("/status").json()["modelo"] == arquivo


def test_cancelar(tmp_path, modelos):
    dataset_sintetico(tmp_path / "dados").fechar()
    with TestClient(criar_app(Config(dados_dir=tmp_path / "dados", modelos_dir=modelos), detector=DetectorLento())) as c:
        tid = c.post("/treinos", json={"epocas": 50, "imgsz": 320}).json()["id"]
        time.sleep(2)
        r = c.post(f"/treinos/{tid}/cancelar").json()
        assert r["situacao"] == "cancelado"
        assert c.get("/treinos").json()["rodando"] is None

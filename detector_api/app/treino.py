"""Treino de modelos próprios e catálogo de modelos.

Cada treino fica em dados/treinos/<id>/:
    dataset/           exportação no formato YOLO (images/, labels/, data.yaml)
    info.json          parâmetros, situação e métricas por época (lido pelo painel)
    treino.log         saída do Ultralytics
O treino roda num processo separado (app/treinar.py): a API continua respondendo, mas a detecção
ao vivo fica mais lenta enquanto a GPU é dividida.

Modelos treinados vão para modelos/tracepro-<id>.pt, com um .json ao lado (classes e métricas).
"""

import json
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

from .config import RAIZ
from .dataset import Dataset
from .protocolo import Codigo, ErroProtocolo

BASES = ("yolo11n.pt", "yolo11s.pt")
MIN_TREINO, MIN_VALIDACAO = 8, 2


def ler_json(p: Path) -> dict[str, Any]:
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def gravar_json(p: Path, dados: dict[str, Any]) -> None:
    tmp = p.with_suffix(".tmp")
    tmp.write_text(json.dumps(dados, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(p)  # troca atômica: o painel nunca lê um arquivo pela metade


def exportar_yolo(ds: Dataset, destino: Path) -> dict[str, Any]:
    """Exporta as fotos revisadas no formato YOLO. A classe i do modelo é a i-ésima classe do dataset,
    e o nome dela é o rótulo ("Pinça de freio"), que aparece direto no app."""
    classes = ds.classes()
    indice = {c["id"]: i for i, c in enumerate(classes)}
    contagem = {d: {"fotos": 0, "fundo": 0, "caixas": {c["rotulo"]: 0 for c in classes}} for d in ("treino", "validacao")}
    if destino.exists():
        shutil.rmtree(destino)
    for pasta in ("train", "val"):
        (destino / "images" / pasta).mkdir(parents=True)
        (destino / "labels" / pasta).mkdir(parents=True)
    for img in ds.listar(status=["revisada"], limite=100_000)["itens"]:
        pasta = "val" if img["divisao"] == "validacao" else "train"
        c = contagem[img["divisao"]]
        c["fotos"] += 1
        (destino / "images" / pasta / f"{img['id']}.jpg").symlink_to(ds.caminho_imagem(img["id"]).resolve())
        linhas = []
        for x in img["caixas"]:
            cx, cy = (x["x1"] + x["x2"]) / 2, (x["y1"] + x["y2"]) / 2
            linhas.append(f"{indice[x['classe_id']]} {cx:.6f} {cy:.6f} {x['x2'] - x['x1']:.6f} {x['y2'] - x['y1']:.6f}")
            c["caixas"][classes[indice[x["classe_id"]]]["rotulo"]] += 1
        c["fundo"] += not linhas
        (destino / "labels" / pasta / f"{img['id']}.txt").write_text("\n".join(linhas))
    yaml = [f"path: {destino.resolve()}", "train: images/train", "val: images/val", "names:"]
    yaml += [f"  {i}: {json.dumps(c['rotulo'], ensure_ascii=False)}" for i, c in enumerate(classes)]
    (destino / "data.yaml").write_text("\n".join(yaml) + "\n", encoding="utf-8")
    return {"classes": [c["rotulo"] for c in classes], "divisoes": contagem}


def validar_para_treino(ds: Dataset) -> list[str]:
    """Problemas que impedem o treino (lista vazia = pode treinar)."""
    r = ds.resumo()
    problemas = []
    if r["revisadas_por_divisao"]["treino"] < MIN_TREINO:
        problemas.append(f"Revise pelo menos {MIN_TREINO} fotos de treino (há {r['revisadas_por_divisao']['treino']}).")
    if r["revisadas_por_divisao"]["validacao"] < MIN_VALIDACAO:
        problemas.append(f"É preciso ter pelo menos {MIN_VALIDACAO} fotos revisadas na validação.")
    for c in r["classes"]:
        if c["caixas_revisadas"] == 0:
            problemas.append(f"A classe {c['rotulo']} ainda não tem nenhuma caixa revisada.")
    return problemas


class Treinos:
    """Inicia, acompanha e cancela treinos; um por vez."""

    def __init__(self, ds: Dataset, pasta: Path, pasta_modelos: Path):
        self.ds = ds
        self.pasta = pasta
        self.pasta_modelos = pasta_modelos
        self.pasta.mkdir(parents=True, exist_ok=True)
        self._processo: subprocess.Popen | None = None
        self._id_atual: str | None = None
        # Treinos que ficaram "rodando" quando a API caiu viram "interrompido".
        for info in self.pasta.glob("*/info.json"):
            d = ler_json(info)
            if d.get("situacao") in ("preparando", "treinando"):
                d["situacao"] = "interrompido"
                d["mensagem"] = "A API foi reiniciada durante o treino."
                gravar_json(info, d)

    def rodando(self) -> str | None:
        if self._processo is not None and self._processo.poll() is None:
            return self._id_atual
        if self._processo is not None:
            self._finalizar()
        return None

    def _finalizar(self) -> None:
        """O processo terminou: se não gravou a situação final, foi uma falha."""
        info_p = self.pasta / self._id_atual / "info.json"
        d = ler_json(info_p)
        if d.get("situacao") in ("preparando", "treinando"):
            d["situacao"] = "erro"
            d["mensagem"] = d.get("mensagem") or f"O treino parou (código {self._processo.returncode}). Veja treino.log."
            d["concluido_em"] = time.time()
            gravar_json(info_p, d)
        self._processo = None
        self._id_atual = None

    def iniciar(self, base: str, epocas: int, imgsz: int, dispositivo: str) -> dict[str, Any]:
        if self.rodando():
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "já existe um treino em andamento")
        if base not in BASES:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"modelo base deve ser um de {BASES}")
        if not 5 <= epocas <= 300:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "épocas entre 5 e 300")
        if imgsz % 32 or not 320 <= imgsz <= 1280:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "imgsz múltiplo de 32 entre 320 e 1280")
        if problemas := validar_para_treino(self.ds):
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, " ".join(problemas))
        if not (self.pasta_modelos / base).exists():
            raise ErroProtocolo(Codigo.MODELO_INDISPONIVEL, f"modelo base {base} não encontrado. Rode: python baixar_modelo.py {base}")

        tid = time.strftime("%Y%m%d-%H%M%S")
        dir_t = self.pasta / tid
        dir_t.mkdir()
        exportado = exportar_yolo(self.ds, dir_t / "dataset")
        info = {
            "id": tid, "situacao": "preparando", "base": base, "epocas": epocas, "imgsz": imgsz, "dispositivo": dispositivo,
            "criado_em": time.time(), "iniciado_em": None, "concluido_em": None, "epoca": 0, "historico": [],
            "melhor": None, "modelo": None, "mensagem": None, **exportado,
        }
        gravar_json(dir_t / "info.json", info)
        env = {**os.environ, "YOLO_OFFLINE": "1", "PYTHONUNBUFFERED": "1"}
        log = open(dir_t / "treino.log", "w", encoding="utf-8")  # noqa: SIM115 — fica aberto com o processo
        self._processo = subprocess.Popen(
            [sys.executable, "-m", "app.treinar", str(dir_t), str(self.pasta_modelos / base), str(epocas), str(imgsz), dispositivo, str(self.pasta_modelos)],
            cwd=RAIZ, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True,
        )
        self._id_atual = tid
        return info

    def cancelar(self, tid: str) -> dict[str, Any]:
        if self.rodando() != tid:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "este treino não está em andamento")
        os.killpg(self._processo.pid, signal.SIGTERM)
        try:
            self._processo.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(self._processo.pid, signal.SIGKILL)
        info_p = self.pasta / tid / "info.json"
        d = ler_json(info_p)
        d.update(situacao="cancelado", concluido_em=time.time(), mensagem="Cancelado no painel.")
        gravar_json(info_p, d)
        self._processo = None
        self._id_atual = None
        return d

    def obter(self, tid: str) -> dict[str, Any]:
        self.rodando()
        p = self.pasta / tid / "info.json"
        if not p.exists():
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"treino {tid} não existe")
        d = ler_json(p)
        log = self.pasta / tid / "treino.log"
        if log.exists():
            linhas = log.read_text(encoding="utf-8", errors="replace").replace("\r", "\n").splitlines()
            d["log"] = [x for x in linhas if x.strip()][-12:]
        return d

    def listar(self) -> list[dict[str, Any]]:
        self.rodando()
        itens = [ler_json(p) for p in sorted(self.pasta.glob("*/info.json"), reverse=True)]
        return [{k: v for k, v in d.items() if k != "historico"} for d in itens if d]


def catalogo_modelos(pasta: Path, ativo: str) -> list[dict[str, Any]]:
    """Modelos de detecção disponíveis em modelos/ (exceto o de sugestão de caixas)."""
    itens = []
    for p in sorted(pasta.glob("*.pt"), key=lambda x: x.stat().st_mtime, reverse=True):
        if p.name.startswith("yoloe"):
            continue
        meta = ler_json(p.with_suffix(".json"))
        itens.append({
            "arquivo": p.name,
            "tipo": "treinado" if meta else "pre-treinado",
            "tamanho_mb": round(p.stat().st_size / 1e6, 1),
            "ativo": p.name == ativo,
            "classes": meta.get("classes"),
            "metricas": meta.get("melhor"),
            "treino": meta.get("id"),
            "criado_em": meta.get("concluido_em") or p.stat().st_mtime,
        })
    return itens

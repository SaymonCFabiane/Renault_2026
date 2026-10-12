"""Dataset de treino: classes, fotos e caixas anotadas.

Fica em dados/ (fora do Git):
    dados/dataset.db        SQLite com classes, imagens e caixas
    dados/imagens/<id>.jpg  cópia normalizada (orientação corrigida, lado maior ≤ 1600 px)
    dados/miniaturas/<id>.jpg  miniatura de 320 px para a grade do painel

Caixas em coordenadas normalizadas (0–1) sobre a imagem "em pé", iguais às da detecção.
"""

import hashlib
import io
import sqlite3
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from PIL import Image, ImageOps, UnidentifiedImageError

from .protocolo import Codigo, ErroProtocolo

LADO_MAX = 1600
LADO_MINIATURA = 320
STATUS = ("pendente", "sugerida", "revisada", "descartada")
DIVISOES = ("treino", "validacao")
EXTENSOES = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
# Cores das classes no painel (contraste bom sobre foto, nos dois temas).
CORES = ["#FFB27A", "#7FD4FF", "#B6F09C", "#F0A3FF", "#FFE070", "#FF8F8F", "#9EA8FF", "#7FFFD4"]

_ESQUEMA = """
CREATE TABLE IF NOT EXISTS classes (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,      -- identificador sem acento (vai para o modelo)
    rotulo TEXT NOT NULL,           -- como aparece no app e no painel
    cor TEXT NOT NULL,
    criada_em REAL NOT NULL
);
CREATE TABLE IF NOT EXISTS imagens (
    id TEXT PRIMARY KEY,            -- 16 primeiros hex do SHA-1 do arquivo original (evita duplicatas)
    largura INTEGER NOT NULL,
    altura INTEGER NOT NULL,
    origem TEXT NOT NULL,           -- importacao | painel | app
    nome_original TEXT,
    classe_esperada_id INTEGER REFERENCES classes(id),
    status TEXT NOT NULL DEFAULT 'pendente',
    divisao TEXT NOT NULL,
    criada_em REAL NOT NULL,
    atualizada_em REAL NOT NULL
);
CREATE TABLE IF NOT EXISTS caixas (
    id INTEGER PRIMARY KEY,
    imagem_id TEXT NOT NULL REFERENCES imagens(id) ON DELETE CASCADE,
    classe_id INTEGER NOT NULL REFERENCES classes(id),
    x1 REAL NOT NULL, y1 REAL NOT NULL, x2 REAL NOT NULL, y2 REAL NOT NULL,
    origem TEXT NOT NULL,           -- manual | sugestao | semente
    confianca REAL
);
CREATE INDEX IF NOT EXISTS caixas_imagem ON caixas(imagem_id);
"""


@dataclass
class Caixa:
    classe_id: int
    x1: float
    y1: float
    x2: float
    y2: float
    origem: str = "manual"
    confianca: float | None = None

    def como_dict(self) -> dict[str, Any]:
        return {
            "classe_id": self.classe_id,
            "x1": round(self.x1, 5), "y1": round(self.y1, 5), "x2": round(self.x2, 5), "y2": round(self.y2, 5),
            "origem": self.origem,
            "confianca": None if self.confianca is None else round(self.confianca, 3),
        }


def _divisao(imagem_id: str) -> str:
    """80% treino, 20% validação, de forma estável (a mesma foto cai sempre no mesmo lado)."""
    return "validacao" if int(imagem_id[:8], 16) % 5 == 0 else "treino"


def _validar_caixa(c: dict[str, Any], classes: set[int]) -> Caixa:
    try:
        cx = Caixa(int(c["classe_id"]), float(c["x1"]), float(c["y1"]), float(c["x2"]), float(c["y2"]))
    except (KeyError, TypeError, ValueError):
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "cada caixa precisa de classe_id, x1, y1, x2 e y2") from None
    if cx.classe_id not in classes:
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"classe {cx.classe_id} não existe")
    cx.x1, cx.x2 = sorted((min(max(cx.x1, 0.0), 1.0), min(max(cx.x2, 0.0), 1.0)))
    cx.y1, cx.y2 = sorted((min(max(cx.y1, 0.0), 1.0), min(max(cx.y2, 0.0), 1.0)))
    if cx.x2 - cx.x1 < 0.003 or cx.y2 - cx.y1 < 0.003:
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "caixa pequena demais")
    return cx


class Dataset:
    def __init__(self, pasta: Path):
        self.pasta = pasta
        self.pasta_imagens = pasta / "imagens"
        self.pasta_miniaturas = pasta / "miniaturas"
        for p in (self.pasta, self.pasta_imagens, self.pasta_miniaturas):
            p.mkdir(parents=True, exist_ok=True)
        self._trava = threading.RLock()
        self._db = sqlite3.connect(pasta / "dataset.db", check_same_thread=False)
        self._db.row_factory = sqlite3.Row
        self._db.execute("PRAGMA foreign_keys = ON")
        self._db.executescript(_ESQUEMA)

    def fechar(self) -> None:
        with self._trava:
            self._db.close()

    # ===== Classes =====
    def classes(self) -> list[dict[str, Any]]:
        with self._trava:
            linhas = self._db.execute(
                """SELECT c.*, (SELECT COUNT(*) FROM caixas x JOIN imagens i ON i.id = x.imagem_id
                                WHERE x.classe_id = c.id AND i.status = 'revisada') AS caixas_revisadas,
                          (SELECT COUNT(*) FROM caixas x JOIN imagens i ON i.id = x.imagem_id
                                WHERE x.classe_id = c.id AND i.status = 'revisada' AND i.divisao = 'treino') AS caixas_treino,
                          (SELECT COUNT(*) FROM caixas x JOIN imagens i ON i.id = x.imagem_id
                                WHERE x.classe_id = c.id AND i.status = 'revisada' AND i.divisao = 'validacao') AS caixas_validacao,
                          (SELECT COUNT(*) FROM imagens i WHERE i.classe_esperada_id = c.id AND i.status != 'descartada') AS imagens
                   FROM classes c ORDER BY c.id"""
            ).fetchall()
        return [dict(r) for r in linhas]

    def criar_classe(self, nome: str, rotulo: str | None = None) -> dict[str, Any]:
        nome = nome.strip().lower().replace(" ", "_")
        if not nome or not all(ch.isalnum() or ch == "_" for ch in nome):
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "nome da classe: só letras, números e _ (ex.: pinca_de_freio)")
        with self._trava:
            existente = self._db.execute("SELECT id FROM classes WHERE nome = ?", (nome,)).fetchone()
            if existente:
                return self.classe(existente["id"])
            n = self._db.execute("SELECT COUNT(*) FROM classes").fetchone()[0]
            cur = self._db.execute(
                "INSERT INTO classes (nome, rotulo, cor, criada_em) VALUES (?, ?, ?, ?)",
                (nome, (rotulo or nome.replace("_", " ").capitalize()).strip(), CORES[n % len(CORES)], time.time()),
            )
            self._db.commit()
            return self.classe(cur.lastrowid)

    def classe(self, classe_id: int) -> dict[str, Any]:
        for c in self.classes():
            if c["id"] == classe_id:
                return c
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"classe {classe_id} não existe")

    def atualizar_classe(self, classe_id: int, rotulo: str | None = None, cor: str | None = None) -> dict[str, Any]:
        self.classe(classe_id)
        with self._trava:
            if rotulo:
                self._db.execute("UPDATE classes SET rotulo = ? WHERE id = ?", (rotulo.strip(), classe_id))
            if cor:
                self._db.execute("UPDATE classes SET cor = ? WHERE id = ?", (cor, classe_id))
            self._db.commit()
        return self.classe(classe_id)

    # ===== Imagens =====
    def adicionar_imagem(self, dados: bytes, origem: str, nome_original: str | None = None, classe_esperada_id: int | None = None) -> tuple[dict[str, Any], bool]:
        """Normaliza e guarda a foto. Devolve (imagem, nova?); uma foto repetida não entra de novo."""
        imagem_id = hashlib.sha1(dados).hexdigest()[:16]
        with self._trava:
            if self._db.execute("SELECT 1 FROM imagens WHERE id = ?", (imagem_id,)).fetchone():
                return self.imagem(imagem_id), False
        try:
            img = ImageOps.exif_transpose(Image.open(io.BytesIO(dados))).convert("RGB")
        except (UnidentifiedImageError, OSError, ImportError):  # o Ultralytics tenta HEIC e falha com ImportError
            raise ErroProtocolo(Codigo.IMAGEM_INVALIDA, f"não consegui abrir {nome_original or 'a imagem'}") from None
        img.thumbnail((LADO_MAX, LADO_MAX), Image.LANCZOS)
        img.save(self.pasta_imagens / f"{imagem_id}.jpg", "JPEG", quality=90)
        mini = img.copy()
        mini.thumbnail((LADO_MINIATURA, LADO_MINIATURA), Image.LANCZOS)
        mini.save(self.pasta_miniaturas / f"{imagem_id}.jpg", "JPEG", quality=80)
        agora = time.time()
        with self._trava:
            self._db.execute(
                """INSERT INTO imagens (id, largura, altura, origem, nome_original, classe_esperada_id, status, divisao, criada_em, atualizada_em)
                   VALUES (?, ?, ?, ?, ?, ?, 'pendente', ?, ?, ?)""",
                (imagem_id, img.width, img.height, origem, nome_original, classe_esperada_id, _divisao(imagem_id), agora, agora),
            )
            self._db.commit()
        return self.imagem(imagem_id), True

    def importar_pasta(self, raiz: Path, rotulos: dict[str, str] | None = None) -> dict[str, Any]:
        """Importa raiz/<classe>/*.jpg. O nome da subpasta vira a classe esperada da foto."""
        rotulos = rotulos or {}
        resumo: dict[str, Any] = {"novas": 0, "repetidas": 0, "erros": [], "por_classe": {}}
        for pasta in sorted(p for p in raiz.iterdir() if p.is_dir()):
            classe = self.criar_classe(pasta.name, rotulos.get(pasta.name))
            novas = 0
            for arq in sorted(f for f in pasta.iterdir() if f.suffix.lower() in EXTENSOES):
                try:
                    _, nova = self.adicionar_imagem(arq.read_bytes(), "importacao", arq.name, classe["id"])
                except ErroProtocolo as e:
                    resumo["erros"].append(e.mensagem)
                    continue
                novas += nova
                resumo["repetidas"] += not nova
            resumo["novas"] += novas
            resumo["por_classe"][classe["rotulo"]] = novas
        return resumo

    def _linha_para_dict(self, r: sqlite3.Row, caixas: Iterable[sqlite3.Row]) -> dict[str, Any]:
        d = dict(r)
        d["caixas"] = [Caixa(x["classe_id"], x["x1"], x["y1"], x["x2"], x["y2"], x["origem"], x["confianca"]).como_dict() for x in caixas]
        return d

    def imagem(self, imagem_id: str) -> dict[str, Any]:
        with self._trava:
            r = self._db.execute("SELECT * FROM imagens WHERE id = ?", (imagem_id,)).fetchone()
            if r is None:
                raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"imagem {imagem_id} não existe")
            caixas = self._db.execute("SELECT * FROM caixas WHERE imagem_id = ? ORDER BY id", (imagem_id,)).fetchall()
        return self._linha_para_dict(r, caixas)

    def listar(self, status: list[str] | None = None, classe_id: int | None = None, divisao: str | None = None, limite: int = 500, desloc: int = 0) -> dict[str, Any]:
        onde, args = [], []
        if status:
            onde.append(f"status IN ({','.join('?' * len(status))})")
            args += status
        if classe_id is not None:
            onde.append("(classe_esperada_id = ? OR id IN (SELECT imagem_id FROM caixas WHERE classe_id = ?))")
            args += [classe_id, classe_id]
        if divisao:
            onde.append("divisao = ?")
            args.append(divisao)
        filtro = f"WHERE {' AND '.join(onde)}" if onde else ""
        with self._trava:
            total = self._db.execute(f"SELECT COUNT(*) FROM imagens {filtro}", args).fetchone()[0]
            linhas = self._db.execute(f"SELECT * FROM imagens {filtro} ORDER BY classe_esperada_id, nome_original, id LIMIT ? OFFSET ?", [*args, limite, desloc]).fetchall()
            ids = [r["id"] for r in linhas]
            caixas: dict[str, list] = {i: [] for i in ids}
            if ids:
                for x in self._db.execute(f"SELECT * FROM caixas WHERE imagem_id IN ({','.join('?' * len(ids))}) ORDER BY id", ids):
                    caixas[x["imagem_id"]].append(x)
        return {"total": total, "itens": [self._linha_para_dict(r, caixas[r["id"]]) for r in linhas]}

    def salvar_caixas(self, imagem_id: str, caixas: list[dict[str, Any]], status: str | None = None) -> dict[str, Any]:
        """Substitui as caixas da imagem. Quem anota no painel manda status='revisada' ao confirmar."""
        atual = self.imagem(imagem_id)
        if status is not None and status not in STATUS:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"status deve ser um de {STATUS}")
        validas = {c["id"] for c in self.classes()}
        novas = []
        for c in caixas:
            cx = _validar_caixa(c, validas)
            cx.origem = c.get("origem") if c.get("origem") in ("manual", "sugestao", "semente") else "manual"
            cx.confianca = c.get("confianca") if cx.origem != "manual" else None
            novas.append(cx)
        if status is None:
            status = atual["status"] if atual["status"] in ("revisada", "descartada") else ("sugerida" if novas else "pendente")
        with self._trava:
            self._db.execute("DELETE FROM caixas WHERE imagem_id = ?", (imagem_id,))
            self._db.executemany(
                "INSERT INTO caixas (imagem_id, classe_id, x1, y1, x2, y2, origem, confianca) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                [(imagem_id, c.classe_id, c.x1, c.y1, c.x2, c.y2, c.origem, c.confianca) for c in novas],
            )
            self._db.execute("UPDATE imagens SET status = ?, atualizada_em = ? WHERE id = ?", (status, time.time(), imagem_id))
            self._db.commit()
        return self.imagem(imagem_id)

    def atualizar_imagem(self, imagem_id: str, status: str | None = None, divisao: str | None = None) -> dict[str, Any]:
        self.imagem(imagem_id)
        if status is not None and status not in STATUS:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"status deve ser um de {STATUS}")
        if divisao is not None and divisao not in DIVISOES:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"divisao deve ser {DIVISOES[0]} ou {DIVISOES[1]}")
        with self._trava:
            if status:
                self._db.execute("UPDATE imagens SET status = ?, atualizada_em = ? WHERE id = ?", (status, time.time(), imagem_id))
            if divisao:
                self._db.execute("UPDATE imagens SET divisao = ? WHERE id = ?", (divisao, imagem_id))
            self._db.commit()
        return self.imagem(imagem_id)

    def rebalancear_divisao(self, fracao_validacao: float = 0.2) -> dict[str, dict[str, int]]:
        """Separa ~20% das fotos revisadas de cada classe para validação (estável: ordena pelo id)."""
        resultado: dict[str, dict[str, int]] = {}
        with self._trava:
            grupos: dict[Any, list[str]] = {}
            for r in self._db.execute(
                """SELECT i.id, COALESCE((SELECT classe_id FROM caixas WHERE imagem_id = i.id LIMIT 1), i.classe_esperada_id, -1) AS g
                   FROM imagens i WHERE status = 'revisada' ORDER BY i.id"""
            ):
                grupos.setdefault(r["g"], []).append(r["id"])
            nomes = {c["id"]: c["rotulo"] for c in self.classes()}
            for g, ids in grupos.items():
                n_val = max(1, round(len(ids) * fracao_validacao)) if len(ids) >= 5 else 0
                # Intercala para a validação pegar fotos espalhadas, não só as do começo.
                passo = len(ids) / n_val if n_val else 0
                val = {ids[int(k * passo)] for k in range(n_val)}
                for i in ids:
                    self._db.execute("UPDATE imagens SET divisao = ? WHERE id = ?", ("validacao" if i in val else "treino", i))
                resultado[nomes.get(g, "sem caixa")] = {"treino": len(ids) - len(val), "validacao": len(val)}
            self._db.commit()
        return resultado

    def caminho_imagem(self, imagem_id: str, miniatura: bool = False) -> Path:
        self.imagem(imagem_id)
        return (self.pasta_miniaturas if miniatura else self.pasta_imagens) / f"{imagem_id}.jpg"

    def resumo(self) -> dict[str, Any]:
        with self._trava:
            por_status = {s: 0 for s in STATUS}
            for r in self._db.execute("SELECT status, COUNT(*) n FROM imagens GROUP BY status"):
                por_status[r["status"]] = r["n"]
            por_divisao = {d: 0 for d in DIVISOES}
            for r in self._db.execute("SELECT divisao, COUNT(*) n FROM imagens WHERE status = 'revisada' GROUP BY divisao"):
                por_divisao[r["divisao"]] = r["n"]
        return {"imagens": {"total": sum(por_status.values()), **por_status}, "revisadas_por_divisao": por_divisao, "classes": self.classes()}

    def referencias(self, classe_id: int, maximo: int = 3) -> list[tuple[Path, list[float]]]:
        """Exemplos visuais para o sugestor: caixas revisadas mais recentes; sem elas, as sementes."""
        with self._trava:
            linhas = self._db.execute(
                """SELECT x.imagem_id, x.x1, x.y1, x.x2, x.y2 FROM caixas x JOIN imagens i ON i.id = x.imagem_id
                   WHERE x.classe_id = ? AND i.status = 'revisada' ORDER BY i.atualizada_em DESC LIMIT ?""",
                (classe_id, maximo),
            ).fetchall()
            if not linhas:
                linhas = self._db.execute(
                    "SELECT imagem_id, x1, y1, x2, y2 FROM caixas WHERE classe_id = ? AND origem = 'semente' LIMIT ?", (classe_id, maximo)
                ).fetchall()
        return [(self.pasta_imagens / f"{r['imagem_id']}.jpg", [r["x1"], r["y1"], r["x2"], r["y2"]]) for r in linhas]

    def ids_para_sugerir(self, todas: bool = False) -> list[str]:
        """Fotos ainda não revisadas (por padrão, só as que não têm nenhuma caixa)."""
        with self._trava:
            sql = "SELECT id FROM imagens WHERE status IN ('pendente', 'sugerida')"
            if not todas:
                sql += " AND id NOT IN (SELECT imagem_id FROM caixas)"
            return [r["id"] for r in self._db.execute(sql + " ORDER BY classe_esperada_id, nome_original")]

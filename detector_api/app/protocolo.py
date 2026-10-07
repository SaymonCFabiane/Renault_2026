"""Formato das mensagens entre app e API.

App → API (WebSocket, mensagem binária):
    [4 bytes: tamanho N do cabeçalho, big-endian][N bytes: cabeçalho JSON UTF-8][bytes do JPEG]
    cabeçalho: {"tipo": "quadro", "seq": 1842, "capturado_em": 1759840000123, "rotacao": 90}

App → API (WebSocket, mensagem de texto JSON):
    {"tipo": "config", "confianca": 0.4, "classes": [0, 67], "imgsz": 640}
    {"tipo": "status"}

API → App (texto JSON): "deteccoes", "descartado", "config_ok", "status" ou "erro".
"""

import json
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any

MAX_CABECALHO = 4096
ROTACOES = (0, 90, 180, 270)


class Codigo(StrEnum):
    CABECALHO_INVALIDO = "CABECALHO_INVALIDO"
    IMAGEM_INVALIDA = "IMAGEM_INVALIDA"
    IMAGEM_GRANDE_DEMAIS = "IMAGEM_GRANDE_DEMAIS"
    PARAMETRO_INVALIDO = "PARAMETRO_INVALIDO"
    MENSAGEM_DESCONHECIDA = "MENSAGEM_DESCONHECIDA"
    MODELO_INDISPONIVEL = "MODELO_INDISPONIVEL"
    ERRO_INTERNO = "ERRO_INTERNO"


class ErroProtocolo(Exception):
    def __init__(self, codigo: Codigo, mensagem: str, seq: int | None = None):
        super().__init__(mensagem)
        self.codigo = codigo
        self.mensagem = mensagem
        self.seq = seq


def erro_ws(codigo: Codigo, mensagem: str, seq: int | None = None) -> dict[str, Any]:
    return {"tipo": "erro", "codigo": str(codigo), "mensagem": mensagem, "seq": seq}


def erro_http(codigo: Codigo, mensagem: str) -> dict[str, Any]:
    return {"erro": {"codigo": str(codigo), "mensagem": mensagem}}


@dataclass
class Quadro:
    seq: int
    capturado_em: float | None
    rotacao: int
    jpeg: bytes
    recebido_em: float = 0.0


@dataclass
class Parametros:
    """Parâmetros de inferência. Cada conexão começa com os da configuração e pode ajustar."""

    confianca: float
    classes: list[int] | None
    imgsz: int
    iou: float = 0.7

    def como_dict(self) -> dict[str, Any]:
        return {"confianca": self.confianca, "classes": self.classes, "imgsz": self.imgsz}

    def com_ajustes(self, dados: dict[str, Any], total_classes: int) -> "Parametros":
        """Valida e aplica os campos presentes em `dados`. Levanta ErroProtocolo se algo for inválido."""
        novo = Parametros(self.confianca, self.classes, self.imgsz, self.iou)
        if "confianca" in dados and dados["confianca"] is not None:
            c = dados["confianca"]
            if not isinstance(c, (int, float)) or isinstance(c, bool) or not 0 <= c <= 1:
                raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "confianca deve ser um número entre 0 e 1")
            novo.confianca = float(c)
        if "classes" in dados:
            novo.classes = validar_classes(dados["classes"], total_classes)
        if "imgsz" in dados and dados["imgsz"] is not None:
            s = dados["imgsz"]
            if not isinstance(s, int) or isinstance(s, bool) or not 32 <= s <= 1920 or s % 32:
                raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "imgsz deve ser múltiplo de 32 entre 32 e 1920")
            novo.imgsz = s
        return novo


def validar_classes(valor: Any, total: int) -> list[int] | None:
    if valor is None or valor == [] or valor == "":
        return None
    if isinstance(valor, str):
        try:
            valor = [int(x) for x in valor.split(",") if x.strip()]
        except ValueError:
            raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "classes deve ser uma lista de ids, ex.: 0,67") from None
    if not isinstance(valor, list) or not all(isinstance(x, int) and not isinstance(x, bool) for x in valor):
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "classes deve ser uma lista de ids inteiros")
    fora = [x for x in valor if not 0 <= x < total]
    if fora:
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, f"classes fora do modelo (0 a {total - 1}): {fora}")
    return sorted(set(valor))


def validar_rotacao(r: Any) -> int:
    if r is None:
        return 0
    if r not in ROTACOES or isinstance(r, bool):
        raise ErroProtocolo(Codigo.PARAMETRO_INVALIDO, "rotacao deve ser 0, 90, 180 ou 270")
    return int(r)


def ler_quadro(dados: bytes, max_bytes: int) -> Quadro:
    """Desempacota a mensagem binária de quadro. Levanta ErroProtocolo se estiver malformada."""
    if len(dados) > max_bytes:
        raise ErroProtocolo(Codigo.IMAGEM_GRANDE_DEMAIS, f"quadro com {len(dados)} bytes; o limite é {max_bytes}")
    if len(dados) < 4:
        raise ErroProtocolo(Codigo.CABECALHO_INVALIDO, "mensagem binária curta demais")
    n = int.from_bytes(dados[:4], "big")
    if not 0 < n <= MAX_CABECALHO or len(dados) < 4 + n:
        raise ErroProtocolo(Codigo.CABECALHO_INVALIDO, "tamanho do cabeçalho inválido")
    try:
        cab = json.loads(dados[4 : 4 + n].decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise ErroProtocolo(Codigo.CABECALHO_INVALIDO, "o cabeçalho não é um JSON válido") from None
    if not isinstance(cab, dict) or cab.get("tipo") != "quadro":
        raise ErroProtocolo(Codigo.CABECALHO_INVALIDO, 'o cabeçalho precisa ter "tipo": "quadro"')
    seq = cab.get("seq")
    if not isinstance(seq, int) or isinstance(seq, bool) or seq < 0:
        raise ErroProtocolo(Codigo.CABECALHO_INVALIDO, "seq deve ser um inteiro ≥ 0")
    cap = cab.get("capturado_em")
    if cap is not None and (not isinstance(cap, (int, float)) or isinstance(cap, bool)):
        raise ErroProtocolo(Codigo.CABECALHO_INVALIDO, "capturado_em deve ser um número (ms desde a época)", seq)
    try:
        rot = validar_rotacao(cab.get("rotacao"))
    except ErroProtocolo as e:
        e.seq = seq
        raise
    jpeg = dados[4 + n :]
    if len(jpeg) < 4 or jpeg[:2] != b"\xff\xd8":
        raise ErroProtocolo(Codigo.IMAGEM_INVALIDA, "o corpo não é um JPEG", seq)
    return Quadro(seq=seq, capturado_em=cap, rotacao=rot, jpeg=jpeg)


def montar_quadro(seq: int, jpeg: bytes, capturado_em: float | None = None, rotacao: int = 0) -> bytes:
    """Empacota um quadro (usado pelo cliente de teste e pelos testes)."""
    cab = json.dumps({"tipo": "quadro", "seq": seq, "capturado_em": capturado_em, "rotacao": rotacao}).encode()
    return len(cab).to_bytes(4, "big") + cab + jpeg


@dataclass
class Deteccao:
    classe_id: int
    classe: str
    confianca: float
    caixa: tuple[float, float, float, float]  # x1, y1, x2, y2 normalizados (0–1)

    def como_dict(self) -> dict[str, Any]:
        x1, y1, x2, y2 = self.caixa
        return {
            "classe_id": self.classe_id,
            "classe": self.classe,
            "confianca": round(self.confianca, 4),
            "caixa": {"x1": round(x1, 5), "y1": round(y1, 5), "x2": round(x2, 5), "y2": round(y2, 5)},
        }


@dataclass
class Resultado:
    largura: int  # dimensões da imagem já girada (referência das caixas)
    altura: int
    inferencia_ms: float
    deteccoes: list[Deteccao] = field(default_factory=list)

    def como_dict(self, seq: int | None = None, capturado_em: float | None = None, processamento_ms: float | None = None) -> dict[str, Any]:
        d: dict[str, Any] = {"tipo": "deteccoes"}
        if seq is not None:
            d["seq"] = seq
        d["capturado_em"] = capturado_em
        d["largura"] = self.largura
        d["altura"] = self.altura
        d["inferencia_ms"] = round(self.inferencia_ms, 2)
        if processamento_ms is not None:
            d["processamento_ms"] = round(processamento_ms, 2)
        d["deteccoes"] = [x.como_dict() for x in self.deteccoes]
        return d

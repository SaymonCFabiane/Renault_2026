"""Configuração da API, lida de variáveis de ambiente (prefixo TRACEPRO_) ou do arquivo .env."""

from pathlib import Path
from typing import Annotated, Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

RAIZ = Path(__file__).resolve().parent.parent
VERSAO = "0.1.0"


class Config(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="TRACEPRO_", env_file=RAIZ / ".env", extra="ignore")

    # Modelo: nome de arquivo dentro de modelos/ (ex.: yolo11n.pt) ou caminho absoluto.
    modelo: str = "yolo11n.pt"
    # auto escolhe mps (Apple Silicon) → cuda (NVIDIA) → cpu.
    dispositivo: Literal["auto", "mps", "cuda", "cpu"] = "auto"
    confianca: float = Field(0.25, ge=0.0, le=1.0)
    iou: float = Field(0.7, ge=0.0, le=1.0)
    # Filtro opcional de classes por id (ex.: TRACEPRO_CLASSES=0,67). Vazio = todas.
    classes: Annotated[list[int] | None, NoDecode] = None
    imgsz: int = Field(640, ge=32, le=1920)

    host: str = "0.0.0.0"
    porta: int = 8000
    # Origens do painel React liberadas no CORS.
    cors_origens: Annotated[list[str], NoDecode] = ["http://localhost:5174", "http://127.0.0.1:5174"]
    # Tamanho máximo de um quadro ou imagem recebida.
    max_bytes_imagem: int = 4 * 1024 * 1024

    @field_validator("classes", mode="before")
    @classmethod
    def _classes(cls, v):
        if v is None or v == "":
            return None
        if isinstance(v, str):
            return [int(x) for x in v.split(",") if x.strip()]
        return v

    @field_validator("cors_origens", mode="before")
    @classmethod
    def _origens(cls, v):
        if isinstance(v, str):
            return [x.strip() for x in v.split(",") if x.strip()]
        return v

    @field_validator("imgsz")
    @classmethod
    def _imgsz(cls, v: int) -> int:
        if v % 32:
            raise ValueError("imgsz precisa ser múltiplo de 32")
        return v

    def caminho_modelo(self) -> Path:
        p = Path(self.modelo)
        return p if p.is_absolute() else RAIZ / "modelos" / p

"""Sugestão de caixas por exemplo visual (YOLOE).

Para cada classe, o sugestor pega até 3 fotos já revisadas como exemplo ("esta é a peça") e procura a
mesma peça nas fotos ainda não revisadas. Quanto mais fotos você revisa, melhores ficam as sugestões.
Sem nenhuma revisada, usa as caixas-semente da importação.
"""

import asyncio
import logging
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from typing import Any

import numpy as np
from PIL import Image

from .config import Config
from .dataset import Dataset

log = logging.getLogger("tracepro.sugestor")
CONF_MINIMA = 0.05


class SugestorVisual:
    def __init__(self, config: Config, dispositivo: str):
        self.config = config
        self.dispositivo = dispositivo
        self._modelo = None

    def _carregar(self):
        if self._modelo is None:
            from ultralytics import YOLOE

            caminho = self.config.caminho_modelo(self.config.modelo_sugestao)
            if not caminho.exists():
                raise FileNotFoundError(f"modelo de sugestão não encontrado: {caminho}. Rode: python baixar_modelo.py {self.config.modelo_sugestao}")
            self._modelo = YOLOE(str(caminho))
        return self._modelo

    def sugerir(self, alvo, referencias: list[tuple[Any, list[float]]]) -> tuple[float, list[float]] | None:
        """Melhor caixa (normalizada) da peça na imagem `alvo`, usando cada referência como exemplo."""
        from ultralytics.models.yolo.yoloe import YOLOEVPSegPredictor

        modelo = self._carregar()
        melhor = None
        for ref, caixa in referencias:
            with Image.open(ref) as im:
                w, h = im.size
            px = np.array([[caixa[0] * w, caixa[1] * h, caixa[2] * w, caixa[3] * h]])
            r = modelo.predict(
                str(alvo), refer_image=str(ref), visual_prompts={"bboxes": px, "cls": np.array([0])},
                predictor=YOLOEVPSegPredictor, conf=CONF_MINIMA, device=self.dispositivo, verbose=False,
            )[0]
            if r.boxes is not None and len(r.boxes):
                i = int(r.boxes.conf.argmax())
                c = float(r.boxes.conf[i])
                if melhor is None or c > melhor[0]:
                    melhor = (c, [float(v) for v in r.boxes.xyxyn[i].tolist()])
        return melhor


@dataclass
class Tarefa:
    rodando: bool = False
    total: int = 0
    feitas: int = 0
    com_caixa: int = 0
    sem_caixa: int = 0
    erro: str | None = None
    iniciada_em: float | None = None
    concluida_em: float | None = None
    _tarefa: Any = field(default=None, repr=False)

    def como_dict(self) -> dict[str, Any]:
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}


async def sugerir_em_lote(dataset: Dataset, sugestor: SugestorVisual, executor: ThreadPoolExecutor, tarefa: Tarefa, todas: bool = False) -> None:
    """Sugere caixas para as fotos não revisadas. Roda na mesma thread da GPU que a detecção, foto a foto,
    para não travar o vídeo ao vivo."""
    loop = asyncio.get_running_loop()
    ids = dataset.ids_para_sugerir(todas)
    tarefa.rodando, tarefa.total, tarefa.feitas, tarefa.com_caixa, tarefa.sem_caixa = True, len(ids), 0, 0, 0
    tarefa.erro, tarefa.iniciada_em, tarefa.concluida_em = None, time.time(), None
    refs_por_classe: dict[int, list] = {}
    try:
        for imagem_id in ids:
            img = dataset.imagem(imagem_id)
            classe_id = img["classe_esperada_id"]
            if classe_id is None:  # sem classe esperada: não há exemplo para procurar
                tarefa.sem_caixa += 1
                tarefa.feitas += 1
                continue
            if classe_id not in refs_por_classe:
                refs_por_classe[classe_id] = dataset.referencias(classe_id)
            refs = [r for r in refs_por_classe[classe_id] if r[0].stem != imagem_id]
            if not refs:
                tarefa.sem_caixa += 1
                tarefa.feitas += 1
                continue
            achado = await loop.run_in_executor(executor, sugestor.sugerir, dataset.caminho_imagem(imagem_id), refs)
            if dataset.imagem(imagem_id)["status"] in ("revisada", "descartada"):  # revisada enquanto a sugestão rodava
                tarefa.feitas += 1
                continue
            if achado:
                conf, (x1, y1, x2, y2) = achado
                dataset.salvar_caixas(
                    imagem_id,
                    [{"classe_id": classe_id, "x1": x1, "y1": y1, "x2": x2, "y2": y2, "origem": "sugestao", "confianca": conf}],
                )
                tarefa.com_caixa += 1
            else:
                tarefa.sem_caixa += 1
            tarefa.feitas += 1
    except Exception as e:
        log.exception("falha ao sugerir caixas")
        tarefa.erro = str(e)
    finally:
        tarefa.rodando = False
        tarefa.concluida_em = time.time()

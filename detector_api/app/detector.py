"""Carrega o YOLO uma única vez e roda a inferência numa thread dedicada (fora do loop de eventos)."""

import asyncio
import logging
import time
from concurrent.futures import ThreadPoolExecutor

import cv2
import numpy as np

from .config import Config
from .protocolo import Codigo, Deteccao, ErroProtocolo, Parametros, Resultado

log = logging.getLogger("tracepro.detector")

_ROTACAO_CV2 = {90: cv2.ROTATE_90_CLOCKWISE, 180: cv2.ROTATE_180, 270: cv2.ROTATE_90_COUNTERCLOCKWISE}


def escolher_dispositivo(pedido: str) -> str:
    import torch

    if pedido != "auto":
        return pedido
    if torch.backends.mps.is_available():
        return "mps"
    if torch.cuda.is_available():
        return "cuda"
    return "cpu"


def decodificar(jpeg: bytes, rotacao: int) -> np.ndarray:
    """JPEG → imagem BGR, já girada no sentido horário para ficar "em pé"."""
    img = cv2.imdecode(np.frombuffer(jpeg, np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        raise ErroProtocolo(Codigo.IMAGEM_INVALIDA, "não foi possível decodificar o JPEG")
    if rotacao:
        img = cv2.rotate(img, _ROTACAO_CV2[rotacao])
    return img


class Detector:
    def __init__(self, config: Config):
        from ultralytics import YOLO

        self.config = config
        caminho = config.caminho_modelo()
        if not caminho.exists():
            raise FileNotFoundError(f"modelo não encontrado: {caminho}. Rode: python baixar_modelo.py {config.modelo}")
        self.dispositivo = escolher_dispositivo(config.dispositivo)
        self.nome_modelo = caminho.name
        self.modelo = YOLO(str(caminho))
        self.nomes: dict[int, str] = {int(k): v for k, v in self.modelo.names.items()}
        # Uma única thread: o MPS/CUDA não deve receber inferências concorrentes.
        self._executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="yolo")
        self._aquecer()
        log.info("modelo %s carregado em %s (%d classes)", self.nome_modelo, self.dispositivo, len(self.nomes))

    def parametros_padrao(self) -> Parametros:
        c = self.config
        return Parametros(confianca=c.confianca, classes=c.classes, imgsz=c.imgsz, iou=c.iou)

    def _aquecer(self) -> None:
        # No MPS, a primeira inferência de cada formato de entrada é lenta (compilação de kernels).
        # Aquecemos os formatos mais comuns antes de abrir a porta: retrato do app, paisagem, 16:9 e quadrado.
        for h, w in ((640, 480), (480, 640), (720, 1280), (1280, 720), (640, 640)):
            vazio = np.zeros((h, w, 3), dtype=np.uint8)
            for _ in range(2):
                self.modelo.predict(vazio, imgsz=self.config.imgsz, device=self.dispositivo, verbose=False)

    def detectar_sync(self, img: np.ndarray, p: Parametros) -> Resultado:
        t0 = time.perf_counter()
        r = self.modelo.predict(
            img, conf=p.confianca, iou=p.iou, classes=p.classes, imgsz=p.imgsz, device=self.dispositivo, verbose=False
        )[0]
        inferencia_ms = (time.perf_counter() - t0) * 1000
        h, w = img.shape[:2]
        dets: list[Deteccao] = []
        if r.boxes is not None and len(r.boxes):
            caixas = r.boxes.xyxyn.cpu().numpy().clip(0, 1)
            confs = r.boxes.conf.cpu().numpy()
            ids = r.boxes.cls.cpu().numpy().astype(int)
            for (x1, y1, x2, y2), conf, cid in zip(caixas, confs, ids):
                dets.append(Deteccao(int(cid), self.nomes.get(int(cid), str(cid)), float(conf), (float(x1), float(y1), float(x2), float(y2))))
        return Resultado(largura=w, altura=h, inferencia_ms=inferencia_ms, deteccoes=dets)

    def _decodificar_e_detectar(self, jpeg: bytes, rotacao: int, p: Parametros) -> Resultado:
        return self.detectar_sync(decodificar(jpeg, rotacao), p)

    async def detectar(self, jpeg: bytes, rotacao: int, p: Parametros) -> Resultado:
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(self._executor, self._decodificar_e_detectar, jpeg, rotacao, p)

    def info(self) -> dict:
        import torch
        import ultralytics

        return {
            "modelo": self.nome_modelo,
            "dispositivo": self.dispositivo,
            "classes": self.nomes,
            "versoes": {"ultralytics": ultralytics.__version__, "torch": torch.__version__},
        }

    def fechar(self) -> None:
        self._executor.shutdown(wait=False, cancel_futures=True)

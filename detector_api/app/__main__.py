"""Sobe a API: python -m app  (lê host e porta da configuração)."""

import logging
import os
import socket

import uvicorn

from .config import Config


def ips_locais() -> list[str]:
    """IPs IPv4 desta máquina na rede local, para configurar o app."""
    ips: set[str] = set()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("10.255.255.255", 1))  # não envia nada; só escolhe a interface de saída
            ips.add(s.getsockname()[0])
    except OSError:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ips.add(info[4][0])
    except OSError:
        pass
    return sorted(ip for ip in ips if not ip.startswith("127."))


def main() -> None:
    # Sem telemetria do Ultralytics e sem downloads inesperados (os modelos vêm de baixar_modelo.py).
    os.environ.setdefault("YOLO_OFFLINE", "1")
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    c = Config()
    print("\nTracePro · API de detecção", flush=True)
    print(f"  Modelo: {c.modelo} · confiança {c.confianca} · imgsz {c.imgsz}")
    for ip in ips_locais() or ["<IP do Mac>"]:
        print(f"  No app, use o servidor  {ip}:{c.porta}   (ws://{ip}:{c.porta}/ws/detectar)", flush=True)
    print(f"  Documentação: http://localhost:{c.porta}/docs\n", flush=True)
    uvicorn.run("app.main:app", host=c.host, port=c.porta, log_level="info", ws_max_size=c.max_bytes_imagem + 8192)


if __name__ == "__main__":
    main()

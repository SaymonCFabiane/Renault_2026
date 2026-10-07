"""Baixa um modelo YOLO pré-treinado para a pasta modelos/.

Uso: python baixar_modelo.py [nome]   (padrão: yolo11n.pt; ex.: yolo11s.pt, yolo11m.pt)
"""

import shutil
import sys
from pathlib import Path

from ultralytics.utils.downloads import attempt_download_asset

DESTINO = Path(__file__).resolve().parent / "modelos"


def main() -> None:
    nome = sys.argv[1] if len(sys.argv) > 1 else "yolo11n.pt"
    DESTINO.mkdir(exist_ok=True)
    alvo = DESTINO / nome
    if alvo.exists():
        print(f"Já existe: {alvo}")
        return
    baixado = Path(attempt_download_asset(nome))  # baixa dos releases oficiais da Ultralytics
    if baixado.resolve() != alvo.resolve():
        shutil.move(str(baixado), alvo)
    print(f"Modelo salvo em {alvo} ({alvo.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()

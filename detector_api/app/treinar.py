"""Processo de treino (iniciado pela API; não é para rodar à mão).

python -m app.treinar <pasta_do_treino> <modelo_base> <epocas> <imgsz> <dispositivo> <pasta_modelos>

Grava o progresso em <pasta_do_treino>/info.json a cada época e, no fim, copia o melhor
modelo para <pasta_modelos>/tracepro-<id>.pt com um .json de metadados ao lado.
"""

import os
import shutil
import sys
import time
from pathlib import Path

os.environ.setdefault("YOLO_OFFLINE", "1")  # sem telemetria nem downloads durante o treino

from .treino import gravar_json, ler_json  # noqa: E402


def _num(v) -> float | None:
    try:
        return round(float(v), 4)
    except (TypeError, ValueError):
        return None


def main() -> None:
    pasta, base, epocas, imgsz, dispositivo, pasta_modelos = sys.argv[1:7]
    pasta, pasta_modelos = Path(pasta), Path(pasta_modelos)
    epocas, imgsz = int(epocas), int(imgsz)
    info_p = pasta / "info.json"
    info = ler_json(info_p)

    def salvar(**k) -> None:
        info.update(k)
        gravar_json(info_p, info)

    from ultralytics import YOLO

    modelo = YOLO(base)
    inicio = time.time()
    em_epoca = {"sim": False}

    def ao_fim_do_treino_da_epoca(trainer) -> None:
        em_epoca["sim"] = True

    def ao_fim_da_epoca(trainer) -> None:
        # O Ultralytics chama este evento também na validação final do best.pt (sem época de treino antes):
        # esse é o resultado oficial do modelo salvo, e não entra no gráfico por época.
        final = not em_epoca["sim"]
        em_epoca["sim"] = False
        m = trainer.metrics or {}
        perdas = trainer.label_loss_items(trainer.tloss, prefix="treino") if trainer.tloss is not None else {}
        linha = {
            "epoca": trainer.epoch + 1,
            "map50": _num(m.get("metrics/mAP50(B)")),
            "map50_95": _num(m.get("metrics/mAP50-95(B)")),
            "precisao": _num(m.get("metrics/precision(B)")),
            "revocacao": _num(m.get("metrics/recall(B)")),
            "perda_caixa": _num(perdas.get("treino/box_loss")),
            "perda_classe": _num(perdas.get("treino/cls_loss")),
            "segundos": round(time.time() - inicio, 1),
        }
        hist = info.get("historico", [])
        if final:
            melhor_epoca = max(hist, key=lambda x: (x["map50_95"] or 0))["epoca"] if hist else None
            salvar(melhor={**linha, "epoca": melhor_epoca})
            return
        hist = hist + [linha]
        melhor = max(hist, key=lambda x: (x["map50_95"] or 0))
        salvar(situacao="treinando", epoca=trainer.epoch + 1, epocas=trainer.epochs, historico=hist, melhor=melhor)

    modelo.add_callback("on_train_epoch_end", ao_fim_do_treino_da_epoca)
    modelo.add_callback("on_fit_epoch_end", ao_fim_da_epoca)
    salvar(situacao="treinando", iniciado_em=inicio)
    try:
        modelo.train(
            data=str(pasta / "dataset" / "data.yaml"),
            epochs=epocas,
            imgsz=imgsz,
            batch=16,
            device=dispositivo,
            patience=max(15, epocas // 4),  # para sozinho se parar de melhorar
            project=str(pasta),
            name="run",
            exist_ok=True,
            cache="ram",
            workers=2,
            plots=False,
            verbose=False,
            seed=0,
        )
    except Exception as e:  # o painel mostra a mensagem
        salvar(situacao="erro", mensagem=f"{type(e).__name__}: {e}", concluido_em=time.time())
        raise

    melhor_pt = pasta / "run" / "weights" / "best.pt"
    if not melhor_pt.exists():
        salvar(situacao="erro", mensagem="O treino terminou sem gerar best.pt.", concluido_em=time.time())
        sys.exit(1)
    nome = f"tracepro-{info['id']}.pt"
    shutil.copy2(melhor_pt, pasta_modelos / nome)
    salvar(situacao="concluido", modelo=nome, concluido_em=time.time())
    gravar_json((pasta_modelos / nome).with_suffix(".json"), {k: v for k, v in info.items() if k != "log"})


if __name__ == "__main__":
    main()

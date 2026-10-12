"""Importa as fotos de midia/<classe>/ para o dataset de treino (dados/) e, opcionalmente, sugere as caixas.

Uso:
    python importar_midia.py               # importa (fotos repetidas são ignoradas)
    python importar_midia.py --sugerir     # importa e já sugere as caixas com o YOLOE
    python importar_midia.py outra_pasta/  # importa de outra pasta com a mesma estrutura

Depois, revise as caixas no painel (http://localhost:5174 → Dataset).
"""

import argparse
import asyncio
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from app.config import RAIZ, Config
from app.dataset import Dataset
from app.detector import escolher_dispositivo
from app.sugestor import SugestorVisual, Tarefa, sugerir_em_lote

# Como cada pasta aparece no app e no painel.
ROTULOS = {"engrenagem": "Engrenagem", "pinca_de_freio": "Pinça de freio"}

# Caixas-semente: um exemplo marcado à mão de cada peça, para a primeira rodada de sugestões.
# Depois que houver fotos revisadas no painel, o sugestor passa a usar elas como exemplo.
SEMENTES = {
    "engrenagem": [
        ("WhatsApp Image 2026-10-07 at 21.35.27.jpeg", (0.360, 0.325, 0.816, 0.675)),
        ("WhatsApp Image 2026-10-07 at 21.36.28.jpeg", (0.260, 0.420, 0.573, 0.645)),
    ],
    "pinca_de_freio": [("WhatsApp Image 2026-10-08 at 19.40.47.jpeg", (0.156, 0.388, 0.773, 0.770))],
}


def aplicar_sementes(ds: Dataset) -> int:
    n = 0
    classes = {c["nome"]: c["id"] for c in ds.classes()}
    for nome, sementes in SEMENTES.items():
        if nome not in classes:
            continue
        itens = ds.listar(classe_id=classes[nome], limite=2000)["itens"]
        por_nome = {i["nome_original"]: i for i in itens}
        for arquivo, (x1, y1, x2, y2) in sementes:
            img = por_nome.get(arquivo)
            if img and not img["caixas"] and img["status"] == "pendente":
                ds.salvar_caixas(img["id"], [{"classe_id": classes[nome], "x1": x1, "y1": y1, "x2": x2, "y2": y2, "origem": "semente"}])
                n += 1
    return n


async def sugerir(ds: Dataset, config: Config) -> None:
    sugestor = SugestorVisual(config, escolher_dispositivo(config.dispositivo))
    tarefa = Tarefa()
    with ThreadPoolExecutor(max_workers=1) as gpu:
        trabalho = asyncio.create_task(sugerir_em_lote(ds, sugestor, gpu, tarefa))
        while not trabalho.done():
            await asyncio.sleep(1)
            print(f"\r  Sugerindo caixas: {tarefa.feitas}/{tarefa.total}", end="", flush=True)
        await trabalho
    print(f"\r  Sugestões: {tarefa.com_caixa} fotos com caixa, {tarefa.sem_caixa} sem (você marca no painel).")
    if tarefa.erro:
        print("  Erro:", tarefa.erro)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("pasta", nargs="?", default=str(RAIZ / "midia"))
    p.add_argument("--sugerir", action="store_true", help="sugere as caixas depois de importar")
    a = p.parse_args()
    pasta = Path(a.pasta)
    if not pasta.is_dir():
        sys.exit(f"Pasta não encontrada: {pasta}")
    config = Config()
    ds = Dataset(config.dados_dir)
    r = ds.importar_pasta(pasta, ROTULOS)
    print(f"Importação: {r['novas']} fotos novas, {r['repetidas']} já estavam no dataset.")
    for rotulo, n in r["por_classe"].items():
        print(f"  {rotulo}: +{n}")
    for e in r["erros"]:
        print("  Erro:", e)
    if n := aplicar_sementes(ds):
        print(f"  {n} caixas-semente aplicadas.")
    if a.sugerir:
        asyncio.run(sugerir(ds, config))
    res = ds.resumo()["imagens"]
    print(f"Dataset: {res['total']} fotos · {res['pendente']} sem caixa · {res['sugerida']} com sugestão · {res['revisada']} revisadas")
    ds.fechar()


if __name__ == "__main__":
    main()

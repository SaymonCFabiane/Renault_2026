# TracePro · API de detecção

API em Python que detecta objetos em tempo real com Ultralytics YOLO. O app Android manda os quadros da câmera pela rede Wi-Fi, a API roda o YOLO no Mac e devolve as caixas para o app desenhar.

```
App: câmera → JPEG 640×480 (q70) → WebSocket ─┐
                                              ▼
API: recebe → guarda o quadro mais recente → thread de inferência (YOLO no MPS) → JSON com as caixas
```

## Instalar (uma vez)

Precisa do [uv](https://docs.astral.sh/uv/) (`brew install uv`). O PyTorch ainda não tem versão para o Python 3.14, por isso o ambiente usa o 3.12.

```bash
cd ~/Documents/GitHub/Test/detector_api
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python -r requirements-dev.txt
.venv/bin/python baixar_modelo.py            # baixa modelos/yolo11n.pt (5,4 MB)
```

Outros modelos: `.venv/bin/python baixar_modelo.py yolo11s.pt` (mais preciso, mais lento).

## Rodar

```bash
cd ~/Documents/GitHub/Test/detector_api
.venv/bin/python -m app
```

O terminal mostra o endereço para configurar no app, por exemplo `10.10.10.108:8000`. Na primeira vez, o macOS pergunta se o Python pode aceitar conexões de rede: responda **Permitir**. Sem isso, o celular não alcança a API.

A documentação interativa fica em http://localhost:8000/docs.

## Configuração

Por variável de ambiente ou num arquivo `.env` nesta pasta (prefixo `TRACEPRO_`):

| Variável | Padrão | O que faz |
| --- | --- | --- |
| `TRACEPRO_MODELO` | `yolo11n.pt` | Arquivo em `modelos/` ou caminho absoluto |
| `TRACEPRO_DISPOSITIVO` | `auto` | `auto` escolhe `mps` (Apple Silicon), depois `cuda`, depois `cpu` |
| `TRACEPRO_CONFIANCA` | `0.25` | Confiança mínima (0–1) |
| `TRACEPRO_IOU` | `0.7` | Limiar de IoU da supressão de caixas repetidas |
| `TRACEPRO_CLASSES` | vazio | Filtro de classes por id, ex.: `0,67` (vazio = todas) |
| `TRACEPRO_IMGSZ` | `640` | Tamanho de entrada (múltiplo de 32) |
| `TRACEPRO_PORTA` | `8000` | Porta (a API escuta em `0.0.0.0`) |
| `TRACEPRO_CORS_ORIGENS` | `http://localhost:5174,http://127.0.0.1:5174` | Origens liberadas para o painel |
| `TRACEPRO_DADOS_DIR` | `dados/` | Onde fica o dataset de treino |
| `TRACEPRO_MODELOS_DIR` | `modelos/` | Onde ficam os modelos (`.pt`) |
| `TRACEPRO_MODELO_SUGESTAO` | `yoloe-11l-seg.pt` | Modelo que sugere as caixas |

Cada conexão WebSocket pode ajustar confiança, classes e imgsz só para ela (mensagem `config`).

## Endpoints

### `GET /status`
```json
{"status": "ok", "versao": "0.1.0", "modelo": "yolo11n.pt", "dispositivo": "mps", "conexoes_ativas": 1,
 "parametros": {"confianca": 0.25, "classes": null, "imgsz": 640, "iou": 0.7},
 "classes": {"0": "person", "1": "bicycle", "…": "…"}, "versoes": {"ultralytics": "8.4.174", "torch": "2.14.1"}}
```
Se o modelo não carregar, a API sobe mesmo assim, com `"status": "erro"` e o motivo em `"erro"`.

### `POST /detectar`
Envia uma imagem (multipart, campo `imagem`). Parâmetros opcionais na URL: `confianca`, `classes` (ex.: `0,5`), `imgsz` e `rotacao` (0, 90, 180 ou 270).
```bash
curl -F imagem=@foto.jpg "http://localhost:8000/detectar?confianca=0.4"
```
A resposta tem o mesmo formato das detecções do WebSocket, sem o `seq`.

### `WS /ws/detectar`
**App → API, quadro** (mensagem binária):
```
[4 bytes: tamanho N do cabeçalho, big-endian][N bytes: cabeçalho JSON UTF-8][bytes do JPEG]
cabeçalho: {"tipo": "quadro", "seq": 1842, "capturado_em": 1759840000123, "rotacao": 90}
```
`rotacao` é quanto girar no sentido horário para a imagem ficar em pé (no Android, a orientação do sensor). As caixas voltam já "em pé".

**App → API, texto JSON:**
- `{"tipo": "config", "confianca": 0.4, "classes": [0, 67], "imgsz": 640}` → `{"tipo": "config_ok", "parametros": {…}}`
- `{"tipo": "status"}` → `{"tipo": "status", …}` (mesmo conteúdo do `GET /status`)

**API → App:**
```json
{"tipo": "deteccoes", "seq": 1842, "capturado_em": 1759840000123, "largura": 480, "altura": 640,
 "inferencia_ms": 14.2, "processamento_ms": 21.7,
 "deteccoes": [{"classe_id": 0, "classe": "person", "confianca": 0.87,
                "caixa": {"x1": 0.12, "y1": 0.30, "x2": 0.51, "y2": 0.94}}]}
```
- Caixas normalizadas (0–1) sobre a imagem já girada (`largura` × `altura`).
- `capturado_em` volta como foi enviado: o app calcula a latência no próprio relógio, sem sincronizar relógios.
- `{"tipo": "descartado", "seq": 1841}`: chegou um quadro mais novo antes deste ser processado.
- `{"tipo": "erro", "codigo": "IMAGEM_INVALIDA", "mensagem": "…", "seq": 1842}`.

**Códigos de erro:** `CABECALHO_INVALIDO`, `IMAGEM_INVALIDA`, `IMAGEM_GRANDE_DEMAIS` (acima de 4 MB), `PARAMETRO_INVALIDO`, `MENSAGEM_DESCONHECIDA`, `MODELO_INDISPONIVEL` e `ERRO_INTERNO`. No HTTP, os erros vêm como `{"erro": {"codigo", "mensagem"}}`, com status 400, 413, 422, 500 ou 503.

## Controle de fluxo
- **Cliente** (o app e o `cliente_teste.py`): só envia o próximo quadro quando recebe a resposta do anterior (ou depois de 1 s sem resposta), respeitando o FPS configurado.
- **API:** a recepção e a inferência são separadas. Existe um único quadro pendente por conexão; se chegar outro, o antigo é descartado (e avisado). A fila nunca cresce, então a latência não aumenta com o tempo.
- **Inferência:** roda numa thread única fora do loop de eventos (o MPS não aceita inferências concorrentes). Na inicialização, o modelo é aquecido nos formatos de imagem mais comuns.

## Dataset de treino (fase 2)

As fotos para treinar o modelo próprio ficam em `dados/` (fora do Git): um SQLite com classes, fotos e caixas, mais as imagens normalizadas.

```bash
.venv/bin/python baixar_modelo.py yoloe-11l-seg.pt    # modelo que sugere caixas por exemplo visual (71 MB)
.venv/bin/python importar_midia.py --sugerir           # importa midia/<classe>/*.jpg e sugere as caixas
```
- **Pastas:** cada subpasta de `midia/` vira uma classe (`engrenagem`, `pinca_de_freio`). Os nomes que aparecem no app estão em `ROTULOS`, no início do script.
- **Repetidas:** fotos repetidas, mesmo com outro nome, não entram de novo; dá para rodar o script quantas vezes quiser.
- **Divisão:** 80% das fotos vão para treino e 20% para validação, sempre do mesmo jeito para cada foto.
- **Sugestões:** usam o YOLOE com exemplo visual. Para cada classe, até 3 fotos já revisadas servem de modelo ("esta é a peça"). Antes da primeira revisão, valem as caixas-semente marcadas no script.

A revisão é feita no painel (`painel_ia` → Dataset). As rotas ficam em `/dataset/...` (veja `/docs`):

| Rota | O que faz |
| --- | --- |
| `GET /dataset/resumo` | Totais por status, por divisão e por classe |
| `GET/POST /dataset/classes`, `PUT /dataset/classes/{id}` | Classes (nome sem acento + rótulo exibido) |
| `GET /dataset/imagens?status=&classe_id=` | Fotos com as caixas |
| `POST /dataset/imagens` | Envia uma foto (multipart `imagem`, `origem`=painel/app, `classe_id` opcional) |
| `GET /dataset/imagens/{id}/arquivo` e `/miniatura` | A foto e a miniatura |
| `PUT /dataset/imagens/{id}/caixas` | Substitui as caixas; `"status": "revisada"` ao confirmar |
| `PATCH /dataset/imagens/{id}` | Muda `status` (ex.: `descartada`) ou `divisao` |
| `POST /dataset/sugestoes`, `GET /dataset/sugestoes` | Sugere caixas para as fotos sem caixa e mostra o progresso |

**Status de cada foto:** `pendente` (sem caixa), `sugerida` (caixa automática, ainda não conferida), `revisada` (conferida por uma pessoa e pronta para treino) e `descartada` (fora do treino). Uma foto revisada sem caixas entra no treino como exemplo sem peça.

As sugestões rodam na mesma thread da GPU que a detecção ao vivo, foto a foto, e por isso não travam o vídeo.

## Treino e modelos

O treino é iniciado pelo painel (Treinos) e roda num processo separado. A API continua respondendo, mas a detecção ao vivo fica mais lenta enquanto a GPU é dividida.

- **Exportação:** cada treino exporta as fotos revisadas no formato YOLO para `dados/treinos/<id>/dataset/`. O nome de cada classe no modelo é o rótulo ("Pinça de freio"), que aparece direto no app.
- **Base e parada:** o treino parte do `yolo11n.pt` (rápido) ou do `yolo11s.pt` (mais preciso; baixe com `baixar_modelo.py yolo11s.pt`) e para sozinho se as métricas pararem de melhorar.
- **Progresso:** sai a cada época em `dados/treinos/<id>/info.json`, e o registro completo em `treino.log`.
- **Resultado:** o melhor modelo vai para `modelos/tracepro-<id>.pt`, com um `.json` de métricas ao lado.
- **Ativação:** `POST /modelos/{arquivo}/ativar` troca o modelo sem reiniciar e fica salvo em `dados/modelo_ativo.txt`; ao subir de novo, a API usa o mesmo modelo.

| Rota | O que faz |
| --- | --- |
| `GET /treinos` | Treino em andamento, problemas que impedem treinar, dataset e histórico |
| `POST /treinos` | Inicia: `{"base": "yolo11n.pt", "epocas": 80, "imgsz": 640}` |
| `GET /treinos/{id}` | Situação, época atual, métricas por época e fim do registro |
| `POST /treinos/{id}/cancelar` | Cancela |
| `GET /modelos` | Modelos em `modelos/`, com tipo, classes, métricas e qual está em uso |
| `POST /modelos/{arquivo}/ativar` | Passa a detectar com esse modelo (app e painel) |

Como ler as métricas (calculadas nas fotos de validação, que o modelo não vê no treino):
- **mAP50 ("acerto"):** acha a peça certa com a caixa no lugar aproximado. Acima de 80–90% já é bom.
- **mAP50-95:** exige a caixa bem ajustada; costuma ficar abaixo do mAP50.
- **Precisão:** das caixas que o modelo desenhou, quantas estavam certas (poucos alarmes falsos).
- **Revocação:** das peças que estavam nas fotos, quantas ele achou (poucas peças perdidas).

A API e o treino rodam com `YOLO_OFFLINE=1`: o Ultralytics não envia dados de uso nem baixa nada sozinho.

## Testar sem o app

```bash
.venv/bin/python cliente_teste.py                         # foto de exemplo em loop, 8 FPS, 15 s
.venv/bin/python cliente_teste.py --fonte webcam --mostrar   # webcam do Mac com as caixas
.venv/bin/python cliente_teste.py --fonte minhas_fotos/ --fps 10
.venv/bin/python cliente_teste.py --url ws://10.10.10.108:8000/ws/detectar
.venv/bin/python cliente_teste.py --sem-controle --fps 40  # rajada, para ver os descartes
```
O cliente mostra FPS, latência média e p95, tempo de inferência e descartes. No MacBook (M4, MPS), em `localhost`, deu cerca de 31 ms de latência a 8 FPS.

Testes automáticos: `.venv/bin/python -m pytest -q`.

## Estrutura
- `app/config.py`: configuração (variáveis `TRACEPRO_*`)
- `app/protocolo.py`: formato das mensagens e erros padronizados
- `app/detector.py`: carga do YOLO, escolha do dispositivo e inferência numa thread
- `app/main.py`: rotas HTTP, WebSocket e controle de fluxo
- `app/dataset.py`, `app/rotas_dataset.py`, `app/sugestor.py`: dataset de treino, rotas e sugestão de caixas
- `app/treino.py`, `app/treinar.py`, `app/rotas_treino.py`: exportação, processo de treino, catálogo e ativação de modelos
- `cliente_teste.py`, `baixar_modelo.py`, `importar_midia.py`, `tests/`

## Licença do Ultralytics
O Ultralytics YOLO é AGPL-3.0. Para demonstração e uso interno não há problema. Se a API for oferecida como serviço para terceiros (por exemplo, a Montadora), a AGPL exige publicar o código ou contratar a licença Enterprise da Ultralytics.

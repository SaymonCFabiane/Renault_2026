# TracePro · Painel de IA

Painel web para usar e calibrar a API de detecção (`detector_api`) sem o celular. É a base do ciclo de treino da fase 2 (dataset, anotação e treino).

## Rodar

A API precisa estar no ar (veja `detector_api/README.md`):

```bash
cd ~/Documents/GitHub/Test/detector_api && .venv/bin/python -m app
```

Em outro terminal:

```bash
cd ~/Documents/GitHub/Test/painel_ia
npm install
npm run dev
```

Abra http://localhost:5174. A porta é fixa porque a API libera essa origem no CORS.

## Telas
- **Ao vivo:** a webcam do Mac vai para o WebSocket da API, com o mesmo protocolo e o mesmo controle de fluxo do app (um quadro por vez, JPEG 640×480 q70). Mostra as caixas, o FPS, a latência (média, p95 e gráfico com a meta de 300 ms), o tempo de inferência e os descartes. Confiança, tamanho de entrada e classes mudam na hora (mensagem `config`).
- **Teste por imagem:** arraste uma foto para `POST /detectar` e veja as caixas, a tabela de detecções e o JSON da resposta.
- **Status e modelo:** situação da API, dispositivo (MPS/CUDA/CPU), parâmetros padrão, versões e a lista de classes do modelo. É aqui que se troca o endereço da API (salvo neste navegador).

O navegador só libera a webcam em `localhost` ou HTTPS. Por isso, a tela "Ao vivo" funciona com o painel aberto no próprio Mac.

## Comandos
`npm run lint` e `npm run build`.

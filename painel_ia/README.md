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
- **Dataset:** fotos do treino, com as caixas sugeridas. Mostra os totais por classe, permite enviar fotos novas e tem o botão "Sugerir caixas". Em **Revisar**, cada foto abre no editor:
  - arraste sobre a peça para criar uma caixa, arraste a caixa para mover e puxe os cantos para ajustar;
  - `1`, `2`… escolhem a classe (e trocam a da caixa selecionada); `Delete` apaga;
  - `Enter` confirma e vai para a próxima; `←`/`→` navegam salvando o que mudou; `D` descarta a foto; `Esc` volta.
  Caixas tracejadas são sugestões ainda não conferidas.
- **Treinos:** mostra quantas caixas revisadas há por peça, em treino e em validação. Você escolhe o modelo base e as épocas e toca em **Treinar**. O progresso aparece época a época, com gráfico de acerto (mAP50), ajuste da caixa (mAP50-95) e revocação. Embaixo ficam o histórico e a lista de modelos; **Ativar** troca o modelo que o app e o painel usam, sem reiniciar a API.
- **Status e modelo:** situação da API, dispositivo (MPS/CUDA/CPU), parâmetros padrão, versões e a lista de classes do modelo. É aqui que se troca o endereço da API (salvo neste navegador).

O navegador só libera a webcam em `localhost` ou HTTPS. Por isso, a tela "Ao vivo" funciona com o painel aberto no próprio Mac.

## Comandos
`npm run lint` e `npm run build`.

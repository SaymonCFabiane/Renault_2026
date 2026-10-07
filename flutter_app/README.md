# TracePro · App mobile

App dos 3 funcionários do TracePro (demo). É só front-end: dados fictícios fixos e estado em memória. Ao reabrir o app, a demo volta ao início.

## Como rodar

```bash
cd ~/Documents/GitHub/Test/flutter_app
flutter pub get
flutter run -d chrome
```

Também roda num simulador iOS ou Android (`flutter run`). Tamanho de referência: 390×844. No Chrome, use o modo de dispositivo do DevTools para ver no tamanho de celular.

Verificação: `flutter analyze` e `flutter test`. Os testes incluem a varredura das 9 telas nos dois temas e o roteiro completo. Com a API rodando em `localhost:8000`, também incluem a conversa real com o servidor; sem ela, esses dois testes são pulados.

## Câmera com IA (Android)

Os visores de leitura (Carregamento, Recebimento, Coleta, Expedição e Conferência) mostram a câmera traseira e as caixas detectadas pela API Python (`detector_api`), que roda no Mac na mesma rede Wi-Fi. As leituras de QR continuam simuladas pelo botão **Simular leitura**.

### Gerar e instalar o APK
```bash
cd ~/Documents/GitHub/Test/flutter_app
flutter build apk --release --split-per-abi
```
Use `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (serve para quase todos os celulares atuais). Passe o arquivo para o celular, abra-o e permita a instalação de "fontes desconhecidas" quando o Android pedir. Na primeira vez que um visor abrir, permita o uso da câmera.

### Conectar ao servidor
1. No Mac, suba a API (`cd detector_api && .venv/bin/python -m app`). O terminal mostra o endereço, ex.: `10.10.10.108:8000`.
2. No app, toque no avatar → **Servidor de IA** (ou no selo do canto do visor). Informe o IP e a porta, toque em **Testar conexão** e em **Salvar**. O endereço fica salvo no celular.
3. Abra um visor de leitura: o selo mostra `IA · 8 fps · 60 ms` quando está tudo certo.

### Selo do visor
| Selo | O que significa |
| --- | --- |
| `IA · 8 fps · 60 ms` | Conectado; quadros por segundo e latência (captura → caixas de volta) |
| Conectando à IA… / Abrindo câmera… | Aguarde |
| IA desconectada | O servidor não respondeu. A API está rodando? Mesmo Wi-Fi? O firewall do Mac liberou o Python? O app tenta de novo a cada 2 s |
| Configurar IA | Falta o IP do servidor |
| Câmera sem permissão | Libere a câmera em Ajustes → Apps → TracePro |
| IA desligada | Chave "Câmera com IA nos leitores" desligada: visor simulado |

Fora do Android (`flutter run -d chrome`, testes), o visor continua simulado, como antes.

### Como funciona
- **Captura:** quadros NV21 da câmera traseira em 720×480.
- **Compressão:** recorte central 4:3 e JPEG 640×480 com qualidade 70, feitos em Kotlin (`MainActivity.kt`, canal `tracepro/jpeg`).
- **Envio:** WebSocket (`lib/ia/`), com no máximo 1 quadro em trânsito e 5, 8 ou 10 FPS.
- **Rotação:** o app informa a do sensor e a API gira a imagem antes da inferência.
- **Desenho:** as caixas são convertidas para o enquadramento do visor (`ia_mapeamento.dart`).
- **Economia:** a câmera desliga quando nenhum visor está na tela ou quando o app vai para segundo plano.

## Perfis

| Perfil | Módulo | Telas |
| --- | --- | --- |
| Bruno Lima | Fornecedor | Lotes liberados, Registro e etiquetas, Carregamento |
| Marcos Souza | Estoque | Fila de tarefas, Conferência de recebimento, Coleta do KT-0142, Expedição de kit |
| Fernanda Rocha | Testes | Kits esperados, Conferência do kit |

Não há login: a primeira tela é a escolha de perfil. O ícone de setas do header troca de perfil em qualquer tela. Toque no avatar para **Pular para o fim da história**, **Reiniciar demo** ou **Trocar perfil** (as duas primeiras também ficam na tela de perfis). O ícone de lua ou sol alterna o tema.

## Roteiro da demo

1. **Bruno**: **Simular liberação pelo painel web** → **Registrar e imprimir etiquetas** → **Imprimir Etiquetas**. Em Carregamento, toque 3× em **Simular leitura** (8/10, com 1 leitura repetida em vermelho) e em **Enviar para Aprovação do ADM**.
2. **Marcos** · Tarefas: **Simular chegada na doca** → **Conferir recebimento**. Toque em **Simular leitura** até ler as 8 peças (uma leitura é inválida) e em **Concluir recebimento**.
3. **Marcos** · Coleta: siga a rota com **Simular leitura do QR** (o 2º passo tem uma leitura inválida). No Farol LED, toque em **Registrar falta** → **Despachar parcial**. Veja também **Ver exceção: KT-0139** (tela vermelha "Coleta travada").
4. **Marcos** · Expedição: leia a caixa, escolha quem leva e toque em **Confirmar expedição**.
5. **Fernanda**: toque no aviso **KT-0142 chegou**, leia as peças, use **Reportar Peça Danificada/Incompatível** (com foto) e **Dar Aceite e Liberar para Montagem**.

## Estrutura

- `lib/data/mock_data.dart`: dados fictícios e sequências de leitura
- `lib/state/demo_state.dart`: `DemoState` (ChangeNotifier) com o estado inicial, `advance` e as ações; `DemoScope` (InheritedNotifier)
- `lib/theme/tokens.dart`: gerado de `docs/referencia/design-tokens.json`; `app_theme.dart`: temas Material 3 claro e escuro
- `lib/ia/`: câmera, WebSocket, protocolo, configuração do servidor de IA e nomes das classes em português
- `lib/widgets/`: componentes (visor de câmera e QR com CustomPainter, toast, modais, shell com header e navegação inferior)
- `lib/screens/`: telas por módulo
- `assets/fonts/`: Nunito (licença SIL OFL em `OFL.txt`)

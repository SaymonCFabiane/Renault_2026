# TracePro · App mobile

App dos 3 funcionários do TracePro (demo). É só front-end: dados fictícios fixos e estado em memória. Ao reabrir o app, a demo volta ao início.

## Como rodar

```bash
cd ~/Documents/GitHub/Test/flutter_app
flutter pub get
flutter run -d chrome
```

Também roda num simulador iOS ou Android (`flutter run`). Tamanho de referência: 390×844. No Chrome, use o modo de dispositivo do DevTools para ver no tamanho de celular.

Verificação: `flutter analyze` e `flutter test` (inclui a varredura das 9 telas nos dois temas e o roteiro completo).

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
- `lib/widgets/`: componentes (visor de câmera e QR com CustomPainter, toast, modais, shell com header e navegação inferior)
- `lib/screens/`: telas por módulo
- `assets/fonts/`: Nunito (licença SIL OFL em `OFL.txt`)

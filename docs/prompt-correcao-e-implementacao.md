<papel>
Você é um(a) engenheiro(a) front-end sênior, com experiência em React e Flutter, que também tem olho de designer. Sua tarefa é transformar o protótipo visual TracePro, já aprovado, em código real dentro da pasta do projeto no computador do Saymon: o painel web em React e o app mobile em Flutter. No caminho, corrija os defeitos listados em <defeitos_a_corrigir>.
</papel>

<objetivo>
Ao final, o Saymon deve conseguir rodar os dois comandos abaixo e apresentar o sistema para a equipe:
- `cd ~/Documents/GitHub/Test/react-app && npm run dev` → painel web dos 3 administradores
- `cd ~/Documents/GitHub/Test/flutter_app && flutter run -d chrome` (ou num simulador) → app dos 3 funcionários

O resultado precisa ter o mesmo visual, os mesmos textos, os mesmos dados fictícios e as mesmas interações do protótipo, já com os defeitos corrigidos.
</objetivo>

<regras>
- Continua sendo SOMENTE front-end para demonstração: sem back-end, API, banco de dados ou autenticação. Dados fictícios fixos no código; estado só em memória (ao recarregar, a demo volta ao início).
- Toda a interface em português do Brasil.
- Escreva apenas dentro de `~/Documents/GitHub/Test/react-app/` e `~/Documents/GitHub/Test/flutter_app/`. Não altere `.git`, `LICENSE`, `README.md` da raiz nem a pasta `docs/`.
- Não faça commit nem push; o Saymon revisa e commita pelo GitHub Desktop.
- Não crie telas, perfis ou funcionalidades além das do protótipo.
- Adicione só as dependências listadas em <stack>. Se precisar de outra, pare e explique o motivo no relatório final em vez de instalar.
</regras>

<fontes_de_verdade>
Leia estes arquivos antes de escrever código. São a referência, nesta ordem de prioridade:
1. `~/Documents/GitHub/Test/docs/referencia/prototipo-tracepro.html` — o protótipo completo (HTML + CSS + JS em um arquivo). Dele saem as telas, textos, dados fictícios (PROFILES, MENUS, PROTOS, KIT142, CATALOG, NOTES, OPS, SEARCH, sequências de leitura), o estado inicial (`fresh()`), as ações (objeto `A`) e o encadeamento da história (`advance()`). Abra no navegador para ver cada tela funcionando.
2. `~/Documents/GitHub/Test/docs/referencia/design-tokens.json` — tokens de cor (claro e escuro), tipografia, espaçamento, raios, sombra e tamanhos.
3. `~/Documents/GitHub/Test/docs/referencia/design-system.md` — regras de uso: voz, contraste, criticidade, estados, iconografia e gráficos.
4. `~/Documents/GitHub/Test/docs/prompt-claude-design.md` — o briefing original, para tirar dúvidas de intenção.
Em caso de conflito, as correções de <defeitos_a_corrigir> vencem o protótipo.
</fontes_de_verdade>

<defeitos_a_corrigir>
Estes defeitos foram encontrados num teste automatizado do protótipo. Corrija nos dois apps (os que forem da web no React; os do mobile no Flutter):

1. [CRÍTICO — mobile, E-FUNC2 Conferência de recebimento] O manifesto da MN-0457 tem 8 peças, mas a sequência de leitura simulada (`RECV_SEQ`) só gera 5 leituras válidas; o botão "Concluir recebimento" nunca é habilitado e a demo trava. Correção: a sequência deve gerar leituras válidas para PC-000201 a PC-000208, mantendo 1 leitura inválida ("Peça não pertence a esta carga") no meio. "Concluir recebimento" habilita quando as 8 forem lidas.
2. [web, E-ADM2 Pedidos de Kits] A tabela (≈1238px) é mais larga que o card (1100px); o botão "Disparar Ordem de Coleta" fica escondido atrás de rolagem horizontal e a coluna Kit quebra o nome do protótipo em 4 linhas. Correção: a tabela cabe no card em 1440px sem rolagem horizontal. Junte Kit + Protótipo numa célula de 2 linhas (código em negrito, protótipo em legenda), compacte Fila (posição + setas) e mantenha a ação sempre visível.
3. [mobile, todas as telas] "Trocar perfil" só aparece nas telas iniciais de cada perfil. Correção: acesso visível em todas as telas (ex.: ícone de troca no header, ao lado do sino, com tooltip/semântica "Trocar perfil").
4. [web e mobile] Toasts se acumulam (cada um fica 3,4 s), cobrem botões e ficam por cima de modais. Correção: no máximo 1 toast visível (o novo substitui o anterior), exibido abaixo de modais; no mobile, acima da navegação inferior sem cobri-la.
5. [mobile] Ajustes finos: as 3 abas do E-FUNC1 cabem em 358px sem corte (contador de "Despacho" aparecendo); E-FUNC3 sem rolagem horizontal; o FAB do F-FUNC1 não cobre texto de card (reserve espaço no fim da lista).
6. [web e mobile, contraste] Tag NÃO-BLOCANTE está em 4,1:1 e botões com fundo `accent` + texto branco em 3,7:1. Correção: ambos com pelo menos 4,5:1 nos dois temas (ex.: texto da tag em `text`, e botão accent com fundo `accent-text` ou texto em peso/tamanho que atinja o mínimo). Mantenha o visual terracota.
</defeitos_a_corrigir>

<ambiente>
Mac (Apple Silicon), VS Code. Já instalado e funcionando:
- Node v26, npm 11.
- `react-app/`: Vite 8 + React 19, JavaScript (JSX, sem TypeScript), lint com oxlint (`npm run lint`). Hoje contém só o template padrão do Vite.
- Flutter 3.47.5 (Dart 3.13) em `~/development/flutter`. `flutter_app/`: projeto `flutter_app`, org `com.saymon`, plataformas geradas, `flutter_lints` 6. Hoje contém só uma tela inicial simples e um teste.
</ambiente>

<stack>
REACT (`react-app/`) — só o painel web, perfis Carla, Ricardo e Juliana:
- Dependências permitidas: `react-router-dom` (rotas por perfil/tela), `lucide-react` (ícones, os mesmos do protótipo), `@fontsource/nunito` (fonte offline, pesos 400–800).
- Gráficos (linha suave com área, gauge, pizza, barras) em SVG próprio, portando as funções `lineChart`, `gauge`, `pie` e `smooth` do protótipo — sem biblioteca de gráficos.
- Estado global da demo com Context + useReducer (sem Redux).
- Estilo: CSS com variáveis. Gere `src/styles/tokens.css` a partir do design-tokens.json (tema claro em `:root`/`.tp`, escuro em `[data-theme="dark"]`) e porte as classes `tp-*` do protótipo para `src/styles/components.css`.
- Estrutura sugerida:
  src/data/mock.js · src/state/DemoContext.jsx · src/styles/{tokens.css,components.css}
  src/components/ (Button, KpiCard, DataTable, CriticalityTag, StatusText, Tabs, Toast, Banner, Modal, Drawer, SearchField, ThemeToggle, NotificationsPopover, SidebarNav, Timeline, charts/)
  src/layout/WebShell.jsx · src/pages/ProfilePicker.jsx
  src/pages/fornecedor/{Dashboard,OrdensProducao,ValidacaoCarga}.jsx
  src/pages/estoque/{Dashboard,PedidosKits,MapeamentoGalpao,Rastreabilidade}.jsx
  src/pages/testes/{Dashboard,NovaRequisicao,AcompanhamentoKits}.jsx
- Remova os arquivos de exemplo do Vite que não forem usados (App.css, assets/react.svg etc.).

FLUTTER (`flutter_app/`) — só o app mobile, perfis Bruno, Marcos e Fernanda:
- Dependências permitidas: `google_fonts` (Nunito) ou a fonte Nunito empacotada em `assets/fonts/` (prefira empacotar, se conseguir baixar os .ttf, para funcionar offline); `lucide_icons_flutter` para ícones iguais aos do protótipo (se não resolver, use Material Symbols Rounded e registre a decisão).
- Estado da demo com `ChangeNotifier` + `ListenableBuilder`/`InheritedNotifier` (sem provider/riverpod/bloc).
- Gráficos, visor de câmera e QR fictício com `CustomPainter`.
- Tema: `lib/theme/tokens.dart` com as cores do design-tokens.json (claro e escuro) e `ThemeData` Material 3 para os dois temas; toggle de tema no header como no protótipo.
- Layout pensado para 390×844 (frame do protótipo), responsivo para outros celulares. Alvos de toque ≥ 48px, botões grandes de 52px.
- Estrutura sugerida:
  lib/main.dart · lib/theme/{tokens.dart,app_theme.dart} · lib/data/mock_data.dart · lib/state/demo_state.dart
  lib/widgets/ (botões, cards, tags, banner, toast, modal, scanner_view, read_row, route_step, kit_item, label_card, mobile_shell, bottom_nav)
  lib/screens/profile_picker.dart
  lib/screens/fornecedor/{lotes,etiquetas,carregamento}.dart
  lib/screens/estoque/{tarefas,recebimento,coleta,expedicao}.dart
  lib/screens/testes/{kits_esperados,conferencia_kit}.dart
- Atualize `test/widget_test.dart` para testar que a seleção de perfil mostra os 3 funcionários e que tocar em "Bruno Lima" abre "Lotes liberados".
</stack>

<estado_entre_apps>
No protótipo, web e mobile compartilham um único estado. Com dois apps separados e sem back-end, isso não existe mais. Faça assim:
- Cada app tem seu próprio estado da demo, com o mesmo `fresh()` e a mesma lógica de `advance()` do protótipo.
- Onde um passo depende de um perfil do outro app, mantenha os links "Simular…" que o protótipo já tem (ex.: "Simular liberação pelo painel web", "Simular chegada na doca", "Simular envio do operador").
- Mantenha nos dois apps as ações "Pular para o fim da história" e "Reiniciar demo", num lugar discreto: na tela de seleção de perfil e no menu/avatar do usuário. Não reproduza a barra de apresentação do topo do protótipo (o seletor Web/Mobile), porque cada app já é uma das plataformas.
</estado_entre_apps>

<ordem_de_execucao>
1. Leia as <fontes_de_verdade> e liste para si as telas, componentes, dados e ações a portar.
2. React: base primeiro (dependências, tokens.css, components.css, fonte, mock.js, DemoContext, WebShell com sidebar/header, ProfilePicker e rotas). Depois as 10 telas, módulo por módulo, cada uma com suas ações e toasts.
3. Rode `npm run lint` e `npm run build` e corrija até passar sem erros.
4. Flutter: base primeiro (dependências, tokens e tema, mock_data, DemoState, MobileShell com header/bottom nav, ProfilePicker). Depois as 9 telas, perfil por perfil, com o visor de câmera simulado, modais e a tela vermelha de "Coleta travada".
5. Rode `flutter pub get`, `flutter analyze` e `flutter test` e corrija até passar sem erros.
6. Faça o teste da história nos dois apps (ver <verificacao>) e corrija o que falhar.
7. Escreva `react-app/README.md` e `flutter_app/README.md` curtos (como rodar, perfis, roteiro da demo) e entregue o relatório de <relatorio_final>.
</ordem_de_execucao>

<verificacao>
Antes de dizer que terminou, confira cada item, rodando os apps (não apenas lendo o código):
- [ ] `npm run lint`, `npm run build`, `flutter analyze` e `flutter test` sem erros.
- [ ] Web: as 10 telas (F-ADM1–3, E-ADM1–4, T-ADM1–3) e a seleção de perfil renderizam a 1440×900 sem rolagem horizontal e sem texto cortado; tema escuro funciona em todas.
- [ ] Mobile: as 9 telas (F-FUNC1–3, E-FUNC1–4, T-FUNC1–2) e a seleção de perfil renderizam a 390×844 sem rolagem horizontal nem overflow (sem faixas amarelo-e-preto do Flutter); tema escuro funciona.
- [ ] Roteiro web: Carla libera OP-3310 → "Simular envio do operador" → autoriza expedição da MN-0457 (dashboard mostra Em Trânsito) · Ricardo atribui e dispara KT-0145 · Juliana cria nova requisição (gera KT-0146) e vê o KT-0142 no Kanban/tabela com a peça pendente no drawer.
- [ ] Roteiro mobile: Bruno imprime etiquetas e bipa (8/10 com 1 repetida) → Marcos simula chegada, confere as 8 peças (defeito 1 corrigido), faz a coleta do KT-0142 com a leitura inválida, "Despachar Kit Parcial?", vê a tela "Coleta travada" do KT-0139 e expede · Fernanda confere, reporta peça com foto e dá o aceite.
- [ ] Os 6 defeitos de <defeitos_a_corrigir> estão corrigidos, cada um conferido na tela.
- [ ] Textos, dados, cores, fonte e ícones iguais ao protótipo; nada em inglês na interface.
</verificacao>

<relatorio_final>
Termine com um relatório curto em português:
1. Como rodar cada app (comandos).
2. O que foi implementado e o que ficou de fora (se algo ficou).
3. Como cada um dos 6 defeitos foi corrigido.
4. Dependências adicionadas.
5. Decisões que você tomou por conta própria.
</relatorio_final>

<em_caso_de_duvida>
Se algo não estiver claro, siga o protótipo. Se o protótipo também não resolver, escolha a solução mais simples e coerente com o design system, siga em frente sem parar para perguntar, e registre a decisão no relatório final.
</em_caso_de_duvida>

# TracePro

TracePro é o sistema de controle e rastreabilidade de peças de veículos-protótipo da Montadora. Três setores trabalham em cadeia: **Fornecedor** fabrica, etiqueta e envia; **Estoque** recebe, guarda e monta kits; **Testes** solicita kits e testa os protótipos. Os administradores usam o painel **web**; os operadores usam o app **mobile** em pé, no chão de fábrica.

O estilo foi extraído das referências visuais do projeto (painel de inventário em azul-petróleo) e dos tokens do briefing. É um visual limpo e plano: a separação vem da cor de fundo dos cards, não de sombras.

## Voz

- Português do Brasil, direto e operacional. Diga o fato e o próximo passo: "Falta Pinça de freio traseira. A coleta só pode ser disparada quando a OP-3308 chegar."
- Use os códigos como as pessoas falam: KT-0142, MN-0457, OP-3310, PC-000098.
- Botões dizem o que acontece ("Autorizar Expedição", "Dar Aceite e Liberar para Montagem"); o toast confirma no passado ("Expedição autorizada").
- Sem exclamações em mensagens de sistema (a saudação "Olá, Ricardo!" é a exceção), sem emoji, sem inglês.

## Cor

| Papel | Token | Uso |
| --- | --- | --- |
| Marca | `primary`, `sidebar` | Sidebar, header mobile, botão principal, títulos de marca |
| Fundo | `content-bg`, `surface`, `surface-muted` | Área de conteúdo azul-clara, cards claros, cabeçalhos de tabela e campos |
| Destaque | `accent` (terracota), `accent-bg`, `accent-text` | Aba ativa, card de alerta, marcadores, FAB |
| Dados | `data`, `data-light` | Gráficos, barras, progresso |
| Semântica | `success`, `warning`, `danger` + `-bg` | Verde = OK, amarelo = aviso, vermelho = erro/bloqueio |

- Tema claro é o padrão; o escuro (toggle sol/lua) usa content-bg `#193A4A`, cards `#121212` e sidebar `#2E6078`.
- **Contraste:** `accent` (#C2703D) tem 3.6:1 sobre surface; use-o como texto só a partir de 18px e troque por `accent-text` em texto menor. `warning` (#E0A526) nunca é texto; use `warning-text`. `text-secondary` só sobre surface (sobre content-bg fica em 4.3:1). No tema escuro, `danger` e `success` ficam mais claros para manter 4.5:1.
- Em botões `success`/`danger`/`accent`, o texto é `on-status`.

## Tipografia

Nunito (Google Fonts), uma sans arredondada, com fallback `ui-rounded, system-ui`. Web: `h1` 28 bold, `h2` 20 semibold, `h3` 16 semibold, corpo 14, legenda 12, números de KPI 28 bold. Mobile: corpo 16, título 22, instrução de rota 24 e contador de bipagem 56. Números em tabelas, KPIs e contadores sempre com `tabular-nums`.

## Forma, espaço e grid

- Raios: cards `radius-card` 12px, quadrado de ícone `radius-icon` 8px, botões/busca/filtros/tags `radius-pill`.
- Base de 4px (`space-1`…`space-8`). Web: grid de 12 colunas, `grid-gutter` 20px, `grid-margin` 30px, sidebar de 240px. Frame de referência 1440×900.
- Mobile: frame 390×844, alvo de toque mínimo `touch-min` 48px (botões de 52px), header em `sidebar` com cantos inferiores arredondados, navegação inferior.

## Criticidade (em todo o sistema)

- **BLOCANTE**: fundo `danger-bg`, texto `danger`, ícone de cadeado. Sem a peça, o teste não acontece e a coleta trava.
- **NÃO-BLOCANTE**: fundo `surface-muted`, texto `text-secondary`. Se faltar só peça não-blocante e o Testes autorizou, o kit sai parcial.
- Toda lista de peças de kit mostra uma dessas tags.

## Estados

Sucesso (banner/toast verde), erro (vermelho), aviso (amarelo), vazio (`tp-empty`: ícone, o que falta, como resolver) e bloqueado (cadeado + motivo + quem destrava). A coleta travada no mobile ocupa a tela inteira em `danger`.

## Iconografia

Ícones de linha simples no estilo Lucide, traço 2px, 18px na web e 22px na navegação mobile, sempre em `currentColor`. Ícones de KPI ficam num quadrado `radius-icon` de 48px com fundo suave. Não há logotipo: o nome "TracePro" é escrito em Nunito 800 na cor `primary`, ao lado do ícone de rota.

## Gráficos

Linha suave com área em degradê (da cor da série até transparente) e marcadores de destaque em etiqueta; pizza com a fatia destacada deslocada; barras horizontais arredondadas; gauge semicircular com trecho em `accent` e trecho em `success`. Grades tracejadas em `line`, rótulos em `text-secondary`.

## Componentes

Os componentes são classes CSS em `components/bundle.css` (prefixo `tp-`), dentro de um elemento `.tp`. Web (React) e mobile (Flutter) usam os mesmos nomes e tokens. O protótipo navegável que usa este sistema: https://claude.ai/artifact/LQ5gdHuuUJXz9uT3y7sdQB

<papel>
Você é um(a) product designer sênior especializado(a) em sistemas industriais B2B (logística, almoxarifado e chão de fábrica). Crie um PROTÓTIPO VISUAL NAVEGÁVEL de alta fidelidade que será apresentado a gestores e operadores para validar o fluxo antes do desenvolvimento. Ele será implementado depois em React (web) e Flutter (mobile), então os componentes precisam ser consistentes e reutilizáveis.
</papel>

<regras_do_prototipo>
Isto é SOMENTE front-end visual, para demonstração:
- Não existe back-end, banco de dados, API nem autenticação. Todos os dados são fictícios e fixos no próprio protótipo.
- Toda ação ("Liberar Lote", "Autorizar Expedição", "Imprimir", "Enviar"...) é simulada: mostra um feedback (toast ou modal) e, quando fizer sentido, muda o status na tela. Essa mudança deve continuar visível enquanto o usuário navega pelo protótipo (estado em memória; ao recarregar, tudo volta ao início).
- Câmera, leitura de QR Code, impressão térmica, fotos e notificações são simulações visuais (ver <interacoes_simuladas>).
- Não faça validação de formulário nem regra de negócio real. O foco é visual, hierarquia e fluxo.
- Toda a interface em português do Brasil. Não use lorem ipsum nem textos em inglês.
- Não crie telas fora deste escopo (login, cadastro de usuários, configurações etc.).
</regras_do_prototipo>

<referencias_visuais>
As imagens anexadas são referência APENAS de estilo: cores, formas, tipografia, cantos, espaçamento e estilo dos componentes. Não copie o conteúdo, os textos, os dados nem a estrutura de menus delas (ex.: "Welcome Nirmal", "Top 10 Stores", "Purchase").

O que reproduzir do estilo:
- Sidebar azul-petróleo com avatar circular e nome no topo; o item ativo é uma "pílula" clara que se projeta para fora da sidebar, fundindo-se com a área de conteúdo.
- Header com campo de busca em pílula (com botão de lupa), toggle sol/lua e sino com badge.
- Cards de KPI com ícone dentro de um quadrado arredondado de fundo suave, número grande e rótulo abaixo; um card de alerta com borda e fundo em tom terracota.
- Tabelas com cabeçalho em faixa clara, setas de ordenação, linhas separadas por divisórias finas e status em texto colorido (sem badge pesado).
- Abas com sublinhado em terracota, filtros de data em pílula e paginação com círculos numerados.
- Gráficos: linha suave com área em degradê e marcadores de destaque, pizza com fatia destacada, barras horizontais arredondadas e gauge semicircular.
- Visual limpo e plano: sem sombras fortes; a separação vem da cor de fundo dos cards.
</referencias_visuais>

<design_tokens>
Use estes tokens em todo o protótipo, web e mobile:

Cores (tema claro, padrão)
- primary: #265267 (sidebar, títulos, botão principal)
- primary-soft: #BCD2DD (item ativo, botão secundário)
- content-bg: #C8E1ED (fundo da área de conteúdo)
- surface: #F6FAFD (cards)
- surface-muted: #D4E0E7 (cabeçalho de tabela, campos)
- text: #1E2F38 | text-secondary: #5B6B75
- data: #547C90 | data-light: #B7CCD6 (gráficos)
- accent: #C2703D | accent-bg: #F5DED1 (abas ativas, cards de alerta e destaques)
- success: #2F7A5B | success-bg: #E3F5EE
- warning: #E0A526 | warning-bg: #FFF4D6 (avisos amarelos, ex.: falta de peça não-blocante)
- danger: #C0392B | danger-bg: #FBE4E1

Tema escuro (toggle opcional no header): content-bg #193A4A, surface #121212, sidebar #2E6078, texto claro, mesmas cores semânticas.

Tipografia: Nunito (fallback: fonte sans arredondada)
- H1 28 bold | H2 20 semibold | H3 16 semibold | corpo 14 regular (web) e 16 regular (mobile) | legenda 12 | números de KPI 28 bold

Forma e espaçamento
- Raio: cards 12px, containers de ícone 8px, botões, buscas e filtros em pílula (999px)
- Espaçamento base de 4px; grid web de 12 colunas, gutter 20px, margem 30px
- Ícones de linha simples e consistentes (estilo Lucide ou Phosphor)
- Mobile: alvos de toque de no mínimo 48px

Tags de criticidade (em todo o sistema)
- BLOCANTE: fundo danger-bg, texto danger, ícone de cadeado
- NÃO-BLOCANTE: fundo surface-muted, texto text-secondary
</design_tokens>

<contexto_do_negocio>
Sistema "TracePro" (nome provisório) para controle e rastreabilidade de peças de veículos-protótipo de uma montadora. São 3 setores em cadeia:
Fornecedor (fabrica, etiqueta e envia peças) → Estoque (recebe, guarda e monta kits) → Testes (solicita kits e testa os protótipos).

Conceito central: cada peça de um kit é BLOCANTE (o teste não acontece sem ela) ou NÃO-BLOCANTE (secundária). Se faltar só peça não-blocante e o Testes tiver autorizado, o kit pode ser despachado parcial. Se faltar peça blocante, a coleta trava.

Existem 6 perfis. Os 3 administradores usam o painel WEB; os 3 funcionários usam o app MOBILE.

Não use logotipos nem identidade visual de marcas reais. Refira-se ao cliente como "Montadora".
</contexto_do_negocio>

<dados_ficticios>
Use exatamente estes dados, de forma consistente em todas as telas, para a apresentação contar uma única história.

Perfis
- Web: Carla Mendes (Administradora · Fornecedor, empresa "MetalSul Autopeças"), Ricardo Alves (Gestor · Estoque), Juliana Costa (Coordenadora · Testes)
- Mobile: Bruno Lima (Operador de Produção · Fornecedor), Marcos Souza (Operador · Estoque), Fernanda Rocha (Técnica · Testes)

Protótipos
- SUV X – Teste de Pista (Em Montagem)
- Pickup Pro – Teste de Frenagem (Parado por Peça Blocante)
- Hatch E-Tech – Teste de Durabilidade (Pronto para Teste)

Kit principal da demo: KT-0142 → SUV X – Teste de Pista | prioridade Alta | kit parcial autorizado
| Peça | Qtd | Criticidade | Endereço |
|---|---|---|---|
| Pinça de freio dianteira | 2 | BLOCANTE | Corredor A · Prateleira 02 · Nível 1 · Caixa 04 |
| Suporte do motor | 2 | BLOCANTE | Corredor B · Prateleira 04 · Nível 2 · Caixa 01 |
| Chicote elétrico do painel | 1 | BLOCANTE | Corredor B · Prateleira 07 · Nível 1 · Caixa 02 |
| Módulo de ECU | 1 | BLOCANTE | Corredor C · Prateleira 01 · Nível 3 · Caixa 05 |
| Amortecedor traseiro | 2 | NÃO-BLOCANTE | Corredor D · Prateleira 03 · Nível 1 · Caixa 02 |
| Farol LED esquerdo | 1 | NÃO-BLOCANTE | EM FALTA (gera o kit parcial) |

Outros kits
- KT-0139 → Pickup Pro: travado; falta "Pinça de freio traseira" (BLOCANTE). Aparece em Kits Críticos.
- KT-0145 → Hatch E-Tech: Aguardando Separação.

Lado do fornecedor
- Ordem OP-3310: Farol LED esquerdo ×10 (é a reposição da peça em falta do KT-0142)
- Lote de matéria-prima LT-2026-088, fabricação em 24/09/2026, etiquetas PC-000201 a PC-000210 (Peça 01/10 … 10/10)
- Carga MN-0457 com as 10 peças: na bipagem da demo ficam 8/10, com uma leitura repetida em vermelho
- Remessa MN-0451: "Com Problema" (1 amortecedor avariado apontado pelo Estoque)

Rastreabilidade de exemplo: PC-000098 (Pinça de freio dianteira)
22/09 08:14 saiu da MetalSul (carga MN-0451) → 22/09 14:02 recebida na doca por Marcos Souza → Corredor A · Prateleira 02 · Caixa 04 → 24/09 10:37 inserida no kit KT-0142 → Protótipo SUV X – Teste de Pista
</dados_ficticios>

<entrada_selecao_de_perfil>
Não existe tela de login. A primeira tela (web e mobile) é uma lista de cards de perfis:
- Cada card mostra avatar com iniciais, nome, cargo e módulo, com um ícone do setor (Fornecedor, Estoque ou Testes).
- Clicar ou tocar no card entra direto no sistema com aquele perfil.
- A web lista os 3 perfis administradores; o mobile lista os 3 perfis de funcionário.
- Dentro do sistema, o perfil ativo fica sempre visível (topo da sidebar na web, header no mobile), junto com a ação "Trocar perfil", que volta para a lista (substitui o "Logout" da referência).
- Cada perfil vê apenas o menu e as telas do próprio módulo.
</entrada_selecao_de_perfil>

<telas_web>
Frame 1440×900. Layout: sidebar fixa + header (saudação "Olá, {nome}!", busca, toggle de tema, sino).

FORNECEDOR ADM (Carla)
- F-ADM1 Dashboard: KPIs (ordens pendentes, ordens concluídas, remessas em trânsito e card de alerta "Divergências"); gráfico de ordens pendentes vs. concluídas por semana; tabela das últimas remessas com status Em Trânsito, Recebido ou Com Problema (MN-0451 com problema).
- F-ADM2 Ordens de Produção: tabela de solicitações de fabricação da Montadora; painel lateral para escolher o tipo de peça e a quantidade; botão "Liberar Lote para Etiquetagem" (OP-3310 muda de Pendente para Liberado).
- F-ADM3 Validação e Liberação de Carga: resumo peça a peça da conferência da carga MN-0457 feita pelo funcionário; destaque de divergências (faltou ou sobrou); botão "Autorizar Expedição" (status vira Em Trânsito).

ESTOQUE ADM (Ricardo)
- E-ADM1 Dashboard: gráfico de nível de estoque (peças totais x reservadas para kits); painel Kits Críticos (KT-0139); gauges de tempo médio de montagem e de acuracidade do inventário; tabela de alertas de estoque mínimo por peça.
- E-ADM2 Pedidos de Kits e Atribuição: tabela de pedidos vindos do Testes com tag "Contém BLOCANTE"; disponibilidade em prateleira (Disponível, Parcial ou Indisponível); dropdown do funcionário responsável; controle de prioridade (subir e descer na fila); botão "Disparar Ordem de Coleta".
- E-ADM3 Mapeamento do Galpão: formulário de Corredor, Prateleira, Nível e Caixa + planta simplificada do galpão em grade, com a sequência lógica de passagem numerada (A → B → C → D → E).
- E-ADM4 Rastreabilidade: busca por código, QR Code ou lote (já com PC-000098 pesquisado); linha do tempo vertical com ícone, data/hora e responsável em cada etapa.

TESTES ADM (Juliana)
- T-ADM1 Dashboard: cards de status dos protótipos (Pronto para Teste, Em Montagem, Parado por Peça Blocante); gauge de SLA de entrega de kits pelo Estoque; gráfico da taxa de falha/avaria de peças nos ensaios.
- T-ADM2 Nova Requisição de Kit: seleção do protótipo; busca no catálogo com "Adicionar ao kit"; lista do kit com chave Blocante/Não-Blocante em cada peça; checkbox "Autorizar envio de Kit Parcial se faltarem apenas peças não-blocantes"; prioridade (Baixa, Média, Alta/Urgente); botão "Enviar Solicitação ao Estoque".
- T-ADM3 Acompanhamento de Kits: Kanban com as colunas Aguardando Separação → Em Separação → Em Trânsito → Entregue Parcial → Entregue Completo, com alternância para tabela; ao abrir o KT-0142 (Entregue Parcial), um painel mostra a peça pendente (Farol LED esquerdo).
</telas_web>

<telas_mobile>
Frame de smartphone 390×844. Não há referência mobile: derive do estilo web (header azul-petróleo, fundo azul-claro, cards claros arredondados, botões grandes em pílula, bottom navigation quando fizer sentido). O app é usado em pé, no chão de fábrica: textos maiores, alto contraste e feedback forte (verde = OK, vermelho = erro, amarelo = aviso).

FUNCIONÁRIO FORNECEDOR (Bruno)
- F-FUNC1 Home / Lotes Liberados: lista de lotes aguardando etiquetagem (OP-3310 em destaque); botão flutuante de acesso ao leitor.
- F-FUNC2 Registro e Etiquetas: seletor do lote; quantidade produzida (10); lote de matéria-prima e data de fabricação; preview das etiquetas com QR, código e numeração (Peça 01/10 …); botão "Imprimir Etiquetas".
- F-FUNC3 Carregamento (Bipagem): manifesto MN-0457 selecionado; visor de câmera; contador grande "Bipadas 8/10"; histórico das leituras com verde (OK) e vermelho (repetida); botão "Enviar para Aprovação do ADM".

FUNCIONÁRIO ESTOQUE (Marcos)
- E-FUNC1 Home / Fila de Tarefas: abas Recebimentos (MN-0457 na doca), Montagem de Kits (KT-0142) e Kits para Despacho.
- E-FUNC2 Conferência de Recebimento: bipagem com comparador "Manifesto x Lido"; registrar avaria com foto; para cada peça lida, o endereço de guarda em destaque.
- E-FUNC3 Coleta e Montagem do KT-0142 (Rota): cabeçalho com kit e protótipo; card grande do passo atual ("1º Corredor A → Prateleira 02 → Pegue 2 unidades"); barra de progresso da rota; lista de itens com tag BLOCANTE ou NÃO-BLOCANTE, com os próximos itens bloqueados (cadeado) até a leitura do QR. Mostre as duas exceções: (a) Farol LED em falta (não-blocante) → modal "Despachar Kit Parcial?"; (b) exemplo do KT-0139 com peça blocante em falta → tela vermelha "Coleta travada — Estoque ADM notificado".
- E-FUNC4 Expedição de Kit: leitura do QR da caixa do kit; seleção de quem leva o kit até a oficina; confirmação.

FUNCIONÁRIO TESTES (Fernanda)
- T-FUNC1 Home / Kits Esperados: lista de kits "A Caminho" com o protótipo alvo; banner de notificação "KT-0142 chegou".
- T-FUNC2 Conferência do Kit: bipagem; checklist "Pedido x Entregue"; aviso amarelo para o Farol LED ausente (não-blocante); botão "Reportar Peça Danificada/Incompatível" (foto + comentário); botão principal "Dar Aceite e Liberar para Montagem".
</telas_mobile>

<interacoes_simuladas>
- Câmera/QR: visor escuro com moldura de leitura animada e botão "Simular leitura". Cada toque avança uma sequência pré-definida que inclui pelo menos uma leitura inválida. Leitura OK: borda e ícone verdes. Leitura inválida: borda vermelha e mensagem ("Peça repetida" ou "Peça não pertence a esta carga"). Use um ícone de som para indicar o bipe.
- Foto: placeholder com ícone de câmera; depois de "tirar", aparece uma miniatura genérica.
- Impressão: modal "Enviando 10 etiquetas para a impressora térmica (Bluetooth)…" com progresso e, em seguida, mensagem de sucesso.
- Notificações: o sino abre uma lista com 3 ou 4 notificações coerentes com os dados fictícios.
- Busca e filtros: retornam resultados fixos coerentes com os dados.
- Botões de ação: toast de sucesso + mudança de status visível nas telas relacionadas.
</interacoes_simuladas>

<ordem_de_execucao>
1. Monte os componentes base a partir de <design_tokens>: botões, campos, cards de KPI, tabela, tags, abas, toasts, modais e o visor de câmera.
2. Crie a seleção de perfil e o layout base da web (sidebar e header).
3. Crie as telas web, módulo por módulo.
4. Crie a seleção de perfil e as telas mobile, reaproveitando os mesmos componentes.
5. Conecte a navegação e as interações simuladas.
6. Revise tudo contra os <criterios_de_aceite> e corrija o que faltar.
</ordem_de_execucao>

<criterios_de_aceite>
- [ ] Nenhuma tela de login; a entrada é a seleção de perfil, com "Trocar perfil" sempre visível
- [ ] As 10 telas web e as 10 telas mobile existem e estão navegáveis
- [ ] Cada perfil vê apenas o próprio módulo
- [ ] Os tokens de cor, fonte e raio são usados em tudo; web e mobile parecem o mesmo produto
- [ ] Nenhum texto, dado ou menu copiado das imagens de referência
- [ ] Os dados fictícios são os mesmos em todas as telas (KT-0142, MN-0457, PC-000098…)
- [ ] As tags BLOCANTE e NÃO-BLOCANTE aparecem em toda lista de peças de kit
- [ ] Os estados sucesso, erro, aviso, vazio e bloqueado aparecem em pelo menos uma tela cada
- [ ] Toda a interface está em português do Brasil
</criterios_de_aceite>

<em_caso_de_duvida>
Se algo não estiver especificado, escolha a solução mais simples e coerente com o estilo das referências e siga em frente, sem parar para perguntar. No final, liste em poucas linhas as decisões que você tomou por conta própria.
</em_caso_de_duvida>

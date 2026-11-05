# TracePro · Painel web

Painel dos 3 administradores do TracePro (demo). É só front-end: dados fictícios fixos e estado em memória. Ao recarregar a página, a demo volta ao início.

## Como rodar

```bash
cd ~/Documents/GitHub/Test/react-app
npm install
npm run dev
```

Abra o endereço que o Vite mostrar (normalmente http://localhost:5173). Tamanho de referência: 1440×900.

Outros comandos: `npm run lint` e `npm run build`.

## Perfis

| Perfil | Módulo | Telas |
| --- | --- | --- |
| Carla Mendes | Fornecedor | Painel, Ordens de Produção, Validação de Carga |
| Ricardo Alves | Estoque | Painel, Pedidos de Kits, Bloqueios de Qualidade, Mapeamento do Galpão, Rastreabilidade, Visão dos Setores, Acessos e Permissões |
| Juliana Costa | Cliente | Painel, Nova Requisição, Acompanhamento de Kits |

Não há login: a primeira tela é a escolha de perfil. "Trocar perfil" fica no rodapé da sidebar. Clique no avatar da sidebar para **Pular para o fim da história** ou **Reiniciar demo** (as duas ações também ficam na tela de perfis). O tema escuro é o botão sol/lua do header.

## Roteiro da demo

1. **Carla** · Ordens de Produção: com a OP-3310 selecionada, clique em **Liberar Lote para Etiquetagem**.
2. **Carla** · Validação de Carga: clique em **Simular envio do operador** (8 de 10 peças, 1 leitura repetida) e em **Autorizar Expedição**. O Painel passa a mostrar a MN-0457 Em Trânsito.
3. **Ricardo** · Pedidos de Kits: escolha o responsável do KT-0145 e clique em **Disparar Ordem de Coleta**. Use as setas da coluna Fila para mudar a prioridade.
4. **Ricardo** · Bloqueios de Qualidade: a remessa MN-0449 chegou com 50 suportes do motor e 20 foram reprovados na inspeção (ficam bloqueados na quarentena, Zona Q, fora dos kits). Selecione peças e escolha **Descartar**, **Devolver ao fornecedor** (gera uma devolução DV-xxxx) ou **Liberar após reinspeção**. Ao descartar ou devolver, dá para pedir reposição: vira uma ordem de produção nova para a Carla. Quando a MN-0457 é recebida, entram mais 2 faróis bloqueados (PC-000203 e PC-000206).
5. **Ricardo** · Mapeamento do Galpão: endereçamento logístico no padrão **Zona-Corredor-Módulo-Nível-Posição** (ex.: `A-07-16-02-03`). Zona A (armazenagem: 10 corredores × 20 módulos × 4 níveis × 4 posições) e Zona Q (quarentena da qualidade). Escolha a peça, monte o endereço no gerador ou clicando na planta e nas posições do módulo, e salve (não deixa ocupar uma posição de outra peça). A página também tem a ficha de localização (produto, PN, quantidade, endereço), o botão **Copiar**, a prévia da etiqueta QR 50×30 mm da posição e a legenda do código.
6. **Ricardo** · Rastreabilidade: PC-000098 já vem pesquisado. Teste também PC-000205, uma peça reprovada (PC-000305), a remessa MN-0449 e o lote LT-2026-088. A linha do tempo mostra recebimento, reprovação, quarentena, destino e reposição.
7. **Juliana** · Nova Requisição: adicione peças e clique em **Enviar Solicitação ao Estoque** (gera o KT-0146).
8. **Juliana** · Acompanhamento de Kits: abra o KT-0142 no Kanban ou na Tabela. O painel lateral mostra a peça pendente (Farol LED esquerdo).
9. **Ricardo** · Visão dos Setores: consulta as telas da Carla (Painel, Ordens, Validação de Carga) e da Juliana (Painel, Acompanhamento de Kits) em modo **somente leitura**: os botões de ação ficam desabilitados e cada consulta entra no registro de atividades.
10. **Ricardo** · Acessos e Permissões: matriz de quem acessa o quê, princípios de governança/LGPD e o registro de atividades (liberações, decisões de qualidade, pedidos e consultas, com data e responsável).
11. **Carla** · Painel e Ordens de Produção: aparecem as reprovações da qualidade, as devoluções e as ordens de reposição pedidas pelo Estoque.

Os passos que dependem do app mobile (bipagem do Bruno etc.) aparecem aqui como links **Simular…**, porque os dois apps não compartilham estado.

## Estrutura

- `src/data/mock.js`: dados fictícios (perfis, kits, ordens, notificações, sequências de leitura)
- `src/state/logic.js`: estado inicial (`fresh`), `advance` e ações da demo; `DemoContext.jsx` usa Context + useReducer
- `src/styles/tokens.css`: gerado de `docs/referencia/design-tokens.json` (claro e escuro); `components.css`: classes `tp-*`
- `src/components/`: componentes e gráficos em SVG próprio (`charts/`)
- `src/layout/WebShell.jsx` e `src/pages/`: telas por módulo

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
| Ricardo Alves | Estoque | Painel, Pedidos de Kits, Mapeamento do Galpão, Rastreabilidade |
| Juliana Costa | Testes | Painel, Nova Requisição, Acompanhamento de Kits |

Não há login: a primeira tela é a escolha de perfil. "Trocar perfil" fica no rodapé da sidebar. Clique no avatar da sidebar para **Pular para o fim da história** ou **Reiniciar demo** (as duas ações também ficam na tela de perfis). O tema escuro é o botão sol/lua do header.

## Roteiro da demo

1. **Carla** · Ordens de Produção: com a OP-3310 selecionada, clique em **Liberar Lote para Etiquetagem**.
2. **Carla** · Validação de Carga: clique em **Simular envio do operador** (8 de 10 peças, 1 leitura repetida) e em **Autorizar Expedição**. O Painel passa a mostrar a MN-0457 Em Trânsito.
3. **Ricardo** · Pedidos de Kits: escolha o responsável do KT-0145 e clique em **Disparar Ordem de Coleta**. Use as setas da coluna Fila para mudar a prioridade.
4. **Ricardo** · Rastreabilidade: PC-000098 já vem pesquisado. Teste também PC-000205 e o lote LT-2026-088.
5. **Juliana** · Nova Requisição: adicione peças e clique em **Enviar Solicitação ao Estoque** (gera o KT-0146).
6. **Juliana** · Acompanhamento de Kits: abra o KT-0142 no Kanban ou na Tabela. O painel lateral mostra a peça pendente (Farol LED esquerdo).

Os passos que dependem do app mobile (bipagem do Bruno etc.) aparecem aqui como links **Simular…**, porque os dois apps não compartilham estado.

## Estrutura

- `src/data/mock.js`: dados fictícios (perfis, kits, ordens, notificações, sequências de leitura)
- `src/state/logic.js`: estado inicial (`fresh`), `advance` e ações da demo; `DemoContext.jsx` usa Context + useReducer
- `src/styles/tokens.css`: gerado de `docs/referencia/design-tokens.json` (claro e escuro); `components.css`: classes `tp-*`
- `src/components/`: componentes e gráficos em SVG próprio (`charts/`)
- `src/layout/WebShell.jsx` e `src/pages/`: telas por módulo

// Dados fictícios fixos da demo, portados do protótipo (docs/referencia/prototipo-tracepro.html).

export const PROFILES = {
  carla: { id: 'carla', name: 'Carla Mendes', ini: 'CM', role: 'Administradora', mod: 'Fornecedor', org: 'MetalSul Autopeças', icon: 'factory', first: 'Carla', base: '/fornecedor' },
  ricardo: { id: 'ricardo', name: 'Ricardo Alves', ini: 'RA', role: 'Gestor', mod: 'Estoque', org: 'Montadora · Almoxarifado', icon: 'warehouse', first: 'Ricardo', base: '/estoque' },
  juliana: { id: 'juliana', name: 'Juliana Costa', ini: 'JC', role: 'Coordenadora', mod: 'Testes', org: 'Montadora · Engenharia de Testes', icon: 'flask-conical', first: 'Juliana', base: '/testes' },
};

// [código da tela, rótulo do menu, ícone, caminho]
export const MENUS = {
  carla: [
    ['F-ADM1', 'Painel', 'layout-dashboard', '/fornecedor/painel'],
    ['F-ADM2', 'Ordens de Produção', 'clipboard-list', '/fornecedor/ordens'],
    ['F-ADM3', 'Validação de Carga', 'truck', '/fornecedor/validacao'],
  ],
  ricardo: [
    ['E-ADM1', 'Painel', 'layout-dashboard', '/estoque/painel'],
    ['E-ADM2', 'Pedidos de Kits', 'boxes', '/estoque/pedidos'],
    ['E-ADM3', 'Mapeamento do Galpão', 'map-pin', '/estoque/galpao'],
    ['E-ADM4', 'Rastreabilidade', 'history', '/estoque/rastreabilidade'],
  ],
  juliana: [
    ['T-ADM1', 'Painel', 'layout-dashboard', '/testes/painel'],
    ['T-ADM2', 'Nova Requisição', 'plus', '/testes/requisicao'],
    ['T-ADM3', 'Acompanhamento de Kits', 'square-kanban', '/testes/acompanhamento'],
  ],
};

export const PATHS = Object.fromEntries(Object.values(MENUS).flat().map(([code, , , path]) => [code, path]));

export const PROTOS = {
  suv: { name: 'SUV X – Teste de Pista', status: 'Em Montagem' },
  pickup: { name: 'Pickup Pro – Teste de Frenagem', status: 'Parado por Peça Blocante' },
  hatch: { name: 'Hatch E-Tech – Teste de Durabilidade', status: 'Pronto para Teste' },
};

export const KIT142 = [
  { p: 'Pinça de freio dianteira', q: 2, b: true, addr: 'Corredor A · Prateleira 02 · Nível 1 · Caixa 04', c: 'A', s: 2, code: 'PC-000098' },
  { p: 'Suporte do motor', q: 2, b: true, addr: 'Corredor B · Prateleira 04 · Nível 2 · Caixa 01', c: 'B', s: 4, code: 'PC-000121' },
  { p: 'Chicote elétrico do painel', q: 1, b: true, addr: 'Corredor B · Prateleira 07 · Nível 1 · Caixa 02', c: 'B', s: 7, code: 'PC-000133' },
  { p: 'Módulo de ECU', q: 1, b: true, addr: 'Corredor C · Prateleira 01 · Nível 3 · Caixa 05', c: 'C', s: 1, code: 'PC-000150' },
  { p: 'Amortecedor traseiro', q: 2, b: false, addr: 'Corredor D · Prateleira 03 · Nível 1 · Caixa 02', c: 'D', s: 3, code: 'PC-000164' },
  { p: 'Farol LED esquerdo', q: 1, b: false, addr: null, c: null, s: null, code: null, missing: true },
];

// [nome, PN, blocante por padrão]
export const CATALOG = [
  ['Pinça de freio dianteira', 'PN 44-1021', true], ['Pinça de freio traseira', 'PN 44-1022', true], ['Disco de freio ventilado', 'PN 44-2040', true],
  ['Suporte do motor', 'PN 21-0310', true], ['Módulo de ECU', 'PN 70-0001', true], ['Chicote elétrico do painel', 'PN 63-1180', true],
  ['Amortecedor traseiro', 'PN 32-0712', false], ['Farol LED esquerdo', 'PN 81-0450', false], ['Farol LED direito', 'PN 81-0451', false], ['Sensor de estacionamento', 'PN 66-0099', false],
];

// [ícone, tom, texto, quando]
export const NOTES = {
  carla: [
    ['triangle-alert', 'accent', 'MN-0451 com problema: 1 amortecedor avariado apontado pelo Estoque.', '22/09 · 15:10'],
    ['clipboard-list', 'data', 'Nova ordem OP-3310: Farol LED esquerdo ×10 (reposição do KT-0142).', '24/09 · 11:02'],
    ['scan-barcode', 'data', 'Bruno Lima está conferindo a carga MN-0457.', '25/09 · 16:20'],
  ],
  ricardo: [
    ['lock', 'danger', 'KT-0139 travado: falta Pinça de freio traseira (BLOCANTE).', '25/09 · 09:41'],
    ['package', 'data', 'Carga MN-0457 prevista na doca hoje às 17:30.', '25/09 · 16:50'],
    ['boxes', 'data', 'Juliana Costa solicitou o kit KT-0145 (Hatch E-Tech).', '25/09 · 10:05'],
    ['triangle-alert', 'warning', 'Farol LED esquerdo abaixo do estoque mínimo (0 de 2).', '24/09 · 10:37'],
  ],
  juliana: [
    ['circle-alert', 'warning', 'KT-0142 será entregue parcial: Farol LED esquerdo em falta.', '24/09 · 10:40'],
    ['lock', 'danger', 'Pickup Pro parado: KT-0139 aguarda Pinça de freio traseira.', '25/09 · 09:41'],
    ['circle-check', 'success', 'Hatch E-Tech pronto para o Teste de Durabilidade.', '25/09 · 08:15'],
  ],
};

export const OPS = [
  { id: 'OP-3310', part: 'Farol LED esquerdo', q: 10, req: '24/09', due: '26/09', why: 'Reposição do KT-0142' },
  { id: 'OP-3308', part: 'Pinça de freio traseira', q: 4, req: '25/09', due: '27/09', why: 'Destrava o KT-0139' },
  { id: 'OP-3306', part: 'Amortecedor traseiro', q: 6, req: '23/09', due: '25/09', why: 'Reposição da avaria na MN-0451' },
  { id: 'OP-3302', part: 'Suporte do motor', q: 8, req: '20/09', due: '22/09', why: 'Estoque de segurança' },
  { id: 'OP-3299', part: 'Chicote elétrico do painel', q: 5, req: '18/09', due: '21/09', why: 'Estoque de segurança' },
];

// Itens: [nome, qtd, blocante, 'miss' se em falta]
export const KITDEF = {
  'KT-0139': { prio: 'Alta', items: [['Pinça de freio traseira', 2, true, 'miss'], ['Disco de freio ventilado', 2, true], ['Sensor de estacionamento', 1, false]] },
  'KT-0145': { prio: 'Média', items: [['Módulo de ECU', 1, true], ['Amortecedor traseiro', 4, false], ['Sensor de estacionamento', 2, false]] },
  'KT-0138': { prio: 'Baixa', items: [['Chicote elétrico do painel', 1, true], ['Farol LED direito', 1, false]] },
  'KT-0136': { prio: 'Média', items: [['Pinça de freio dianteira', 2, true], ['Disco de freio ventilado', 2, true]] },
};

export const KIT_PROTO = {
  'KT-0142': PROTOS.suv.name, 'KT-0139': PROTOS.pickup.name, 'KT-0145': PROTOS.hatch.name, 'KT-0138': PROTOS.hatch.name, 'KT-0136': PROTOS.suv.name,
};

export const KANBAN_COLS = ['Aguardando Separação', 'Em Separação', 'Em Trânsito', 'Entregue Parcial', 'Entregue Completo'];

// [código, descrição, perfil, tela]
export const SEARCH = [
  ['OP-3310', 'Ordem · Farol LED esquerdo ×10', 'carla', 'F-ADM2'], ['OP-3308', 'Ordem · Pinça de freio traseira ×4', 'carla', 'F-ADM2'],
  ['MN-0457', 'Carga · conferência de 10 peças', 'carla', 'F-ADM3'], ['MN-0451', 'Remessa com problema', 'carla', 'F-ADM1'],
  ['KT-0142', 'Kit · SUV X – Teste de Pista', 'ricardo', 'E-ADM2'], ['KT-0139', 'Kit travado · Pickup Pro', 'ricardo', 'E-ADM2'],
  ['KT-0145', 'Kit · Hatch E-Tech', 'ricardo', 'E-ADM2'], ['PC-000098', 'Pinça de freio dianteira · rastrear', 'ricardo', 'E-ADM4'],
  ['LT-2026-088', 'Lote de matéria-prima · rastrear', 'ricardo', 'E-ADM4'],
  ['KT-0142', 'Kit · SUV X – Teste de Pista', 'juliana', 'T-ADM3'], ['KT-0139', 'Kit travado · Pickup Pro', 'juliana', 'T-ADM3'],
  ['KT-0145', 'Kit · Hatch E-Tech', 'juliana', 'T-ADM3'],
];

// Sequências de leitura simuladas (mesma história do app mobile).
export const LOAD_SEQ = [{ c: 'PC-000207', ok: true }, { c: 'PC-000207', ok: false, msg: 'Peça repetida' }, { c: 'PC-000208', ok: true }];
// Defeito 1 corrigido: 8 leituras válidas (PC-000201 a PC-000208) com 1 inválida no meio.
export const RECV_SEQ = [
  { c: 'PC-000201', ok: true }, { c: 'PC-000202', ok: true }, { c: 'PC-000203', ok: true }, { c: 'PC-000204', ok: true },
  { c: 'PC-000315', ok: false, msg: 'Peça não pertence a esta carga' },
  { c: 'PC-000205', ok: true }, { c: 'PC-000206', ok: true }, { c: 'PC-000207', ok: true }, { c: 'PC-000208', ok: true },
];
export const ACC_SEQ = [{ i: 0, ok: true }, { i: 1, ok: true }, { i: 1, ok: false, msg: 'Peça repetida' }, { i: 2, ok: true }, { i: 3, ok: true }, { i: 4, ok: true }];
export const GUARD = 'Corredor D · Prateleira 05 · Nível 2 · Caixa 03';

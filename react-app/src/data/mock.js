// Dados fictícios fixos da demo, portados do protótipo (docs/referencia/prototipo-tracepro.html).

export const PROFILES = {
  carla: { id: 'carla', name: 'Carla Mendes', ini: 'CM', role: 'Administradora', mod: 'Fornecedor', org: 'MetalSul Autopeças', icon: 'factory', first: 'Carla', base: '/fornecedor' },
  ricardo: { id: 'ricardo', name: 'Ricardo Alves', ini: 'RA', role: 'Gestor', mod: 'Estoque', org: 'Montadora · Almoxarifado', icon: 'warehouse', first: 'Ricardo', base: '/estoque' },
  juliana: { id: 'juliana', name: 'Juliana Costa', ini: 'JC', role: 'Coordenadora', mod: 'Cliente', org: 'Montadora · Engenharia de Testes', icon: 'flask-conical', first: 'Juliana', base: '/cliente' },
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
    ['E-ADM5', 'Bloqueios de Qualidade', 'shield-alert', '/estoque/qualidade'],
    ['E-ADM3', 'Mapeamento do Galpão', 'map-pin', '/estoque/galpao'],
    ['E-ADM4', 'Rastreabilidade', 'history', '/estoque/rastreabilidade'],
    ['E-ADM6', 'Visão dos Setores', 'eye', '/estoque/setores'],
    ['E-ADM7', 'Acessos e Permissões', 'key-round', '/estoque/acessos'],
  ],
  juliana: [
    ['T-ADM1', 'Painel', 'layout-dashboard', '/cliente/painel'],
    ['T-ADM2', 'Nova Requisição', 'plus', '/cliente/requisicao'],
    ['T-ADM3', 'Acompanhamento de Kits', 'square-kanban', '/cliente/acompanhamento'],
  ],
};

export const PATHS = Object.fromEntries(Object.values(MENUS).flat().map(([code, , , path]) => [code, path]));

export const PROTOS = {
  suv: { name: 'SUV X – Teste de Pista', status: 'Em Montagem' },
  pickup: { name: 'Pickup Pro – Teste de Frenagem', status: 'Parado por Peça Blocante' },
  hatch: { name: 'Hatch E-Tech – Teste de Durabilidade', status: 'Pronto para Teste' },
};

export const KIT142 = [
  { p: 'Pinça de freio dianteira', q: 2, b: true, end: 'A-01-04-01-04', code: 'PC-000098' },
  { p: 'Suporte do motor', q: 2, b: true, end: 'A-03-08-02-01', code: 'PC-000121' },
  { p: 'Chicote elétrico do painel', q: 1, b: true, end: 'A-03-15-01-02', code: 'PC-000133' },
  { p: 'Módulo de ECU', q: 1, b: true, end: 'A-05-02-03-03', code: 'PC-000150' },
  { p: 'Amortecedor traseiro', q: 2, b: false, end: 'A-07-11-01-02', code: 'PC-000164' },
  { p: 'Farol LED esquerdo', q: 1, b: false, end: null, code: null, missing: true },
];

// [nome, PN, blocante por padrão]
export const CATALOG = [
  ['Pinça de freio dianteira', 'PN 44-1021', true], ['Pinça de freio traseira', 'PN 44-1022', true], ['Disco de freio ventilado', 'PN 44-2040', true],
  ['Suporte do motor', 'PN 21-0310', true], ['Módulo de ECU', 'PN 70-0001', true], ['Chicote elétrico do painel', 'PN 63-1180', true],
  ['Amortecedor traseiro', 'PN 32-0712', false], ['Farol LED esquerdo', 'PN 81-0450', false], ['Farol LED direito', 'PN 81-0451', false], ['Sensor de estacionamento', 'PN 66-0099', false], ['Engrenagem', 'PN 27-0405', true],
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
  'KT-0139': { prio: 'Alta', partial: false, items: [['Pinça de freio traseira', 2, true, 'miss'], ['Disco de freio ventilado', 2, true], ['Sensor de estacionamento', 1, false]] },
  'KT-0145': { prio: 'Média', items: [['Módulo de ECU', 1, true], ['Amortecedor traseiro', 4, false], ['Sensor de estacionamento', 2, false], ['Engrenagem', 1, true], ['Pinça de freio dianteira', 2, true]] },
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
  ['MN-0449', 'Suporte do motor · 20 peças bloqueadas pela qualidade', 'ricardo', 'E-ADM5'],
  ['PC-000305', 'Suporte do motor reprovado · rastrear', 'ricardo', 'E-ADM4'],
  ['MN-0449', 'Suporte do motor · 20 reprovadas na inspeção do Estoque', 'carla', 'F-ADM1'],
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
/* ===== Endereçamento logístico: Zona-Corredor-Módulo-Nível-Posição (ex.: A-03-12-02-01) ===== */
export const GALPAO = {
  A: { nome: 'Armazenagem', corredores: 10, modulos: 20, niveis: 4, posicoes: 4 },
  Q: { nome: 'Quarentena da qualidade', corredores: 1, modulos: 6, niveis: 4, posicoes: 4 },
};
// Onde cada peça do catálogo está guardada e quanto há em estoque disponível.
export const ENDERECOS = {
  'Pinça de freio dianteira': 'A-01-04-01-04', 'Pinça de freio traseira': 'A-01-05-02-01', 'Disco de freio ventilado': 'A-02-10-01-01',
  'Suporte do motor': 'A-03-08-02-01', 'Módulo de ECU': 'A-05-02-03-03', 'Chicote elétrico do painel': 'A-03-15-01-02',
  'Amortecedor traseiro': 'A-07-11-01-02', 'Farol LED esquerdo': 'A-07-16-02-03', 'Farol LED direito': 'A-07-16-02-04', 'Sensor de estacionamento': 'A-09-03-02-02', 'Engrenagem': 'A-04-09-01-02',
};
export const SALDO = {
  'Pinça de freio dianteira': 12, 'Pinça de freio traseira': 0, 'Disco de freio ventilado': 16, 'Suporte do motor': 30, 'Módulo de ECU': 3,
  'Chicote elétrico do painel': 5, 'Amortecedor traseiro': 8, 'Farol LED esquerdo': 0, 'Farol LED direito': 4, 'Sensor de estacionamento': 10, 'Engrenagem': 6,
};
export const GUARD = ENDERECOS['Farol LED esquerdo'];

/* ===== Qualidade: inspeção no recebimento e bloqueio de estoque ===== */
export const QUARENTENA = 'Zona Q · Quarentena da qualidade';
export const MOTIVOS = ['Avaria ou trinca', 'Dimensão fora do padrão', 'Acabamento ou pintura', 'Peça errada', 'Outro'];
const faixa = (de, ate) => Array.from({ length: ate - de + 1 }, (_, i) => 'PC-000' + String(de + i));
// Inspeções já feitas pelo colaborador do Estoque no app (peça a peça).
export const INSPECOES = [
  {
    remessa: 'MN-0449', peca: 'Suporte do motor', recebidas: 50, data: '23/09 15:10', inspetor: 'Marcos Souza', end: 'Q-01-01-01-01',
    reprovadas: [
      ...faixa(301, 314).map((c) => ({ c, motivo: 'Dimensão fora do padrão' })),
      ...faixa(315, 320).map((c) => ({ c, motivo: 'Acabamento ou pintura' })),
    ],
  },
  { remessa: 'MN-0451', peca: 'Amortecedor traseiro', recebidas: 4, data: '22/09 14:20', inspetor: 'Marcos Souza', end: 'Q-01-02-01-01', reprovadas: [{ c: 'PC-000172', motivo: 'Avaria ou trinca' }] },
];
// Inspeção da MN-0457 no app (mesmas peças do botão "Simular inspeção"); entra quando a carga é recebida.
export const INSPECAO_MN0457 = {
  remessa: 'MN-0457', peca: 'Farol LED esquerdo', recebidas: 8, data: '25/09 17:52', inspetor: 'Marcos Souza', end: 'Q-01-03-01-01',
  reprovadas: [{ c: 'PC-000203', motivo: 'Avaria ou trinca' }, { c: 'PC-000206', motivo: 'Peça errada' }],
};

// Registro de atividades (governança): o que já aconteceu antes do início da demo. [quando, quem, o quê]
export const AUDITORIA_INICIAL = [
  ['25/09 14:05', 'Bruno Lima · Fornecedor', 'Imprimiu 10 etiquetas do lote LT-2026-088'],
  ['24/09 11:02', 'Ricardo Alves · Estoque', 'Pediu a OP-3310 (reposição do Farol LED esquerdo do KT-0142)'],
  ['23/09 15:10', 'Marcos Souza · Estoque', 'Reprovou 20 peças da MN-0449 na inspeção de qualidade'],
  ['22/09 14:20', 'Marcos Souza · Estoque', 'Reprovou 1 peça da MN-0451 na inspeção de qualidade'],
  ['21/09 09:12', 'Juliana Costa · Cliente', 'Enviou a requisição KT-0145 (Hatch E-Tech)'],
];

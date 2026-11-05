// Estado da demo e regras, portados de fresh(), advance() e do objeto A do protótipo.
import { KIT142, KITDEF, KIT_PROTO, PROTOS, OPS, LOAD_SEQ, RECV_SEQ, ACC_SEQ, GUARD, INSPECOES, INSPECAO_MN0457, AUDITORIA_INICIAL, ENDERECOS } from '../data/mock.js';

function bloquear(Q, inspecao) {
  for (const r of inspecao.reprovadas) {
    if (Q.pecas[r.c]) continue;
    Q.pecas[r.c] = {
      c: r.c, remessa: inspecao.remessa, peca: inspecao.peca, motivo: r.motivo, inspetor: inspecao.inspetor, data: inspecao.data, end: inspecao.end,
      status: 'bloqueada', decisao: null,
    };
  }
  Q.inspecoes[inspecao.remessa] = { remessa: inspecao.remessa, peca: inspecao.peca, recebidas: inspecao.recebidas, data: inspecao.data, inspetor: inspecao.inspetor, end: inspecao.end };
}

const agoraTexto = () => new Date().toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' }).replace(',', '');

export function fresh() {
  return {
    theme: 'light',
    toast: null,
    ops: { 'OP-3310': 'Pendente', 'OP-3308': 'Pendente', 'OP-3306': 'Liberado', 'OP-3302': 'Concluída', 'OP-3299': 'Concluída' },
    opSel: 'OP-3310',
    ordersTab: 'Todas',
    mn0457: 'Em Conferência', // → Aguardando Aprovação → Em Trânsito → Recebido
    labels: { printed: false },
    load: { reads: ['PC-000201', 'PC-000202', 'PC-000203', 'PC-000204', 'PC-000205', 'PC-000206'].map((c, i) => ({ c, ok: true, t: '16:' + (21 + i * 2) })), seq: 0 },
    recv: { reads: [], seq: 0 },
    kits: { 'KT-0142': 'Em Separação', 'KT-0139': 'Em Separação', 'KT-0145': 'Aguardando Separação', 'KT-0138': 'Entregue Completo', 'KT-0136': 'Entregue Completo' },
    extraKits: [],
    queue: ['KT-0142', 'KT-0139', 'KT-0145'],
    assignee: { 'KT-0142': 'Marcos Souza', 'KT-0139': 'Marcos Souza', 'KT-0145': '' },
    k142ready: false,
    route: { idx: 0 },
    ship: { scanned: false, carrier: '' },
    accept: { got: [], seq: 0 },
    req: { proto: 'hatch', items: [['Disco de freio ventilado', 4, false], ['Sensor de estacionamento', 2, false]], partial: true, prio: 'Média', q: '' },
    justSent: false,
    trace: { q: 'PC-000098', mode: 'Código' },
    kview: 'kanban',
    ksel: 'KT-0142',
    drawer: false,
    map: { z: 'A', c: '07', m: '16', n: '02', p: '03' }, // gerador de endereço (Zona-Corredor-Módulo-Nível-Posição)
    mapPeca: 'Farol LED esquerdo',
    enderecos: { ...ENDERECOS },
    // Qualidade: peças reprovadas na inspeção ficam bloqueadas até o gestor decidir o destino.
    qualidade: (() => {
      const Q = { pecas: {}, inspecoes: {}, devolucoes: [], seqDv: 12, seqOp: 3312 };
      INSPECOES.forEach((i) => bloquear(Q, i));
      return Q;
    })(),
    opsExtras: [], // ordens de reposição criadas pelo Estoque
    auditoria: AUDITORIA_INICIAL.map(([quando, quem, oque]) => ({ quando, quem, oque })),
  };
}

/** Peças da qualidade agrupadas por remessa. */
/** "A-07-16-02-03" → "Zona A · Corredor 07 · Módulo 16 · Nível 02 · Posição 03" */
export function descreverEndereco(end) {
  const [z, c, m, n, p] = end.split('-');
  return `Zona ${z} · Corredor ${c} · Módulo ${m} · Nível ${n} · Posição ${p}`;
}
export const enderecoDoMapa = (m) => [m.z, m.c, m.m, m.n, m.p].join('-');

/** "8 peças de suporte do motor" */
export const qtdPecas = (n, nome) => `${n} ${n === 1 ? 'peça' : 'peças'} de ${nome.toLowerCase()}`;

export function lotesQualidade(S) {
  const lotes = {};
  for (const p of Object.values(S.qualidade.pecas)) {
    const l = (lotes[p.remessa] ||= { ...S.qualidade.inspecoes[p.remessa], pecas: [] });
    l.pecas.push(p);
  }
  return Object.values(lotes).sort((a, b) => b.remessa.localeCompare(a.remessa));
}
export const bloqueadas = (S) => Object.values(S.qualidade.pecas).filter((p) => p.status === 'bloqueada');
export const todasOps = (S) => [...S.opsExtras, ...OPS];

/* ===== Seletores ===== */
export const loadOk = (S) => S.load.reads.filter((r) => r.ok).map((r) => r.c);
export const kitProto = (S, k) => KIT_PROTO[k] || (S.extraKits.find((x) => x.id === k) || {}).proto || '';
export const allKits = (S) => ['KT-0145', 'KT-0142', 'KT-0139', 'KT-0138', 'KT-0136', ...S.extraKits.map((x) => x.id)];
export const kitPrio = (S, k) => (k === 'KT-0142' ? 'Alta' : (KITDEF[k] || S.extraKits.find((x) => x.id === k) || {}).prio || 'Média');
export const kitItems = (S, k) =>
  k === 'KT-0142' ? KIT142.map((i) => [i.p, i.q, i.b, i.missing ? 'miss' : '']) : (KITDEF[k] || {}).items || (S.extraKits.find((x) => x.id === k) || {}).items || [];
export const kitAvail = (k) => ({ 'KT-0142': 'Parcial', 'KT-0139': 'Indisponível' })[k] || 'Disponível';
/** O Cliente aceita receber o kit em partes (só quando faltar peça não-blocante)? */
export const kitParcial = (S, k) => (S.extraKits.find((x) => x.id === k) || KITDEF[k] || {}).partial ?? true;
export const kitStatus = (S, k) => (k === 'KT-0139' ? 'Travado' : S.kits[k]);

export function statusCls(s) {
  if (/Recebido|Concluída|Entregue Completo|Pronto|Disponível|Liberado|OK|Lida|Carregada/.test(s)) return 'ok';
  if (/Problema|Parado|Indisponível|Travad|Faltou|Cancel|Zerado/.test(s)) return 'bad';
  if (/Parcial|Aguardando Aprovação|Conferência/.test(s)) return 'warn';
  if (/Pendente|Aguardando/.test(s)) return 'accent';
  return 'info';
}

/* ===== História: avanços encadeados ===== */
export function advance(S, to) {
  const order = ['opReleased', 'loadDone', 'loadSent', 'shipped', 'received', 'routeDone', 'kitShipped', 'accepted'];
  const n = order.indexOf(to);
  if (n >= 0 && S.ops['OP-3310'] === 'Pendente') S.ops['OP-3310'] = 'Liberado';
  if (n >= 1 && S.load.seq < LOAD_SEQ.length) {
    while (S.load.seq < LOAD_SEQ.length) {
      const r = LOAD_SEQ[S.load.seq++];
      S.load.reads.push({ ...r, t: '16:3' + S.load.seq });
    }
  }
  if (n >= 2 && S.mn0457 === 'Em Conferência') S.mn0457 = 'Aguardando Aprovação';
  if (n >= 3 && S.mn0457 === 'Aguardando Aprovação') S.mn0457 = 'Em Trânsito';
  if ((n === 4 || to === 'accepted') && S.mn0457 !== 'Recebido') {
    S.recv.reads = RECV_SEQ.filter((r) => r.ok).map((r, i) => ({ ...r, t: '17:' + (35 + i), sub: 'Guardar em ' + GUARD }));
    S.recv.seq = RECV_SEQ.length;
    S.mn0457 = 'Recebido';
    bloquear(S.qualidade, INSPECAO_MN0457);
  }
  if (n >= 5) {
    S.route.idx = KIT142.length;
    S.k142ready = true;
  }
  if (n >= 6 && S.kits['KT-0142'] === 'Em Separação') {
    S.kits['KT-0142'] = 'Em Trânsito';
    S.ship = { scanned: true, carrier: S.ship.carrier || 'Transporte interno', t: '18:05' };
  }
  if (n >= 7) {
    S.accept.got = [0, 1, 2, 3, 4];
    S.accept.seq = ACC_SEQ.length;
    S.kits['KT-0142'] = 'Entregue Parcial';
  }
}

let toastId = 0;
// Defeito 4: um único toast; o novo substitui o anterior.
const toast = (S, k, m) => {
  S.toast = { id: ++toastId, k, m };
};

/* ===== Ações (mesmos nomes do objeto A do protótipo) ===== */
export const ACTIONS = {
  theme: (S) => { S.theme = S.theme === 'light' ? 'dark' : 'light'; },
  toast: (S, v) => toast(S, v.k, v.m),
  clearToast: (S, id) => { if (S.toast && S.toast.id === id) S.toast = null; },
  opsTab: (S, v) => { S.ordersTab = v; },
  opSel: (S, v) => { S.opSel = v; },
  qualSel: (S, v) => { S.qualSel = v; },
  releaseOp: (S) => {
    S.ops[S.opSel] = 'Liberado';
    toast(S, 'ok', `${S.opSel} liberado para etiquetagem.${S.opSel === 'OP-3310' ? ' Bruno Lima foi avisado no app.' : ''}`);
  },
  simSend: (S) => { advance(S, 'loadSent'); toast(S, 'ok', 'Bruno Lima enviou a conferência da MN-0457 (8/10).'); },
  authorize: (S) => { S.mn0457 = 'Em Trânsito'; toast(S, 'ok', 'Expedição da MN-0457 autorizada. Status: Em Trânsito.'); },
  returnLoad: (S) => toast(S, 'warn', 'Carga devolvida para Bruno Lima conferir de novo.'),
  prio: (S, { k, d }) => {
    const q = S.queue, i = q.indexOf(k), j = i + d;
    if (j < 0 || j >= q.length) return;
    [q[i], q[j]] = [q[j], q[i]];
    toast(S, 'ok', `${k} agora é o ${j + 1}º da fila.`);
  },
  assign: (S, { k, name }) => {
    S.assignee[k] = name;
    if (name) toast(S, 'ok', `${k} atribuído a ${name}.`);
  },
  dispatch: (S, k) => {
    if (!S.assignee[k]) { toast(S, 'bad', 'Escolha o responsável antes de disparar a coleta.'); return; }
    S.kits[k] = 'Em Separação';
    toast(S, 'ok', `Ordem de coleta do ${k} enviada para ${S.assignee[k]}.`);
  },
  map: (S, v) => {
    Object.assign(S.map, v);
    if (v.z) Object.assign(S.map, { c: '01', m: '01', n: '01', p: '01' });
  },
  mapPeca: (S, part) => {
    S.mapPeca = part;
    const [z, c, m, n, p] = S.enderecos[part].split('-');
    S.map = { z, c, m, n, p };
  },
  saveMap: (S) => {
    const end = enderecoDoMapa(S.map), dono = Object.keys(S.enderecos).find((k) => S.enderecos[k] === end && k !== S.mapPeca);
    if (dono) { toast(S, 'bad', `${end} já guarda ${dono}. Escolha outra posição.`); return; }
    S.enderecos[S.mapPeca] = end;
    toast(S, 'ok', `${S.mapPeca} agora fica em ${end}.`);
  },
  copiado: (S, end) => toast(S, 'ok', `Endereço ${end} copiado.`),
  imprimirEtiqueta: (S, end) => toast(S, 'ok', `Etiqueta 50×30 mm do endereço ${end} enviada para a impressora.`),
  traceMode: (S, v) => {
    S.trace.mode = v;
    if (v === 'Lote') S.trace.q = 'LT-2026-088';
    if (v === 'Código') S.trace.q = 'PC-000098';
  },
  trace: (S, v) => {
    S.trace.q = v;
    S.trace.mode = v.startsWith('LT') ? 'Lote' : S.trace.mode === 'QR Code' ? 'QR Code' : 'Código';
    if (S.trace.mode === 'QR Code') toast(S, 'ok', 'QR lido: ' + v);
  },
  traceQuery: (S, v) => { S.trace.q = v; },
  reqProto: (S, v) => { S.req.proto = v; },
  reqQuery: (S, v) => { S.req.q = v; },
  addItem: (S, v) => {
    S.req.items.push([v, 1, false]); // o Cliente marca BLOCANTE só no que é indispensável para o teste
    S.justSent = false;
  },
  rmItem: (S, i) => { S.req.items.splice(i, 1); },
  qty: (S, { i, d }) => { S.req.items[i][1] = Math.max(1, S.req.items[i][1] + d); },
  toggleB: (S, { i, on }) => { S.req.items[i][2] = on; },
  partial: (S, on) => { S.req.partial = on; },
  reqPrio: (S, v) => { S.req.prio = v; },
  sendReq: (S) => {
    const id = 'KT-0' + (146 + S.extraKits.length);
    S.extraKits.push({ id, proto: PROTOS[S.req.proto].name, items: S.req.items.map((x) => [...x]), prio: S.req.prio, partial: S.req.partial });
    S.kits[id] = 'Aguardando Separação';
    S.queue.push(id);
    S.assignee[id] = '';
    S.req.items = [];
    S.justSent = true;
    toast(S, 'ok', `${id} enviado ao Estoque.`);
  },
  leaveReq: (S) => { S.justSent = false; },
  kview: (S, v) => { S.kview = v; },
  openKit: (S, k) => { S.ksel = k; S.drawer = true; },
  closeDrawer: (S) => { S.drawer = false; },
  searchJump: (S, { code, scr }) => {
    if (scr === 'E-ADM4') { S.trace.q = code; S.trace.mode = code.startsWith('LT') ? 'Lote' : 'Código'; }
    if (scr === 'E-ADM5') S.qualSel = code;
    if (scr === 'T-ADM3') { S.ksel = code; S.drawer = true; }
    if (scr === 'F-ADM2' && todasOps(S).find((o) => o.id === code)) S.opSel = code;
  },
  decidirQualidade: (S, { codigos, destino, repor }) => {
    const pecas = codigos.map((c) => S.qualidade.pecas[c]).filter((p) => p && p.status === 'bloqueada');
    if (!pecas.length) return;
    const quando = agoraTexto();
    const porRemessa = {};
    for (const p of pecas) (porRemessa[p.remessa] ||= []).push(p);
    const feitos = [];
    for (const [remessa, lista] of Object.entries(porRemessa)) {
      const peca = lista[0].peca;
      let dv = null, op = null;
      if (destino === 'devolvida') {
        dv = `DV-${String(S.qualidade.seqDv++).padStart(4, '0')}`;
        S.qualidade.devolucoes.unshift({ id: dv, remessa, peca, qtd: lista.length, data: quando, status: 'Devolução em trânsito' });
      }
      if (repor && destino !== 'liberada') {
        op = `OP-${S.qualidade.seqOp++}`;
        S.opsExtras.unshift({ id: op, part: peca, q: lista.length, req: quando.slice(0, 5), due: '—', why: `Reposição de ${lista.length} reprovadas na ${remessa}` });
        S.ops[op] = 'Pendente';
      }
      for (const p of lista) {
        p.status = destino;
        p.decisao = { por: 'Ricardo Alves', quando, devolucao: dv, reposicao: op };
      }
      feitos.push(`${qtdPecas(lista.length, peca)} (${remessa})${dv ? ` na ${dv}` : ''}${op ? `, reposição ${op}` : ''}`);
    }
    const verbo = { descartada: 'Descartadas e baixadas do estoque', devolvida: 'Devolvidas ao fornecedor', liberada: 'Liberadas para o estoque' }[destino];
    toast(S, 'ok', `${verbo}: ${feitos.join('; ')}.`);
  },
  skipEnd: (S) => {
    advance(S, 'opReleased');
    S.labels.printed = true;
    advance(S, 'loadSent');
    advance(S, 'shipped');
    advance(S, 'received');
    advance(S, 'accepted');
    S.kits['KT-0145'] = 'Em Separação';
    S.assignee['KT-0145'] = 'Marcos Souza';
    toast(S, 'ok', 'Demo no fim da história: KT-0142 entregue parcial.');
  },
  consultar: () => {}, // só registra no log (veja AUDITAR)
  reset: (S) => {
    const theme = S.theme;
    Object.assign(S, fresh(), { theme });
    toast(S, 'ok', 'Demo reiniciada.');
  },
};

const CARLA = 'Carla Mendes · Fornecedor', RICARDO = 'Ricardo Alves · Estoque', JULIANA = 'Juliana Costa · Cliente';
const DESTINO_AUDIT = { descartada: 'Descartou', devolvida: 'Devolveu ao fornecedor', liberada: 'Liberou após reinspeção' };

// Ações que entram no registro de atividades: (estado antes, estado depois, valor) → [quem, o quê] ou null.
const AUDITAR = {
  releaseOp: (A, S) => A.ops[A.opSel] !== 'Liberado' && [CARLA, `Liberou a ${S.opSel} para etiquetagem`],
  authorize: () => [CARLA, 'Autorizou a expedição da MN-0457'],
  returnLoad: () => [CARLA, 'Devolveu a MN-0457 para nova conferência'],
  assign: (A, S, { k, name }) => name && [RICARDO, `Atribuiu o ${k} a ${name}`],
  dispatch: (A, S, k) => S.kits[k] !== A.kits[k] || A.assignee[k] ? [RICARDO, `Disparou a ordem de coleta do ${k}`] : null,
  saveMap: (A, S) => A.enderecos[S.mapPeca] !== S.enderecos[S.mapPeca] && [RICARDO, `Mudou ${S.mapPeca} de ${A.enderecos[S.mapPeca]} para ${S.enderecos[S.mapPeca]}`],
  decidirQualidade: (A, S, { codigos, destino, repor }) =>
    [RICARDO, `${DESTINO_AUDIT[destino]} ${codigos.length === 1 ? '1 peça' : `${codigos.length} peças`} bloqueadas (${codigos[0]}${codigos.length > 1 ? ` a ${codigos.at(-1)}` : ''})${repor && destino !== 'liberada' ? ' e pediu reposição' : ''}`],
  sendReq: (A, S) => [JULIANA, `Enviou a requisição ${S.extraKits.at(-1).id}`],
  consultar: (A, S, oque) => [RICARDO, oque],
};

export function reducer(state, action) {
  const f = ACTIONS[action.type];
  if (!f) return state;
  const S = structuredClone(state);
  f(S, action.v);
  const reg = AUDITAR[action.type]?.(state, S, action.v);
  if (reg) S.auditoria.unshift({ quando: agoraTexto(), quem: reg[0], oque: reg[1] });
  return S;
}


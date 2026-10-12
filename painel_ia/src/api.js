// Cliente da API de detecção (detector_api). O endereço fica salvo neste navegador.
const CHAVE = 'painel_ia_api';
export const API_PADRAO = 'http://localhost:8000';

export function apiBase() {
  try {
    return localStorage.getItem(CHAVE) || API_PADRAO;
  } catch {
    return API_PADRAO;
  }
}

export function salvarApiBase(url) {
  try {
    localStorage.setItem(CHAVE, url.replace(/\/+$/, ''));
  } catch {
    // sem armazenamento: vale só nesta sessão
  }
}

export const wsUrl = (base = apiBase()) => base.replace(/^http/, 'ws') + '/ws/detectar';

/** Erro padronizado da API: {"erro": {"codigo", "mensagem"}}. */
export class ErroApi extends Error {
  constructor(codigo, mensagem) {
    super(mensagem);
    this.codigo = codigo;
  }
}

async function lerJson(r) {
  const corpo = await r.json().catch(() => null);
  if (!r.ok) throw new ErroApi(corpo?.erro?.codigo || `HTTP_${r.status}`, corpo?.erro?.mensagem || r.statusText);
  return corpo;
}

export async function buscarStatus(base = apiBase(), sinal) {
  try {
    return await lerJson(await fetch(base + '/status', { signal: sinal }));
  } catch (e) {
    if (e instanceof ErroApi || e.name === 'AbortError') throw e;
    throw new ErroApi('SEM_CONEXAO', `Não consegui falar com ${base}. A API está rodando (python -m app)?`);
  }
}

export async function detectarImagem(arquivo, { confianca, imgsz, classes } = {}) {
  const q = new URLSearchParams();
  if (confianca != null) q.set('confianca', confianca);
  if (imgsz) q.set('imgsz', imgsz);
  if (classes?.length) q.set('classes', classes.join(','));
  const corpo = new FormData();
  corpo.append('imagem', arquivo);
  try {
    return await lerJson(await fetch(`${apiBase()}/detectar?${q}`, { method: 'POST', body: corpo }));
  } catch (e) {
    if (e instanceof ErroApi) throw e;
    throw new ErroApi('SEM_CONEXAO', `Não consegui enviar para ${apiBase()}.`);
  }
}

/** [4 bytes: tamanho do cabeçalho, big-endian][cabeçalho JSON][JPEG] */
export function montarQuadro(seq, capturadoEm, jpeg, rotacao = 0) {
  const cab = new TextEncoder().encode(JSON.stringify({ tipo: 'quadro', seq, capturado_em: capturadoEm, rotacao }));
  const saida = new Uint8Array(4 + cab.length + jpeg.byteLength);
  new DataView(saida.buffer).setUint32(0, cab.length, false);
  saida.set(cab, 4);
  saida.set(new Uint8Array(jpeg), 4 + cab.length);
  return saida;
}

/* ===== Dataset de treino ===== */
async function pedir(caminho, opcoes = {}) {
  try {
    const r = await fetch(apiBase() + caminho, opcoes);
    return await lerJson(r);
  } catch (e) {
    if (e instanceof ErroApi) throw e;
    throw new ErroApi('SEM_CONEXAO', `Não consegui falar com ${apiBase()}. A API está rodando?`);
  }
}

const json = (metodo, corpo) => ({ method: metodo, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(corpo) });

export const urlImagem = (id) => `${apiBase()}/dataset/imagens/${id}/arquivo`;
export const urlMiniatura = (id) => `${apiBase()}/dataset/imagens/${id}/miniatura`;
export const resumoDataset = () => pedir('/dataset/resumo');
export const listarImagens = ({ status, classe_id } = {}) => {
  const q = new URLSearchParams({ limite: 2000 });
  if (status) q.set('status', status);
  if (classe_id != null && classe_id !== '') q.set('classe_id', classe_id);
  return pedir(`/dataset/imagens?${q}`);
};
export const salvarCaixas = (id, caixas, status) => pedir(`/dataset/imagens/${id}/caixas`, json('PUT', { caixas, status }));
export const ajustarImagem = (id, ajuste) => pedir(`/dataset/imagens/${id}`, json('PATCH', ajuste));
export const iniciarSugestoes = (todas = false) => pedir('/dataset/sugestoes', json('POST', { todas }));
export const estadoSugestoes = () => pedir('/dataset/sugestoes');
export const criarClasse = (nome, rotulo) => pedir('/dataset/classes', json('POST', { nome, rotulo }));
export const enviarFotoDataset = (arquivo, classeId) => {
  const corpo = new FormData();
  corpo.append('imagem', arquivo);
  corpo.append('origem', 'painel');
  if (classeId) corpo.append('classe_id', classeId);
  return pedir('/dataset/imagens', { method: 'POST', body: corpo });
};

/* ===== Treinos e modelos ===== */
export const listarTreinos = () => pedir('/treinos');
export const iniciarTreino = (parametros) => pedir('/treinos', json('POST', parametros));
export const obterTreino = (id) => pedir(`/treinos/${id}`);
export const cancelarTreino = (id) => pedir(`/treinos/${id}/cancelar`, { method: 'POST' });
export const listarModelos = () => pedir('/modelos');
export const ativarModelo = (arquivo) => pedir(`/modelos/${encodeURIComponent(arquivo)}/ativar`, { method: 'POST' });

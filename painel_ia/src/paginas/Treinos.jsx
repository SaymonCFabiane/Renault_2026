import { useCallback, useEffect, useState } from 'react';
import { ativarModelo, cancelarTreino, iniciarTreino, listarModelos, listarTreinos, obterTreino } from '../api.js';
import GraficoMetricas from '../components/GraficoMetricas.jsx';
import Icon from '../components/Icon.jsx';
import { Banner, Button, Card, Segmented, Stat } from '../components/ui.jsx';

const pct = (v) => (v == null ? '–' : `${Math.round(v * 100)}%`);
const data = (s) => (s ? new Date(s * 1000).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' }) : '–');
const duracao = (a, b) => {
  if (!a) return '–';
  const s = Math.round((b || Date.now() / 1000) - a);
  return s < 60 ? `${s} s` : `${Math.floor(s / 60)} min ${String(s % 60).padStart(2, '0')} s`;
};
const SITUACAO = { preparando: ['Preparando', 'info'], treinando: ['Treinando', 'info'], concluido: ['Concluído', 'ok'], erro: ['Erro', 'blocante'], cancelado: ['Cancelado', 'nao'], interrompido: ['Interrompido', 'warn'] };

/** Treinos: novo treino, acompanhamento, histórico e modelos. */
export default function Treinos({ atualizar }) {
  const [estado, setEstado] = useState(null);
  const [modelos, setModelos] = useState([]);
  const [atual, setAtual] = useState(null);
  const [verId, setVerId] = useState(null);
  const [params, setParams] = useState({ base: 'yolo11n.pt', epocas: 80, imgsz: 640 });
  const [erro, setErro] = useState(null);
  const [aviso, setAviso] = useState(null);
  const [ocupado, setOcupado] = useState(false);

  const carregar = useCallback(async () => {
    try {
      const [e, m] = await Promise.all([listarTreinos(), listarModelos()]);
      setEstado(e);
      setModelos(m);
      setErro(null);
      const id = e.rodando || verId || e.itens[0]?.id;
      setAtual(id ? await obterTreino(id) : null);
    } catch (err) {
      setErro(err.message);
    }
  }, [verId]);

  useEffect(() => { carregar(); }, [carregar]);
  // Durante o treino, atualiza a cada 2 s.
  useEffect(() => {
    if (!estado?.rodando) return undefined;
    const t = setInterval(carregar, 2000);
    return () => clearInterval(t);
  }, [estado?.rodando, carregar]);

  async function treinar() {
    setOcupado(true); setAviso(null);
    try {
      const t = await iniciarTreino(params);
      setVerId(t.id);
      await carregar();
    } catch (e) {
      setErro(e.message);
    } finally {
      setOcupado(false);
    }
  }

  async function cancelar(id) {
    setOcupado(true);
    try { await cancelarTreino(id); await carregar(); } catch (e) { setErro(e.message); } finally { setOcupado(false); }
  }

  async function ativar(arquivo) {
    setOcupado(true); setAviso(null);
    try {
      const r = await ativarModelo(arquivo);
      setAviso(`Modelo ${r.ativo} ativo. O app e o painel já detectam: ${Object.values(r.classes).join(', ')}.`);
      await carregar();
      atualizar?.();
    } catch (e) {
      setErro(e.message);
    } finally {
      setOcupado(false);
    }
  }

  if (!estado) return erro ? <Banner tone="bad" icon="circle-x" title="API fora do ar">{erro}</Banner> : null;
  const ds = estado.dataset;
  const rodando = estado.rodando;
  const hist = atual?.historico || [];
  const ultimo = hist.at(-1);
  const restante = ultimo && atual.situacao === 'treinando' ? Math.round((ultimo.segundos / ultimo.epoca) * (atual.epocas - ultimo.epoca)) : null;
  const ativo = modelos.find((m) => m.ativo);

  return (
    <div className="tp-grid">
      <div style={{ gridColumn: 'span 8', minWidth: 0 }} className="tp-stack">
        {aviso && <Banner tone="ok" icon="circle-check" title={aviso} />}
        {erro && <Banner tone="bad" icon="circle-x" title="Problema">{erro}</Banner>}

        {atual ? (
          <Card title={`Treino ${data(atual.criado_em)}`} extra={
            <div className="tp-row">
              <span className={`tp-tag tp-tag--${SITUACAO[atual.situacao]?.[1] || 'info'}`}>{SITUACAO[atual.situacao]?.[0] || atual.situacao}</span>
              {rodando === atual.id && <Button variant="outline" size="sm" icon="square" disabled={ocupado} onClick={() => cancelar(atual.id)}>Cancelar</Button>}
              {atual.situacao === 'concluido' && atual.modelo !== ativo?.arquivo && <Button size="sm" icon="check" disabled={ocupado} onClick={() => ativar(atual.modelo)}>Ativar este modelo</Button>}
            </div>
          }>
            <div className="tp-field-row" style={{ marginBottom: 6 }}>
              <span className="tp-cap">
                {atual.situacao === 'concluido' && atual.epoca < atual.epocas
                  ? `Parou na época ${atual.epoca} de ${atual.epocas}: sem melhora desde a ${atual.melhor?.epoca}`
                  : `Época ${atual.epoca} de ${atual.epocas}`} · {atual.base} · {atual.imgsz} px · {atual.dispositivo?.toUpperCase()}
              </span>
              <span className="tp-cap">{duracao(atual.iniciado_em, atual.concluido_em)}{restante != null ? ` · faltam ~${duracao(0, restante)}` : ''}</span>
            </div>
            <div className={`tp-progress${atual.situacao === 'concluido' ? ' tp-progress--ok' : ''}`} style={{ marginBottom: 16 }}><i style={{ width: `${atual.situacao === 'concluido' ? 100 : (atual.epoca / Math.max(1, atual.epocas)) * 100}%` }} /></div>
            {atual.mensagem && <div style={{ marginBottom: 12 }}><Banner tone={atual.situacao === 'erro' ? 'bad' : 'warn'} icon="circle-alert" title={atual.mensagem} /></div>}
            <div className="tp-metricas" style={{ marginBottom: 14 }}>
              <Stat value={pct(atual.melhor?.map50)} label="Acerto (mAP50)" tone={atual.melhor?.map50 >= 0.8 ? 'ok' : undefined} />
              <Stat value={pct(atual.melhor?.map50_95)} label="Precisão da caixa (mAP50-95)" />
              <Stat value={pct(atual.melhor?.precisao)} label="Acertos entre o que achou (precisão)" />
              <Stat value={pct(atual.melhor?.revocacao)} label="Peças encontradas (revocação)" />
            </div>
            {hist.length > 0 ? <GraficoMetricas historico={hist} epocas={atual.epocas} />
              : <p className="tp-muted">As métricas aparecem ao fim da primeira época (o preparo leva alguns segundos).</p>}
            {atual.situacao === 'concluido' && (
              <p className="tp-cap" style={{ margin: '12px 0 0' }}>
                Melhor época: {atual.melhor?.epoca}. Modelo salvo como <b>{atual.modelo}</b>. Os números vêm das {atual.divisoes?.validacao?.fotos} fotos de validação, que o modelo não viu no treino.
              </p>
            )}
            {atual.log?.length > 0 && (
              <details style={{ marginTop: 12 }}>
                <summary className="tp-label" style={{ cursor: 'pointer' }}>Registro do treino</summary>
                <pre className="tp-code">{atual.log.join('\n')}</pre>
              </details>
            )}
          </Card>
        ) : (
          <Card title="Nenhum treino ainda"><p className="tp-muted" style={{ margin: 0 }}>Escolha os parâmetros ao lado e toque em Treinar.</p></Card>
        )}

        <Card title="Histórico de treinos">
          {estado.itens.length ? (
            <div className="tp-table-wrap">
              <table className="tp-table">
                <thead><tr><th>Quando</th><th>Base</th><th>Épocas</th><th>Acerto</th><th>Caixa</th><th>Duração</th><th>Situação</th><th /></tr></thead>
                <tbody>
                  {estado.itens.map((t) => (
                    <tr key={t.id} className={`is-clickable${atual?.id === t.id ? ' is-selected' : ''}`} onClick={() => setVerId(t.id)}>
                      <td className="num">{data(t.criado_em)}</td>
                      <td>{t.base}</td>
                      <td className="num">{t.epoca}/{t.epocas}</td>
                      <td className="num">{pct(t.melhor?.map50)}</td>
                      <td className="num">{pct(t.melhor?.map50_95)}</td>
                      <td className="num">{duracao(t.iniciado_em, t.concluido_em)}</td>
                      <td><span className={`tp-tag tp-tag--${SITUACAO[t.situacao]?.[1] || 'info'}`}>{SITUACAO[t.situacao]?.[0] || t.situacao}</span></td>
                      <td>{t.modelo && t.modelo === ativo?.arquivo ? <span className="tp-tag tp-tag--ok">Em uso</span> : null}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : <p className="tp-muted" style={{ margin: 0 }}>Os treinos aparecem aqui.</p>}
        </Card>
      </div>

      <div style={{ gridColumn: 'span 4', minWidth: 0 }} className="tp-stack">
        <Card title="Novo treino">
          <div className="tp-stack" style={{ gap: 14 }}>
            <div className="tp-table-wrap">
              <table className="tp-table">
                <thead><tr><th>Caixas revisadas</th><th>Treino</th><th>Validação</th></tr></thead>
                <tbody>
                  {ds.classes.map((c) => (
                    <tr key={c.id}><td><span className="tp-row" style={{ gap: 6 }}><i style={{ width: 10, height: 10, borderRadius: 2, background: c.cor, display: 'inline-block' }} />{c.rotulo}</span></td>
                      <td className="num">{c.caixas_treino}</td><td className="num">{c.caixas_validacao}</td></tr>
                  ))}
                  <tr><td><b>Fotos revisadas</b></td><td className="num">{ds.revisadas_por_divisao.treino}</td><td className="num">{ds.revisadas_por_divisao.validacao}</td></tr>
                </tbody>
              </table>
            </div>
            {estado.problemas.map((p) => <Banner key={p} tone="warn" icon="circle-alert" title={p} />)}
            <div>
              <div className="tp-label">Modelo base</div>
              <Segmented label="Modelo base" value={params.base} onChange={(base) => setParams({ ...params, base })}
                items={[{ value: 'yolo11n.pt', label: 'Rápido (n)' }, { value: 'yolo11s.pt', label: 'Preciso (s)' }]} />
              {!estado.bases.includes(params.base) && <p className="tp-cap" style={{ margin: '6px 0 0' }}>Baixe antes: .venv/bin/python baixar_modelo.py {params.base}</p>}
            </div>
            <div>
              <div className="tp-label">Épocas (voltas pelo dataset)</div>
              <Segmented label="Épocas" value={params.epocas} onChange={(epocas) => setParams({ ...params, epocas })}
                items={[50, 80, 120].map((v) => ({ value: v, label: String(v) }))} />
              <p className="tp-cap" style={{ margin: '6px 0 0' }}>Para sozinho antes se parar de melhorar. Com {ds.revisadas_por_divisao.treino} fotos, 80 épocas levam uns 10 a 15 min no Mac.</p>
            </div>
            <Button block icon="play" disabled={ocupado || !!rodando || estado.problemas.length > 0 || !estado.bases.includes(params.base)} onClick={treinar}>
              {rodando ? 'Treinando…' : 'Treinar'}
            </Button>
            <p className="tp-cap" style={{ margin: 0 }}>Durante o treino a GPU é dividida: a detecção ao vivo do app fica mais lenta.</p>
          </div>
        </Card>

        <Card title="Modelos">
          <div className="tp-stack" style={{ gap: 10 }}>
            {modelos.map((m) => (
              <div key={m.arquivo} className="tp-result" style={m.ativo ? { borderColor: 'var(--success)' } : undefined}>
                <div className="t">
                  <b style={{ wordBreak: 'break-all' }}>{m.arquivo}</b>
                  <span>{m.tipo === 'treinado' ? `${m.classes?.join(', ')} · acerto ${pct(m.metricas?.map50)}` : 'Pré-treinado (80 objetos do dia a dia)'} · {m.tamanho_mb} MB</span>
                </div>
                {m.ativo ? <span className="tp-tag tp-tag--ok"><Icon name="check" size={12} />Em uso</span>
                  : <Button size="sm" variant="outline" disabled={ocupado} onClick={() => ativar(m.arquivo)}>Ativar</Button>}
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

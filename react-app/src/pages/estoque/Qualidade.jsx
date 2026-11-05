import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PATHS, QUARENTENA } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import { lotesQualidade, qtdPecas } from '../../state/logic.js';
import Card, { Col, Stat } from '../../components/Card.jsx';
import Banner, { EmptyState } from '../../components/Banner.jsx';
import Button from '../../components/Button.jsx';
import { Tag } from '../../components/CriticalityTag.jsx';
import Icon from '../../components/Icon.jsx';

const DESTINOS = {
  descartada: { verbo: 'Descartar', icone: 'trash', variante: 'danger', explica: 'As peças saem do estoque como sucata (baixa definitiva).' },
  devolvida: { verbo: 'Devolver ao fornecedor', icone: 'devolver', variante: 'outline', explica: 'Gera uma remessa de devolução para a MetalSul Autopeças.' },
  liberada: { verbo: 'Liberar após reinspeção', icone: 'shield-check', variante: 'outline', explica: 'A reinspeção aprovou: as peças voltam ao estoque disponível.' },
};
const SITUACAO = {
  bloqueada: ['BLOQUEADA', 'warn', 'shield-alert'],
  descartada: ['DESCARTADA', 'blocante', 'trash'],
  devolvida: ['DEVOLVIDA', 'info', 'devolver'],
  liberada: ['LIBERADA', 'ok', 'shield-check'],
};

function Lote({ lote, aberto, onAbrir }) {
  const { act } = useDemo();
  const navigate = useNavigate();
  const pendentes = lote.pecas.filter((p) => p.status === 'bloqueada');
  const [sel, setSel] = useState(() => new Set(pendentes.map((p) => p.c)));
  const [destino, setDestino] = useState(null);
  const [repor, setRepor] = useState(true);
  const selecionadas = pendentes.filter((p) => sel.has(p.c));
  const taxa = Math.round((lote.pecas.length / lote.recebidas) * 100);
  const motivos = Object.entries(lote.pecas.reduce((a, p) => ((a[p.motivo] = (a[p.motivo] || 0) + 1), a), {}));
  const contagem = Object.fromEntries(Object.keys(SITUACAO).map((k) => [k, lote.pecas.filter((p) => p.status === k).length]));

  function alternar(c) {
    const n = new Set(sel);
    if (n.has(c)) n.delete(c); else n.add(c);
    setSel(n);
  }

  function confirmar() {
    act('decidirQualidade', { codigos: selecionadas.map((p) => p.c), destino, repor });
    setDestino(null);
    setSel(new Set());
  }

  return (
    <section className="tp-card">
      <button type="button" className="tp-qual__cab" onClick={onAbrir} aria-expanded={aberto}>
        <div style={{ minWidth: 0 }}>
          <div className="tp-h2">{lote.remessa} · {lote.peca}</div>
          <div className="tp-cap">Inspecionada por {lote.inspetor} em {lote.data} · {lote.recebidas} recebidas, {lote.pecas.length} {lote.pecas.length === 1 ? 'reprovada' : 'reprovadas'} ({taxa}%) · quarentena {lote.end}</div>
        </div>
        <div className="tp-row" style={{ gap: 6, justifyContent: 'flex-end' }}>
          {Object.entries(contagem).filter(([, n]) => n).map(([k, n]) => <Tag key={k} tone={SITUACAO[k][1]} icon={SITUACAO[k][2]}>{n} {SITUACAO[k][0]}{n > 1 ? 'S' : ''}</Tag>)}
          <Icon name={aberto ? 'chevron-up' : 'chevron-down'} />
        </div>
      </button>

      {aberto && (
        <div className="tp-stack" style={{ gap: 14, marginTop: 16 }}>
          <div className="tp-row" style={{ gap: 8 }}>
            <span className="tp-cap" style={{ fontWeight: 700 }}>Motivos:</span>
            {motivos.map(([m, n]) => <span key={m} className="tp-tag tp-tag--nao">{m} · {n}</span>)}
          </div>
          {pendentes.length > 0 && (
            <div className="tp-row" style={{ justifyContent: 'space-between' }}>
              <label className="tp-check">
                <input type="checkbox" checked={selecionadas.length === pendentes.length}
                  onChange={(e) => setSel(new Set(e.target.checked ? pendentes.map((p) => p.c) : []))} />
                <span><b>{selecionadas.length} de {pendentes.length}</b> peças bloqueadas selecionadas · quarentena {lote.end}</span>
              </label>
            </div>
          )}
          <div className="tp-qual__pecas">
            {lote.pecas.map((p) => {
              const [rot, tom, icone] = SITUACAO[p.status];
              const livre = p.status === 'bloqueada';
              return (
                <label key={p.c} className={`tp-qual__peca${livre ? '' : ' feita'}`} title={p.motivo}>
                  {livre ? <input type="checkbox" checked={sel.has(p.c)} onChange={() => alternar(p.c)} /> : <Icon name={icone} size={16} />}
                  <span className="t"><b className="num">{p.c}</b><span>{p.motivo}</span></span>
                  {!livre && <span className={`tp-tag tp-tag--${tom}`}>{rot}</span>}
                  <button type="button" className="tp-icon-btn" style={{ width: 28, height: 28 }} aria-label={`Rastrear ${p.c}`}
                    onClick={(e) => { e.preventDefault(); act('searchJump', { code: p.c, scr: 'E-ADM4' }); navigate(PATHS['E-ADM4']); }}>
                    <Icon name="history" size={16} />
                  </button>
                </label>
              );
            })}
          </div>

          {pendentes.length > 0 && !destino && (
            <div className="tp-row">
              {Object.entries(DESTINOS).map(([k, d]) => (
                <Button key={k} variant={d.variante} icon={d.icone} disabled={!selecionadas.length} onClick={() => setDestino(k)}>{d.verbo} ({selecionadas.length})</Button>
              ))}
            </div>
          )}

          {destino && (
            <div className="tp-qual__confirma">
              <div>
                <b>{DESTINOS[destino].verbo}: {qtdPecas(selecionadas.length, lote.peca)} da {lote.remessa}?</b>
                <p className="tp-cap" style={{ margin: '2px 0 0' }}>{DESTINOS[destino].explica}</p>
              </div>
              {destino !== 'liberada' && (
                <label className="tp-check">
                  <input type="checkbox" checked={repor} onChange={(e) => setRepor(e.target.checked)} />
                  <span>Pedir {selecionadas.length === 1 ? '1 peça' : `${selecionadas.length} peças`} de reposição ao fornecedor (cria uma ordem de produção para a Carla Mendes)</span>
                </label>
              )}
              <div className="tp-row">
                <Button variant={destino === 'descartada' ? 'danger' : 'primary'} icon="check" onClick={confirmar}>Confirmar</Button>
                <Button variant="ghost" onClick={() => setDestino(null)}>Cancelar</Button>
              </div>
            </div>
          )}

          {lote.pecas.some((p) => p.decisao) && (
            <div className="tp-stack" style={{ gap: 6 }}>
              <span className="tp-label">Decisões</span>
              {Object.values(lote.pecas.filter((p) => p.decisao).reduce((a, p) => {
                const k = `${p.status}|${p.decisao.quando}|${p.decisao.devolucao}|${p.decisao.reposicao}`;
                (a[k] ||= { ...p.decisao, status: p.status, n: 0 }).n++;
                return a;
              }, {})).map((d) => (
                <div key={`${d.status}${d.quando}${d.reposicao}`} className="tp-cap">
                  {d.quando} · {d.por}: {d.n} {SITUACAO[d.status][0].toLowerCase()}{d.n > 1 ? 's' : ''}
                  {d.devolucao ? ` na devolução ${d.devolucao}` : ''}{d.reposicao ? ` · reposição pedida (${d.reposicao})` : ''}
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </section>
  );
}

// E-ADM5 · Bloqueios de Qualidade
export default function Qualidade() {
  const { S } = useDemo();
  const lotes = lotesQualidade(S);
  const todas = lotes.flatMap((l) => l.pecas);
  const n = (st) => todas.filter((p) => p.status === st).length;
  const recebidas = lotes.reduce((a, l) => a + l.recebidas, 0);
  const pend = (l) => l.pecas.filter((p) => p.status === 'bloqueada').length;
  const [aberto, setAberto] = useState(() => S.qualSel || [...lotes].sort((a, b) => pend(b) - pend(a))[0]?.remessa);

  return (
    <div className="tp-grid">
      <Col span={12}>
        <Card title="Bloqueios de qualidade" extra={<span className="tp-cap">{QUARENTENA}</span>}>
          <div className="tp-grid" style={{ gridTemplateColumns: 'repeat(5, 1fr)', gap: 12 }}>
            <Stat value={n('bloqueada')} label="Aguardando decisão" tone={n('bloqueada') ? 'warn' : 'ok'} />
            <Stat value={n('descartada')} label="Descartadas" />
            <Stat value={n('devolvida')} label="Devolvidas ao fornecedor" />
            <Stat value={n('liberada')} label="Liberadas na reinspeção" />
            <Stat value={`${Math.round((todas.length / Math.max(1, recebidas)) * 100)}%`} label={`Reprovação MetalSul (${todas.length} de ${recebidas})`} tone="bad" />
          </div>
          <p className="tp-cap" style={{ margin: '14px 0 0' }}>
            O colaborador inspeciona peça a peça no recebimento (app). As reprovadas ficam bloqueadas na quarentena e não entram em kits até você decidir o destino.
          </p>
        </Card>
      </Col>
      {S.qualidade.devolucoes.length > 0 && (
        <Col span={12}>
          <Banner tone="info" icon="truck" title={`${S.qualidade.devolucoes.length} devolução(ões) a caminho do fornecedor`}>
            {S.qualidade.devolucoes.map((d) => `${d.id}: ${qtdPecas(d.qtd, d.peca)} da ${d.remessa}`).join(' · ')}
          </Banner>
        </Col>
      )}
      <Col span={12}>
        {lotes.length ? (
          <div className="tp-stack">
            {lotes.map((l) => <Lote key={l.remessa} lote={l} aberto={aberto === l.remessa} onAbrir={() => setAberto(aberto === l.remessa ? null : l.remessa)} />)}
          </div>
        ) : <EmptyState icon="shield-check" title="Nenhuma peça reprovada">As reprovações da inspeção aparecem aqui.</EmptyState>}
      </Col>
    </div>
  );
}

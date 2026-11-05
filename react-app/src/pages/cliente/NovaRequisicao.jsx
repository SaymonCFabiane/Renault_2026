import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { CATALOG, PATHS, PROTOS } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import Card, { Col } from '../../components/Card.jsx';
import { EmptyState } from '../../components/Banner.jsx';
import Button from '../../components/Button.jsx';
import SearchField from '../../components/SearchField.jsx';
import Icon from '../../components/Icon.jsx';
import { Segmented } from '../../components/Tabs.jsx';

function CatalogResults({ S, act }) {
  const q = S.req.q.trim().toLowerCase();
  const list = CATALOG.filter((c) => !q || c[0].toLowerCase().includes(q) || c[1].toLowerCase().includes(q));
  if (!list.length) return <EmptyState icon="search" title="Nenhuma peça encontrada">Busque pelo nome ou pelo código (PN).</EmptyState>;
  return list.map((c) => {
    const inKit = S.req.items.some((x) => x[0] === c[0]);
    return (
      <div key={c[0]} className="tp-result">
        <div className="tp-iconbox tp-iconbox--data" style={{ width: 40, height: 40 }}><Icon name="package" /></div>
        <div className="t"><b>{c[0]}</b><span>{c[1]}</span></div>
        <Button size="sm" variant={inKit ? 'secondary' : 'outline'} icon={inKit ? 'check' : 'plus'} disabled={inKit} onClick={() => act('addItem', c[0])}>{inKit ? 'No kit' : 'Adicionar ao kit'}</Button>
      </div>
    );
  });
}

// T-ADM2 · Nova Requisição de Kit
export default function NovaRequisicao() {
  const { S, act } = useDemo();
  const navigate = useNavigate();
  const r = S.req, last = S.extraKits.at(-1);
  useEffect(() => () => act('leaveReq'), [act]);
  return (
    <div className="tp-grid">
      {last && S.justSent && (
        <Col span={12}>
          <div className="tp-banner tp-banner--ok">
            <Icon name="circle-check" />
            <div><b>{last.id} enviado ao Estoque</b>
              <p>Ricardo Alves já vê o pedido na fila.{' '}
                <button type="button" className="tp-link" onClick={() => { act('openKit', last.id); navigate(PATHS['T-ADM3']); }}>Acompanhar {last.id}</button></p>
            </div>
          </div>
        </Col>
      )}
      <Col span={7}>
        <Card title="Catálogo de peças">
          <div className="tp-stack" style={{ gap: 14 }}>
            <div>
              <label className="tp-label" htmlFor="rq-proto">Protótipo</label>
              <select id="rq-proto" className="tp-select" value={r.proto} onChange={(e) => act('reqProto', e.target.value)}>
                {Object.entries(PROTOS).map(([k, p]) => <option key={k} value={k}>{p.name}</option>)}
              </select>
            </div>
            <SearchField id="rq-q" value={r.q} onChange={(v) => act('reqQuery', v)} placeholder="Buscar peça por nome ou PN" label="Buscar no catálogo" />
            <div className="tp-stack" style={{ gap: 8 }}><CatalogResults S={S} act={act} /></div>
          </div>
        </Card>
      </Col>
      <Col span={5}>
        <Card title="Kit solicitado" extra={<span className="tp-cap">{r.items.length} itens</span>}>
          <div className="tp-stack" style={{ gap: 14 }}>
            {r.items.length ? (
              <div className="tp-stack" style={{ gap: 8 }}>
                {r.items.map((it, i) => (
                  <div key={it[0]} className="tp-result">
                    <div className="t">
                      <b>{it[0]}</b>
                      <span className="tp-row" style={{ gap: 6, marginTop: 4 }}>
                        Qtd
                        <button type="button" className="tp-icon-btn" style={{ width: 26, height: 26 }} aria-label={`Diminuir ${it[0]}`} onClick={() => act('qty', { i, d: -1 })}><Icon name="minus" /></button>
                        <b className="num">{it[1]}</b>
                        <button type="button" className="tp-icon-btn" style={{ width: 26, height: 26 }} aria-label={`Aumentar ${it[0]}`} onClick={() => act('qty', { i, d: 1 })}><Icon name="plus" /></button>
                      </span>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
                      <label className="tp-switch">
                        <input type="checkbox" checked={it[2]} onChange={(e) => act('toggleB', { i, on: e.target.checked })} />
                        <span className="track" />
                        <span style={{ color: it[2] ? 'var(--danger)' : 'var(--text-secondary)' }}>{it[2] ? 'BLOCANTE' : 'NÃO-BLOCANTE'}</span>
                      </label>
                      <button type="button" className="tp-link" style={{ fontSize: 12 }} onClick={() => act('rmItem', i)}>Remover</button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyState icon="boxes" title="Nenhuma peça no kit">Adicione peças pelo catálogo ao lado.</EmptyState>
            )}
            {r.items.length > 0 && <p className="tp-cap" style={{ margin: 0 }}>Todas as peças entram como NÃO-BLOCANTE. Ligue BLOCANTE só nas peças sem as quais o teste não acontece.</p>}
            <div>
              <div className="tp-label">Entregas parciais</div>
              <Segmented label="Entregas parciais" value={r.partial ? 'sim' : 'nao'} onChange={(v) => act('partial', v === 'sim')}
                items={[{ value: 'sim', label: 'Aceitar', icon: 'check' }, { value: 'nao', label: 'Não aceitar', icon: 'x' }]} />
              <p className="tp-cap" style={{ margin: '6px 0 0' }}>
                {r.partial
                  ? 'Se faltar só peça NÃO-BLOCANTE, o Estoque envia o que já tem e o restante chega depois.'
                  : 'O kit só sai do Estoque com todas as peças, mesmo que isso atrase a entrega.'}
              </p>
            </div>
            <div>
              <div className="tp-label">Prioridade</div>
              <Segmented className="tp-seg--prio" label="Prioridade" value={r.prio} onChange={(v) => act('reqPrio', v)}
                items={[{ value: 'Baixa', label: 'Baixa' }, { value: 'Média', label: 'Média' }, { value: 'Alta', label: 'Alta/Urgente' }]} />
            </div>
            <Button block icon="send" disabled={!r.items.length} onClick={() => act('sendReq')}>Enviar Solicitação ao Estoque</Button>
          </div>
        </Card>
      </Col>
    </div>
  );
}

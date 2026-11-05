import { CATALOG } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import { todasOps } from '../../state/logic.js';
import Card, { Col } from '../../components/Card.jsx';
import Tabs from '../../components/Tabs.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import StatusText from '../../components/StatusText.jsx';
import Banner, { EmptyState } from '../../components/Banner.jsx';
import Button from '../../components/Button.jsx';
import { useLeitura } from '../../state/somenteLeitura.js';

const TAB_STATUS = { Pendentes: 'Pendente', Liberadas: 'Liberado', Concluídas: 'Concluída' };

// F-ADM2 · Ordens de Produção
export default function OrdensProducao() {
  const travado = !!useLeitura();
  const { S, act } = useDemo();
  const f = S.ordersTab;
  const inTab = (o, t) => t === 'Todas' || TAB_STATUS[t] === S.ops[o.id];
  const OPS = todasOps(S);
  const list = OPS.filter((o) => inTab(o, f));
  const o = OPS.find((x) => x.id === S.opSel);
  const done = S.ops[o.id] !== 'Pendente';
  return (
    <div className="tp-grid">
      <Col span={8}>
        <Card title="Solicitações de fabricação da Montadora">
          <Tabs style={{ marginBottom: 16 }} value={f} onChange={(v) => act('opsTab', v)}
            items={['Todas', 'Pendentes', 'Liberadas', 'Concluídas'].map((t) => ({ value: t, label: t, count: OPS.filter((x) => inTab(x, t)).length }))} />
          {list.length ? (
            <DataTable head={<><SortTh>Ordem</SortTh><SortTh>Peça</SortTh><SortTh align="right">Qtd</SortTh><SortTh>Prazo</SortTh><SortTh>Status</SortTh></>}>
              {list.map((x) => (
                <tr key={x.id} className={`is-clickable${x.id === S.opSel ? ' is-selected' : ''}`} onClick={() => act('opSel', x.id)}>
                  <td><b>{x.id}</b><div className="tp-cap">{x.why}</div></td>
                  <td>{x.part}</td>
                  <td className="num" style={{ textAlign: 'right' }}>{x.q}</td>
                  <td className="num">{x.due === '—' ? 'a combinar' : `${x.due}/2026`}</td>
                  <td><StatusText>{S.ops[x.id]}</StatusText></td>
                </tr>
              ))}
            </DataTable>
          ) : (
            <EmptyState icon="inbox" title="Nenhuma ordem nesta aba">As ordens aparecem aqui quando mudam de status.</EmptyState>
          )}
        </Card>
      </Col>
      <Col span={4}>
        <Card title="Liberar lote">
          <div key={o.id} className="tp-stack" style={{ gap: 14 }}>
            <div className="tp-row" style={{ justifyContent: 'space-between' }}>
              <div><div className="tp-h3">{o.id}</div><div className="tp-cap">Solicitada em {o.req}/2026 · {o.why}</div></div>
              <StatusText>{S.ops[o.id]}</StatusText>
            </div>
            <div>
              <label className="tp-label" htmlFor="op-part">Tipo de peça</label>
              <select id="op-part" className="tp-select" disabled={done || travado} defaultValue={o.part}>
                {CATALOG.map((c) => <option key={c[0]}>{c[0]}</option>)}
              </select>
            </div>
            <div className="tp-grid" style={{ gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div><label className="tp-label" htmlFor="op-qty">Quantidade</label><input id="op-qty" className="tp-input num" type="number" defaultValue={o.q} disabled={done || travado} /></div>
              <div><label className="tp-label" htmlFor="op-lote">Lote de matéria-prima</label><input id="op-lote" className="tp-input" defaultValue={o.id === 'OP-3310' ? 'LT-2026-088' : 'LT-2026-091'} disabled={done || travado} /></div>
            </div>
            {done ? (
              <Banner tone="ok" icon="circle-check" title="Lote liberado para etiquetagem">{o.id === 'OP-3310' ? 'Bruno Lima já vê o OP-3310 no app.' : 'Disponível para a produção.'}</Banner>
            ) : (
              <Banner tone="info" icon="info" title="Ao liberar">O lote aparece no app do operador de produção para etiquetar.</Banner>
            )}
            <Button block icon={done ? 'check' : 'send'} disabled={done} onClick={() => act('releaseOp')}>{done ? 'Lote liberado' : 'Liberar Lote para Etiquetagem'}</Button>
          </div>
        </Card>
      </Col>
    </div>
  );
}

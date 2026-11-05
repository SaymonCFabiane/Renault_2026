import { useDemo } from '../../state/useDemo.js';
import { kitAvail, kitItems, kitParcial, kitPrio, kitProto, kitStatus } from '../../state/logic.js';
import Card from '../../components/Card.jsx';
import Banner from '../../components/Banner.jsx';
import Button from '../../components/Button.jsx';
import { PrioTag, Tag } from '../../components/CriticalityTag.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import StatusText from '../../components/StatusText.jsx';
import Icon from '../../components/Icon.jsx';

// E-ADM2 · Pedidos de Kits e Atribuição
// Defeito 2: tabela compacta (layout fixo) que cabe no card a 1440px, sem rolagem horizontal.
export default function PedidosKits() {
  const { S, act } = useDemo();
  const q = S.queue;
  return (
    <div className="tp-stack">
      <Banner tone="bad" icon="lock" title="KT-0139 travado">Falta Pinça de freio traseira (BLOCANTE). A coleta só pode ser disparada quando a OP-3308 chegar da MetalSul.</Banner>
      <Card title="Pedidos de kits do Cliente" extra={<span className="tp-cap">Solicitados por Juliana Costa · Cliente</span>}>
        <DataTable compact head={<>
          <th style={{ width: 64 }}>Fila</th>
          <SortTh>Kit</SortTh>
          <SortTh width={150}>Peças</SortTh>
          <SortTh width={130}>Prioridade</SortTh>
          <th style={{ width: 150 }}>Responsável</th>
          <SortTh width={118}>Status</SortTh>
          <th style={{ width: 228 }}><span className="tp-sr">Ação</span></th>
        </>}>
          {q.map((k, i) => {
            const items = kitItems(S, k), hasB = items.some((x) => x[2]), stt = kitStatus(S, k), av = kitAvail(k);
            const canGo = S.kits[k] === 'Aguardando Separação' && av !== 'Indisponível';
            return (
              <tr key={k}>
                <td>
                  <div className="tp-fila">
                    <span className="tp-fila__pos">{i + 1}º</span>
                    <span className="tp-fila__arrows">
                      <button type="button" className="tp-icon-btn" disabled={i === 0} aria-label={`Subir ${k} na fila`} onClick={() => act('prio', { k, d: -1 })}><Icon name="arrow-up" /></button>
                      <button type="button" className="tp-icon-btn" disabled={i === q.length - 1} aria-label={`Descer ${k} na fila`} onClick={() => act('prio', { k, d: 1 })}><Icon name="arrow-down" /></button>
                    </span>
                  </div>
                </td>
                <td className="tp-kit-cell"><b>{k}</b><span className="tp-cap" title={kitProto(S, k)}>{kitProto(S, k)}</span></td>
                <td>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'flex-start' }}>
                    <span>{items.length} itens · <StatusText>{av}</StatusText></span>
                    {hasB && <Tag tone="blocante" icon="lock">Contém BLOCANTE</Tag>}
                    {kitParcial(S, k) ? <Tag tone="info">ACEITA PARCIAL</Tag> : <Tag tone="nao">SÓ COMPLETO</Tag>}
                  </div>
                </td>
                <td><PrioTag prio={kitPrio(S, k)} /></td>
                <td>
                  <select className="tp-select" style={{ height: 36 }} aria-label={`Responsável por ${k}`} value={S.assignee[k] || ''} onChange={(e) => act('assign', { k, name: e.target.value })}>
                    <option value="">Selecionar…</option>
                    {['Marcos Souza', 'Diego Martins'].map((n) => <option key={n}>{n}</option>)}
                  </select>
                </td>
                <td><StatusText>{stt}</StatusText></td>
                <td>
                  {stt === 'Travado' ? (
                    <Button variant="outline" size="sm" icon="lock" disabled>Travado</Button>
                  ) : canGo ? (
                    <Button size="sm" icon="send" onClick={() => act('dispatch', k)}>Disparar Ordem de Coleta</Button>
                  ) : (
                    <span className="tp-cap">Coleta disparada</span>
                  )}
                </td>
              </tr>
            );
          })}
        </DataTable>
      </Card>
    </div>
  );
}

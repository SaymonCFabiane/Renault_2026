import { KANBAN_COLS } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import { allKits, kitItems, kitParcial, kitPrio, kitProto, kitStatus } from '../../state/logic.js';
import Card from '../../components/Card.jsx';
import Banner from '../../components/Banner.jsx';
import CriticalityTag, { PrioTag, Tag } from '../../components/CriticalityTag.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import Drawer from '../../components/Drawer.jsx';
import StatusText from '../../components/StatusText.jsx';
import { Segmented } from '../../components/Tabs.jsx';

function KitDrawer({ S, act }) {
  const k = S.ksel, items = kitItems(S, k), delivered = /Entregue/.test(S.kits[k]);
  return (
    <Drawer label={`Detalhes do ${k}`} onClose={() => act('closeDrawer')} head={<>
      <div className="tp-h2">{k}</div>
      <div className="tp-cap">{kitProto(S, k)}</div>
      <div className="tp-row" style={{ gap: 8, marginTop: 8 }}><PrioTag prio={kitPrio(S, k)} />{kitParcial(S, k) ? <Tag tone="info">ACEITA PARCIAL</Tag> : <Tag tone="nao">SÓ COMPLETO</Tag>}<StatusText>{kitStatus(S, k)}</StatusText></div>
    </>}>
      {k === 'KT-0142' && (
        <Banner tone="warn" icon="circle-alert" title="Peça pendente: Farol LED esquerdo">
          NÃO-BLOCANTE · envio parcial autorizado. Reposição na OP-3310 (MetalSul, {S.ops['OP-3310'] === 'Pendente' ? 'aguardando liberação' : 'em produção'}).
        </Banner>
      )}
      {k === 'KT-0139' && <Banner tone="bad" icon="lock" title="Coleta travada">Falta Pinça de freio traseira (BLOCANTE). O teste de frenagem não pode começar sem ela.</Banner>}
      <div className="tp-h3">Peças do kit</div>
      {items.map((it) => (
        <div key={it[0]} className="tp-result" style={it[3] === 'miss' ? { background: `var(--${it[2] ? 'danger' : 'warning'}-bg)`, borderColor: 'transparent' } : undefined}>
          <div className="t">
            <b>{it[0]} <span className="num tp-muted">×{it[1]}</span></b>
            <div style={{ marginTop: 4 }}><CriticalityTag blocante={it[2]} /></div>
          </div>
          {it[3] === 'miss' ? <StatusText tone={it[2] ? 'bad' : 'warn'}>Em falta</StatusText>
            : delivered ? <StatusText tone="ok" icon="check">Entregue</StatusText>
            : <StatusText tone="muted">Separação</StatusText>}
        </div>
      ))}
      {k === 'KT-0142' && <div className="tp-cap">Pedido em 24/09 às 10:40 · Solicitante: Juliana Costa</div>}
    </Drawer>
  );
}

// T-ADM3 · Acompanhamento de Kits
export default function AcompanhamentoKits() {
  const { S, act } = useDemo();
  const kits = allKits(S);
  const board = S.kview === 'kanban' ? (
    <div className="tp-kanban">
      {KANBAN_COLS.map((c) => {
        const ks = kits.filter((k) => S.kits[k] === c);
        return (
          <div key={c} className="tp-kcol">
            <div className="tp-kcol__head"><span>{c}</span><span className="tp-tag tp-tag--info">{ks.length}</span></div>
            {ks.length ? ks.map((k) => {
              const items = kitItems(S, k);
              return (
                <button key={k} type="button" className={`tp-kcard${S.ksel === k && S.drawer ? ' on' : ''}`} onClick={() => act('openKit', k)}>
                  <div className="tp-row" style={{ justifyContent: 'space-between', width: '100%' }}><b>{k}</b><PrioTag prio={kitPrio(S, k)} /></div>
                  <span className="tp-cap">{kitProto(S, k)}</span>
                  <div className="tp-row" style={{ gap: 6 }}>
                    {k === 'KT-0139' && <Tag tone="blocante" icon="lock">TRAVADO</Tag>}
                    {items.some((x) => x[3] === 'miss') && k !== 'KT-0139' && <Tag tone="warn">PARCIAL</Tag>}
                    {items.some((x) => x[2]) && <Tag tone="nao">{items.length} itens · c/ blocante</Tag>}
                  </div>
                </button>
              );
            }) : <div className="tp-cap" style={{ textAlign: 'center', padding: '16px 0' }}>Nenhum kit</div>}
          </div>
        );
      })}
    </div>
  ) : (
    <DataTable head={<><SortTh>Kit</SortTh><SortTh>Protótipo</SortTh><SortTh>Prioridade</SortTh><SortTh>Etapa</SortTh></>}>
      {kits.map((k) => (
        <tr key={k} className={`is-clickable${S.ksel === k && S.drawer ? ' is-selected' : ''}`} onClick={() => act('openKit', k)}>
          <td><b>{k}</b></td><td>{kitProto(S, k)}</td><td><PrioTag prio={kitPrio(S, k)} /></td><td><StatusText>{kitStatus(S, k)}</StatusText></td>
        </tr>
      ))}
    </DataTable>
  );
  return (
    <>
      <Card title="Acompanhamento de kits" extra={
        <Segmented label="Visualização" value={S.kview} onChange={(v) => act('kview', v)}
          items={[{ value: 'kanban', label: 'Kanban', icon: 'square-kanban' }, { value: 'table', label: 'Tabela', icon: 'table' }]} />
      }>
        {board}
      </Card>
      {S.drawer && <KitDrawer S={S} act={act} />}
    </>
  );
}

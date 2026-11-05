import { PROTOS } from '../../data/mock.js';
import { useIrPara } from '../../state/somenteLeitura.js';
import { useDemo } from '../../state/useDemo.js';
import { kitPrio, kitProto, kitStatus } from '../../state/logic.js';
import Card, { Col } from '../../components/Card.jsx';
import Button from '../../components/Button.jsx';
import { PrioTag } from '../../components/CriticalityTag.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import StatusText from '../../components/StatusText.jsx';
import Icon from '../../components/Icon.jsx';
import LineChart from '../../components/charts/LineChart.jsx';
import Gauge from '../../components/charts/Gauge.jsx';

// T-ADM1 · Painel do Cliente
export default function Dashboard() {
  const { S, act } = useDemo();
  const ir = useIrPara();
  const cards = [
    ['hatch', 'circle-check', 'ok', 'Pronto para Teste', 'KT-0138 entregue completo em 24/09'],
    ['suv', 'timer', 'data', 'Em Montagem', `KT-0142 · ${S.kits['KT-0142']}`],
    ['pickup', 'lock', 'danger', 'Parado por Peça Blocante', 'KT-0139 · falta Pinça de freio traseira'],
  ];
  const kits = ['KT-0142', 'KT-0139', 'KT-0145', ...S.extraKits.map((x) => x.id)];
  const openKit = (k) => { act('openKit', k); ir('T-ADM3'); };
  return (
    <div className="tp-grid">
      {cards.map(([id, icon, v, sts, sub]) => (
        <Col key={id} span={4}>
          <section className="tp-card" style={{ display: 'flex', gap: 16, alignItems: 'flex-start', boxShadow: v === 'danger' ? 'inset 0 0 0 1.5px var(--danger)' : undefined }}>
            <div className={`tp-iconbox${v === 'data' ? ' tp-iconbox--data' : v === 'danger' ? ' tp-iconbox--danger' : ''}`}><Icon name={icon} /></div>
            <div style={{ minWidth: 0 }}>
              <div className="tp-cap" style={{ fontWeight: 700 }}>{PROTOS[id].name}</div>
              <div className={`tp-h2 tp-status--${v === 'ok' ? 'ok' : v === 'danger' ? 'bad' : 'info'}`} style={{ margin: '2px 0 4px' }}>{sts}</div>
              <div className="tp-cap">{sub}</div>
            </div>
          </section>
        </Col>
      ))}
      <Col span={4}>
        <Card title="SLA de entrega de kits">
          <Gauge value={86} split={0.8} label="Kits entregues no prazo pelo Estoque · Setembro" />
        </Card>
      </Col>
      <Col span={8}>
        <Card title="Taxa de falha e avaria de peças nos ensaios" extra={<span className="tp-cap">% de peças reprovadas por ensaio</span>}>
          <LineChart w={720} h={240} label="Taxa de falha por mês" labels={['Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set']} max={5} ticks={[0, 1, 2, 3, 4, 5]} fmt={(v) => v + '%'}
            series={[{ vals: [3.2, 2.8, 4.1, 3.5, 2.6, 2.9], color: 'var(--data)', fill: true, dots: true }]}
            marks={[{ i: 2, s: 0, label: '4,1% · pico', color: 'var(--accent-text)' }]} />
        </Card>
      </Col>
      <Col span={12}>
        <Card title="Kits em andamento" extra={<Button variant="outline" size="sm" consulta onClick={() => ir('T-ADM3')}>Ver acompanhamento</Button>}>
          <DataTable head={<><SortTh>Kit</SortTh><SortTh>Protótipo</SortTh><SortTh>Prioridade</SortTh><SortTh>Status</SortTh></>}>
            {kits.map((k) => (
              <tr key={k} className="is-clickable" onClick={() => openKit(k)}>
                <td><b>{k}</b></td><td>{kitProto(S, k)}</td><td><PrioTag prio={kitPrio(S, k)} /></td><td><StatusText>{kitStatus(S, k)}</StatusText></td>
              </tr>
            ))}
          </DataTable>
        </Card>
      </Col>
    </div>
  );
}

import { useNavigate } from 'react-router-dom';
import { PATHS, PROTOS } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import Card, { Col } from '../../components/Card.jsx';
import Button from '../../components/Button.jsx';
import CriticalityTag, { PrioTag } from '../../components/CriticalityTag.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import StatusText from '../../components/StatusText.jsx';
import Icon from '../../components/Icon.jsx';
import LineChart from '../../components/charts/LineChart.jsx';
import Gauge from '../../components/charts/Gauge.jsx';
import Legend from '../../components/charts/Legend.jsx';

function CriticalKit({ tone, title, locked, proto, part, blocante, note }) {
  return (
    <div className={`tp-banner tp-banner--${tone}`} style={{ flexDirection: 'column', gap: 8 }}>
      <div className="tp-row" style={{ justifyContent: 'space-between', width: '100%' }}>
        <b className="tp-row" style={{ gap: 6 }}>{locked && <Icon name="lock" />}{title}</b>
        <PrioTag prio="Alta" />
      </div>
      <p style={{ margin: 0 }}>{proto}</p>
      <div className="tp-row" style={{ gap: 8 }}><span style={{ color: 'var(--text)', fontWeight: 600 }}>Falta: {part}</span><CriticalityTag blocante={blocante} /></div>
      <p style={{ margin: 0 }} className="tp-cap">{note}</p>
    </div>
  );
}

// E-ADM1 · Painel do Estoque
export default function Dashboard() {
  const { S } = useDemo();
  const navigate = useNavigate();
  const farol = S.mn0457 === 'Recebido' ? 7 : 0;
  const alerts = [['Pinça de freio traseira', 0, 4, true], ['Farol LED esquerdo', farol, 2, false], ['Amortecedor traseiro', 3, 6, false], ['Módulo de ECU', 2, 3, true], ['Sensor de estacionamento', 5, 8, false]];
  return (
    <div className="tp-grid">
      <Col span={8}>
        <Card title="Nível de estoque" extra={<Legend items={[['var(--data)', 'Peças totais'], ['var(--accent)', 'Reservadas para kits']]} />}>
          <LineChart w={720} h={260} label="Nível de estoque de abril a setembro" labels={['Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set']} max={2500} ticks={[0, 500, 1000, 1500, 2000, 2500]} fmt={(v) => v.toLocaleString('pt-BR')} vgrid
            series={[{ vals: [1840, 1910, 1780, 2050, 1990, 2120], color: 'var(--data)', fill: true, dots: true }, { vals: [420, 510, 460, 630, 580, 700], color: 'var(--accent)', dots: true }]}
            marks={[{ i: 5, s: 1, label: '700 reservadas', color: 'var(--accent-text)' }]} />
        </Card>
      </Col>
      <Col span={4}>
        <Card title="Kits críticos">
          <div className="tp-stack" style={{ gap: 12 }}>
            <CriticalKit tone="bad" locked title="KT-0139" proto={PROTOS.pickup.name} part="Pinça de freio traseira" blocante note="Coleta travada · Reposição na OP-3308 (MetalSul)" />
            <CriticalKit tone="warn" title="KT-0142 · parcial" proto={PROTOS.suv.name} part="Farol LED esquerdo" blocante={false} note="Envio parcial autorizado por Juliana Costa" />
            <Button variant="outline" onClick={() => navigate(PATHS['E-ADM2'])}>Abrir pedidos de kits</Button>
          </div>
        </Card>
      </Col>
      <Col span={3}>
        <Card title="Tempo médio de montagem">
          <Gauge value={42} max={60} unit=" min" split={0.75} c1="var(--success)" c2="var(--accent)" label="Meta: até 45 min por kit" />
        </Card>
      </Col>
      <Col span={3}>
        <Card title="Acuracidade do inventário">
          <Gauge value={97.8} split={0.9} label="Último inventário cíclico: 23/09" />
        </Card>
      </Col>
      <Col span={6}>
        <Card title="Alertas de estoque mínimo">
          <DataTable head={<><SortTh>Peça</SortTh><SortTh align="right">Em estoque</SortTh><SortTh align="right">Mínimo</SortTh><SortTh>Situação</SortTh></>}>
            {alerts.map((a) => (
              <tr key={a[0]}>
                <td><div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'flex-start' }}><b>{a[0]}</b><CriticalityTag blocante={a[3]} /></div></td>
                <td className="num" style={{ textAlign: 'right' }}>{a[1]}</td>
                <td className="num" style={{ textAlign: 'right' }}>{a[2]}</td>
                <td>{a[1] === 0 ? <StatusText>Zerado · Indisponível</StatusText> : a[1] < a[2] ? <StatusText tone="warn">Abaixo do mínimo</StatusText> : <StatusText>OK</StatusText>}</td>
              </tr>
            ))}
          </DataTable>
        </Card>
      </Col>
    </div>
  );
}

import { useIrPara } from '../../state/somenteLeitura.js';
import { useDemo } from '../../state/useDemo.js';
import { lotesQualidade, loadOk } from '../../state/logic.js';
import Card, { Col } from '../../components/Card.jsx';
import KpiCard from '../../components/KpiCard.jsx';
import Banner from '../../components/Banner.jsx';
import Button from '../../components/Button.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import StatusText from '../../components/StatusText.jsx';
import Icon from '../../components/Icon.jsx';
import LineChart from '../../components/charts/LineChart.jsx';
import Legend from '../../components/charts/Legend.jsx';

// F-ADM1 · Painel do Fornecedor
export default function Dashboard() {
  const { S } = useDemo();
  const ir = useIrPara();
  const pend = Object.values(S.ops).filter((v) => v === 'Pendente').length;
  const trans = 2 + (S.mn0457 === 'Em Trânsito' ? 1 : 0);
  const lidas = loadOk(S).length;
  const lotesQ = lotesQualidade(S);
  const devol = S.qualidade.devolucoes;
  const reposicoes = S.opsExtras;
  const rows = [
    ...devol.map((d) => [d.id, `Devolução · ${d.peca} ×${d.qtd} (reprovadas na ${d.remessa})`, d.data.slice(0, 5), d.status, 'MetalSul Autopeças']),
    ['MN-0457', 'Farol LED esquerdo ×' + lidas, '25/09', S.mn0457, 'Doca 2 · Montadora'],
    ['MN-0455', 'Suporte do motor ×8', '24/09', 'Em Trânsito', 'Doca 1 · Montadora'],
    ['MN-0453', 'Chicote elétrico do painel ×5', '23/09', 'Em Trânsito', 'Doca 1 · Montadora'],
    ['MN-0451', 'Pinça de freio dianteira ×6 · Amortecedor traseiro ×4', '22/09', 'Com Problema', 'Doca 2 · Montadora'],
    ['MN-0449', 'Suporte do motor ×50 · 20 reprovadas na inspeção', '21/09', 'Com Problema', 'Doca 1 · Montadora'],
    ['MN-0448', 'Módulo de ECU ×3', '19/09', 'Recebido', 'Doca 1 · Montadora'],
  ];
  return (
    <div className="tp-grid">
      <Col span={12}>
        <Card title="Visão geral">
          <div className="tp-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
            <KpiCard icon="clipboard-list" value={pend} label="Ordens pendentes" />
            <KpiCard icon="package-check" value={18} label="Ordens concluídas no mês" />
            <KpiCard icon="truck" value={trans} label="Remessas em trânsito" />
            <KpiCard icon="triangle-alert" value={2 + lotesQ.length} label="Divergências" variant="alert" info />
          </div>
        </Card>
      </Col>
      <Col span={8}>
        <Card title="Ordens pendentes x concluídas" extra={<div className="tp-row"><Legend items={[['var(--data-alt)', 'Pendentes'], ['var(--success)', 'Concluídas']]} /><span className="tp-cap">Últimas 6 semanas</span></div>}>
          <LineChart w={720} h={250} label="Ordens pendentes e concluídas por semana" labels={['Sem 34', 'Sem 35', 'Sem 36', 'Sem 37', 'Sem 38', 'Sem 39']} max={16} ticks={[0, 4, 8, 12, 16]}
            series={[{ vals: [6, 5, 7, 4, 5, pend + 3], color: 'var(--data-alt)', fill: true }, { vals: [8, 10, 9, 12, 11, 13], color: 'var(--success)', fill: true }]}
            marks={[{ i: 3, s: 1, label: 'Pico de entregas', color: 'var(--success)' }, { i: 2, s: 0, label: 'Mais pendências', color: 'var(--data-alt)' }]} />
        </Card>
      </Col>
      <Col span={4}>
        <Card title="Divergências abertas">
          <div className="tp-stack" style={{ gap: 12 }}>
            <Banner tone="bad" icon="triangle-alert" title="MN-0451 · Com Problema">1 amortecedor traseiro avariado, apontado por Marcos Souza (Estoque). Reposição na OP-3306.</Banner>
            {lotesQ.map((l) => {
              const pend = l.pecas.filter((p) => p.status === 'bloqueada').length;
              const dest = l.pecas.length - pend;
              return (
                <Banner key={l.remessa} tone={pend ? 'bad' : 'info'} icon="shield-alert" title={`${l.remessa} · ${l.pecas.length} ${l.pecas.length === 1 ? 'reprovada' : 'reprovadas'} na inspeção do Estoque`}>
                  {l.peca} ({Math.round((l.pecas.length / l.recebidas) * 100)}% da carga). {pend ? `${pend} ${pend === 1 ? 'bloqueada' : 'bloqueadas'} aguardando decisão do Estoque` : ''}{pend && dest ? '; ' : ''}{dest ? `${dest} já com destino definido` : ''}.
                </Banner>
              );
            })}
            {reposicoes.length > 0 && (
              <Banner tone="info" icon="clipboard-list" title={`${reposicoes.length} ordem(ns) de reposição pedida(s) pelo Estoque`}>
                {reposicoes.map((o) => `${o.id}: ${o.part} ×${o.q}`).join(' · ')}. Veja em Ordens de Produção.
              </Banner>
            )}
            <Banner tone="warn" icon="circle-alert" title={`MN-0457 · ${lidas} de 10 peças`}>{10 - lidas} etiquetas não foram bipadas no carregamento.</Banner>
            <Button variant="outline" consulta onClick={() => ir('F-ADM3')}>Ver conferência da MN-0457</Button>
          </div>
        </Card>
      </Col>
      <Col span={12}>
        <Card title="Últimas remessas" extra={<div className="tp-row"><span className="tp-date"><Icon name="calendar" />19-09-2026</span><span className="tp-muted">até</span><span className="tp-date"><Icon name="calendar" />25-09-2026</span></div>}>
          <DataTable head={<><SortTh>Remessa</SortTh><SortTh>Conteúdo</SortTh><SortTh>Saída</SortTh><SortTh>Destino</SortTh><SortTh>Status</SortTh></>}>
            {rows.map((r) => (
              <tr key={r[0]} className={r[0] === 'MN-0457' ? 'is-clickable' : undefined} onClick={r[0] === 'MN-0457' ? () => ir('F-ADM3') : undefined}>
                <td><b>{r[0]}</b></td><td>{r[1]}</td><td className="num">{r[2]}</td><td>{r[4]}</td><td><StatusText>{r[3]}</StatusText></td>
              </tr>
            ))}
          </DataTable>
        </Card>
      </Col>
    </div>
  );
}

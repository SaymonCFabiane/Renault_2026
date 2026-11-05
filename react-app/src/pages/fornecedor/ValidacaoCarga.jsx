import { useDemo } from '../../state/useDemo.js';
import { loadOk } from '../../state/logic.js';
import Card, { Col, Stat } from '../../components/Card.jsx';
import Banner from '../../components/Banner.jsx';
import Button from '../../components/Button.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import StatusText from '../../components/StatusText.jsx';
import Icon from '../../components/Icon.jsx';
import { useLeitura } from '../../state/somenteLeitura.js';

const ALL = Array.from({ length: 10 }, (_, i) => 'PC-0002' + String(i + 1).padStart(2, '0'));

// F-ADM3 · Validação e Liberação de Carga (MN-0457)
export default function ValidacaoCarga() {
  const { S, act } = useDemo();
  const leitura = useLeitura();
  const ok = loadOk(S);
  const dup = S.load.reads.filter((r) => !r.ok);
  const s = S.mn0457, pending = s === 'Em Conferência', approved = s === 'Em Trânsito' || s === 'Recebido';
  return (
    <div className="tp-grid">
      <Col span={12}>
        <Card title="Carga MN-0457 · Farol LED esquerdo" extra={<StatusText>{s}</StatusText>}>
          <div className="tp-cap" style={{ marginTop: -12, marginBottom: 16 }}>OP-3310 · Lote LT-2026-088 · Conferida por Bruno Lima · Destino: Doca 2 da Montadora</div>
          {pending && (
            <div className="tp-banner tp-banner--info" style={{ marginBottom: 16 }}>
              <Icon name="scan-barcode" />
              <div><b>Conferência em andamento no app</b>
                <p>Bruno Lima bipou {ok.length} de 10 peças. A expedição fica bloqueada até ele enviar a conferência.{' '}
                  {!leitura && <button type="button" className="tp-link" onClick={() => act('simSend')}>Simular envio do operador</button>}</p>
              </div>
            </div>
          )}
          {approved && (
            <Banner tone="ok" icon="truck" title="Expedição autorizada" style={{ marginBottom: 16 }}>
              A carga saiu com {ok.length} peças. {s === 'Recebido' ? 'Recebida pela Montadora.' : 'O Estoque vê a MN-0457 na fila de recebimentos.'}
            </Banner>
          )}
          <div className="tp-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
            <Stat value={10} label="Esperadas" />
            <Stat value={ok.length} label="Lidas" tone="ok" />
            <Stat value={10 - ok.length} label="Faltaram" tone="bad" />
            <Stat value={dup.length} label="Leituras repetidas" tone="warn" />
          </div>
        </Card>
      </Col>
      <Col span={8}>
        <Card title="Conferência peça a peça">
          <DataTable head={<><SortTh>Etiqueta</SortTh><SortTh>Numeração</SortTh><SortTh>Leitura</SortTh><SortTh>Situação</SortTh></>}>
            {ALL.map((c, i) => {
              const r = S.load.reads.find((x) => x.c === c && x.ok);
              return (
                <tr key={c} className={r ? undefined : 'is-bad'}>
                  <td><b className="num">{c}</b></td>
                  <td>Peça {String(i + 1).padStart(2, '0')}/10</td>
                  <td className="num">{r ? '25/09 · ' + r.t : '—'}</td>
                  <td>{r ? <StatusText tone="ok" icon="circle-check">Lida</StatusText> : <StatusText tone="bad" icon="circle-x">Faltou</StatusText>}</td>
                </tr>
              );
            })}
            {dup.map((d) => (
              <tr key={'dup' + d.t} className="is-warn">
                <td><b className="num">{d.c}</b></td><td>Leitura repetida</td><td className="num">25/09 · {d.t}</td>
                <td><StatusText tone="warn" icon="triangle-alert">Ignorada</StatusText></td>
              </tr>
            ))}
          </DataTable>
        </Card>
      </Col>
      <Col span={4}>
        <Card title="Divergências">
          <div className="tp-stack" style={{ gap: 12 }}>
            {10 - ok.length > 0 && <Banner tone="bad" icon="circle-x" title={`Faltaram ${10 - ok.length} peças`}>{ALL.filter((c) => !ok.includes(c)).join(', ')}</Banner>}
            {dup.length > 0 && <Banner tone="warn" icon="triangle-alert" title={`${dup.length} leitura repetida`}>{dup.map((d) => d.c).join(', ')} foi bipada duas vezes. A segunda leitura não conta.</Banner>}
            <Banner tone="info" icon="info" title="Sobraram 0 peças">Nenhuma etiqueta de fora da OP-3310 foi lida.</Banner>
            <Button block icon={approved ? 'check' : 'truck'} disabled={pending || approved} onClick={() => act('authorize')}>{approved ? 'Expedição autorizada' : 'Autorizar Expedição'}</Button>
            {pending && <div className="tp-cap tp-row" style={{ justifyContent: 'center', gap: 6 }}><Icon name="lock" />Aguardando envio da conferência</div>}
            {!pending && !approved && <Button variant="ghost" block onClick={() => act('returnLoad')}>Devolver para nova conferência</Button>}
          </div>
        </Card>
      </Col>
    </div>
  );
}

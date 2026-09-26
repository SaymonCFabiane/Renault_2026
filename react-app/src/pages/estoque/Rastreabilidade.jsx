import { useState } from 'react';
import { PROTOS } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import { loadOk } from '../../state/logic.js';
import Card, { Col } from '../../components/Card.jsx';
import Button from '../../components/Button.jsx';
import CriticalityTag from '../../components/CriticalityTag.jsx';
import DataTable, { SortTh } from '../../components/DataTable.jsx';
import SearchField from '../../components/SearchField.jsx';
import StatusText from '../../components/StatusText.jsx';
import Timeline from '../../components/Timeline.jsx';
import QrCode from '../../components/QrCode.jsx';
import { EmptyState } from '../../components/Banner.jsx';
import { Segmented } from '../../components/Tabs.jsx';

function traceResult(S, raw) {
  const q = raw.trim().toUpperCase();
  if (q === 'PC-000098') return {
    title: 'PC-000098 · Pinça de freio dianteira', sub: 'Kit KT-0142 · ' + PROTOS.suv.name, b: true, steps: [
      ['factory', '22/09 08:14', 'Saiu da MetalSul Autopeças', 'Carga MN-0451 · Carla Mendes'],
      ['package-check', '22/09 14:02', 'Recebida na doca', 'Marcos Souza · Estoque'],
      ['map-pin', '22/09 14:20', 'Guardada', 'Corredor A · Prateleira 02 · Caixa 04'],
      ['boxes', '24/09 10:37', 'Inserida no kit KT-0142', 'Marcos Souza · Coleta'],
      ['car', 'Destino', 'Protótipo SUV X – Teste de Pista', 'Juliana Costa · Testes'],
    ],
  };
  const m = q.match(/^PC-0002(0[1-9]|10)$/);
  if (m) {
    const n = +m[1], read = loadOk(S).includes(q), st = S.mn0457;
    const steps = [['factory', '24/09 09:30', 'Fabricada no lote LT-2026-088', `OP-3310 · Peça ${String(n).padStart(2, '0')}/10`], ['tag', '25/09 14:05', 'Etiqueta impressa', 'Bruno Lima · Fornecedor']];
    if (read) steps.push(['scan-barcode', '25/09 16:3' + (n % 10), 'Bipada no carregamento da MN-0457', 'Bruno Lima']);
    else steps.push(['circle-x', '25/09', 'Não bipada no carregamento', 'Divergência na MN-0457']);
    if (read && (st === 'Em Trânsito' || st === 'Recebido')) steps.push(['truck', '25/09 17:02', 'Expedição autorizada', 'Carla Mendes']);
    if (read && st === 'Recebido') steps.push(['map-pin', '25/09 17:48', 'Recebida e guardada', 'Corredor D · Prateleira 05 · Nível 2 · Caixa 03']);
    return { title: q + ' · Farol LED esquerdo', sub: 'Reposição do KT-0142', b: false, steps };
  }
  if (q === 'LT-2026-088') return { lot: true };
  return null;
}

// E-ADM4 · Rastreabilidade
export default function Rastreabilidade() {
  const { S, act } = useDemo();
  const t = S.trace;
  const [draft, setDraft] = useState(t.q);
  const [shown, setShown] = useState(t.q);
  if (shown !== t.q) { setShown(t.q); setDraft(t.q); }
  const r = traceResult(S, t.q);
  const ok = loadOk(S);
  let res;
  if (!r) {
    res = <EmptyState icon="package-search" title={`Nenhum resultado para “${t.q}”`}>Tente PC-000098, PC-000205 ou o lote LT-2026-088.</EmptyState>;
  } else if (r.lot) {
    res = (
      <>
        <div className="tp-h3" style={{ marginBottom: 12 }}>Lote LT-2026-088 · 10 peças · fabricado em 24/09/2026</div>
        <DataTable head={<><SortTh>Etiqueta</SortTh><SortTh>Peça</SortTh><SortTh>Numeração</SortTh><SortTh>Situação</SortTh></>}>
          {Array.from({ length: 10 }, (_, i) => {
            const c = 'PC-0002' + String(i + 1).padStart(2, '0');
            return (
              <tr key={c} className="is-clickable" onClick={() => act('trace', c)}>
                <td><b className="num">{c}</b></td><td>Farol LED esquerdo</td><td>Peça {String(i + 1).padStart(2, '0')}/10</td>
                <td>{ok.includes(c) ? <StatusText>{S.mn0457 === 'Recebido' ? 'Recebido' : 'Carregada'}</StatusText> : <StatusText>Faltou no carregamento</StatusText>}</td>
              </tr>
            );
          })}
        </DataTable>
      </>
    );
  } else {
    res = (
      <>
        <div className="tp-row" style={{ justifyContent: 'space-between', marginBottom: 20 }}>
          <div>
            <div className="tp-h2">{r.title}</div>
            <div className="tp-row" style={{ gap: 8, marginTop: 4 }}><CriticalityTag blocante={r.b} /><span className="tp-cap">{r.sub}</span></div>
          </div>
          <QrCode seed={t.q} size={72} />
        </div>
        <Timeline steps={r.steps} />
      </>
    );
  }
  return (
    <div className="tp-grid">
      <Col span={12}>
        <Card title="Rastreabilidade">
          <div className="tp-row" style={{ gap: 12 }}>
            <Segmented label="Buscar por" value={t.mode} onChange={(v) => act('traceMode', v)}
              items={[{ value: 'Código', label: 'Código', icon: 'tag' }, { value: 'QR Code', label: 'QR Code', icon: 'qr-code' }, { value: 'Lote', label: 'Lote', icon: 'layers' }]} />
            <SearchField id="trace-q" style={{ flex: 1, minWidth: 240 }} value={draft} onChange={setDraft} onSubmit={() => act('traceQuery', draft)}
              placeholder={t.mode === 'Lote' ? 'Ex.: LT-2026-088' : 'Ex.: PC-000098'} label="Código para rastrear" />
            {t.mode === 'QR Code' && <Button variant="secondary" icon="scan-line" onClick={() => act('trace', 'PC-000098')}>Simular leitura de QR</Button>}
          </div>
        </Card>
      </Col>
      <Col span={12}><section className="tp-card">{res}</section></Col>
    </div>
  );
}

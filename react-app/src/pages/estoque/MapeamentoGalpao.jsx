import { useState } from 'react';
import { CATALOG, KIT142 } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import Card, { Col } from '../../components/Card.jsx';
import Button from '../../components/Button.jsx';
import Icon from '../../components/Icon.jsx';
import Legend from '../../components/charts/Legend.jsx';

const ROWS = ['A', 'B', 'C', 'D', 'E'];
const USED = ['A1', 'A3', 'A5', 'B1', 'B2', 'B5', 'C2', 'C3', 'C6', 'D1', 'D5', 'D6', 'E2', 'E7'];
const HITS = KIT142.filter((i) => i.c).map((i) => i.c + i.s);
const pad = (n) => String(n).padStart(2, '0');

function Field({ id, label, value, options, onChange }) {
  return (
    <div>
      <label className="tp-label" htmlFor={id}>{label}</label>
      <select id={id} className="tp-select" value={value} onChange={(e) => onChange(e.target.value)}>
        {options.map((o) => <option key={o}>{o}</option>)}
      </select>
    </div>
  );
}

// E-ADM3 · Mapeamento do Galpão
export default function MapeamentoGalpao() {
  const { S, act } = useDemo();
  const m = S.map;
  const [part, setPart] = useState('Farol LED esquerdo');
  const set = (key) => (value) => act('map', { key, value });
  return (
    <div className="tp-grid">
      <Col span={4}>
        <Card title="Cadastrar endereço">
          <form className="tp-stack" style={{ gap: 14 }} onSubmit={(e) => { e.preventDefault(); act('saveMap', part); }}>
            <div className="tp-grid" style={{ gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <Field id="m-c" label="Corredor" value={m.c} options={ROWS} onChange={set('c')} />
              <Field id="m-s" label="Prateleira" value={m.s} options={[1, 2, 3, 4, 5, 6, 7, 8].map(pad)} onChange={set('s')} />
              <Field id="m-n" label="Nível" value={m.n} options={['1', '2', '3', '4']} onChange={set('n')} />
              <Field id="m-b" label="Caixa" value={m.b} options={[1, 2, 3, 4, 5, 6].map(pad)} onChange={set('b')} />
            </div>
            <Field id="m-p" label="Peça guardada" value={part} options={CATALOG.map((c) => c[0])} onChange={setPart} />
            <div className="tp-stat"><span>Endereço gerado</span><b style={{ fontSize: 18 }}>Corredor {m.c} · Prateleira {m.s} · Nível {m.n} · Caixa {m.b}</b></div>
            <Button type="submit" icon="check">Salvar endereço</Button>
          </form>
        </Card>
      </Col>
      <Col span={8}>
        <Card title="Planta do galpão">
          <div className="tp-map">
            <div className="tp-row tp-cap" style={{ fontWeight: 700, gap: 8 }}>
              <Icon name="route" />Entrada · Doca 1
              {ROWS.map((r, i) => (
                <span key={r} className="tp-row" style={{ gap: 6 }}><span className="tp-seq">{i + 1}</span>{r}{' →'}</span>
              ))}
              Doca de expedição
            </div>
            {ROWS.map((r, i) => (
              <div key={r} className="tp-aisle">
                <div className="tp-row" style={{ gap: 8, flexWrap: 'nowrap' }}><span className="tp-seq">{i + 1}</span><b>Corredor {r}</b></div>
                {Array.from({ length: 8 }, (_, j) => {
                  const id = r + (j + 1), sel = m.c === r && +m.s === j + 1;
                  return (
                    <div key={id} className={`tp-slot${HITS.includes(id) ? ' hit' : USED.includes(id) ? ' used' : ''}`} style={sel ? { outline: '3px solid var(--accent)', outlineOffset: 1 } : undefined}>
                      P{pad(j + 1)}
                    </div>
                  );
                })}
              </div>
            ))}
            <div className="tp-row" style={{ justifyContent: 'space-between' }}>
              <Legend items={[['var(--primary)', 'Rota do KT-0142'], ['var(--data-light)', 'Ocupada'], ['var(--surface-muted)', 'Livre'], ['var(--accent)', 'Endereço selecionado']]} />
              <span className="tp-cap">5 corredores · 8 prateleiras · 4 níveis</span>
            </div>
          </div>
        </Card>
      </Col>
    </div>
  );
}

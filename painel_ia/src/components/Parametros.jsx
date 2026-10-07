import { useState } from 'react';
import { rotulo } from '../rotulos.js';

/** Confiança, tamanho de entrada e filtro de classes (iguais aos da API). */
export default function Parametros({ valor, onChange, classes }) {
  const [busca, setBusca] = useState('');
  const lista = Object.entries(classes || {})
    .map(([id, nome]) => [Number(id), nome])
    .filter(([, nome]) => !busca || nome.includes(busca.toLowerCase()) || rotulo(nome).includes(busca.toLowerCase()));
  const sel = new Set(valor.classes || []);
  const alternar = (id) => {
    const n = new Set(sel);
    if (n.has(id)) n.delete(id); else n.add(id);
    onChange({ ...valor, classes: [...n].sort((a, b) => a - b) });
  };
  return (
    <div className="tp-stack" style={{ gap: 16 }}>
      <div>
        <div className="tp-field-row">
          <label className="tp-label" htmlFor="p-conf">Confiança mínima</label>
          <output htmlFor="p-conf">{Math.round(valor.confianca * 100)}%</output>
        </div>
        <input id="p-conf" className="tp-range" type="range" min="0.05" max="0.95" step="0.05" value={valor.confianca}
          onChange={(e) => onChange({ ...valor, confianca: Number(e.target.value) })} />
      </div>
      <div>
        <label className="tp-label" htmlFor="p-imgsz">Tamanho de entrada (imgsz)</label>
        <select id="p-imgsz" className="tp-select" value={valor.imgsz} onChange={(e) => onChange({ ...valor, imgsz: Number(e.target.value) })}>
          {[320, 480, 640, 960].map((s) => <option key={s} value={s}>{s} px{s === 640 ? ' (padrão)' : ''}</option>)}
        </select>
      </div>
      <div>
        <div className="tp-field-row">
          <span className="tp-label">Classes</span>
          {sel.size > 0 && <button type="button" className="tp-link" style={{ fontSize: 12 }} onClick={() => onChange({ ...valor, classes: [] })}>Limpar ({sel.size})</button>}
        </div>
        <input className="tp-input" style={{ height: 36, marginBottom: 8 }} placeholder="Filtrar classes…" value={busca} onChange={(e) => setBusca(e.target.value)} aria-label="Filtrar classes" />
        <div className="tp-chips">
          {lista.map(([id, nome]) => (
            <button key={id} type="button" className={sel.has(id) ? 'on' : ''} aria-pressed={sel.has(id)} onClick={() => alternar(id)} title={`${id} · ${nome}`}>
              {rotulo(nome)}
            </button>
          ))}
        </div>
        <p className="tp-cap" style={{ margin: '6px 0 0' }}>{sel.size ? `Detectando só ${sel.size} classe${sel.size > 1 ? 's' : ''}.` : 'Nenhuma marcada: detecta todas.'}</p>
      </div>
    </div>
  );
}

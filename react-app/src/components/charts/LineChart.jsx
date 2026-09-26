import { useId } from 'react';
import { smooth } from './smooth.js';

// Linha suave com área em degradê e marcadores de destaque.
// series: [{ vals, color, fill, dots }] · marks: [{ i, s, label, color }]
export default function LineChart({ w = 640, h = 240, labels, series, max, ticks, fmt = (v) => v, marks = [], vgrid = false, label }) {
  const uid = useId().replace(/:/g, '');
  const L = 44, R = 16, T = 26, B = 28, iw = w - L - R, ih = h - T - B;
  const x = (i) => L + (iw * i) / (labels.length - 1);
  const y = (v) => T + ih * (1 - v / max);
  return (
    <svg className="tp-chart" viewBox={`0 0 ${w} ${h}`} role="img" aria-label={label}>
      {ticks.map((t) => (
        <g key={t}>
          <line className="grid" x1={L} x2={w - R} y1={y(t)} y2={y(t)} />
          <text x={L - 8} y={y(t) + 4} textAnchor="end">{fmt(t)}</text>
        </g>
      ))}
      {vgrid && labels.map((l, i) => <line key={l} className="grid" x1={x(i)} x2={x(i)} y1={T} y2={T + ih} />)}
      {labels.map((l, i) => <text key={l} x={x(i)} y={h - 8} textAnchor="middle">{l}</text>)}
      {series.map((se, si) => {
        const pts = se.vals.map((v, i) => [+x(i).toFixed(1), +y(v).toFixed(1)]);
        const d = smooth(pts);
        const gid = `g${uid}${si}`;
        return (
          <g key={si}>
            {se.fill && (
              <>
                <defs>
                  <linearGradient id={gid} x1="0" x2="0" y1="0" y2="1">
                    <stop offset="0" stopColor={se.color} stopOpacity=".35" />
                    <stop offset="1" stopColor={se.color} stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path d={`${d} L${pts.at(-1)[0]},${T + ih} L${pts[0][0]},${T + ih} Z`} fill={`url(#${gid})`} />
              </>
            )}
            <path d={d} fill="none" stroke={se.color} strokeWidth="2.5" strokeLinecap="round" />
            {se.dots && pts.map((p) => <circle key={p[0]} cx={p[0]} cy={p[1]} r="4.5" fill={se.color} stroke="var(--surface)" strokeWidth="2" />)}
          </g>
        );
      })}
      {marks.map((m) => {
        const px = x(m.i), py = y(series[m.s].vals[m.i]), tw = m.label.length * 6.2 + 16;
        return (
          <g key={m.label}>
            <circle cx={px} cy={py} r="5" fill={m.color} stroke="var(--surface)" strokeWidth="2" />
            <rect x={px - tw / 2} y={py - 32} width={tw} height="20" rx="4" fill={m.color} />
            <path d={`M${px - 5},${py - 12.5} L${px},${py - 7} L${px + 5},${py - 12.5}Z`} fill={m.color} />
            <text x={px} y={py - 18} textAnchor="middle" className="tp-mark-label">{m.label}</text>
          </g>
        );
      })}
    </svg>
  );
}

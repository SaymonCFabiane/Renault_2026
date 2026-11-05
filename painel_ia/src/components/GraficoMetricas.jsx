/** Linhas de métricas (0–1) por época: mAP50, mAP50-95 e precisão. */
const SERIES = [
  ['map50', 'Acerto (mAP50)', 'var(--success)'],
  ['map50_95', 'Precisão da caixa (mAP50-95)', 'var(--data)'],
  ['revocacao', 'Peças encontradas (revocação)', 'var(--data-alt)'],
];

export default function GraficoMetricas({ historico, epocas }) {
  const W = 640, H = 220, L = 36, R = 12, T = 12, B = 26;
  const iw = W - L - R, ih = H - T - B;
  const total = Math.max(epocas || 1, historico.length, 2);
  const x = (e) => L + (iw * (e - 1)) / (total - 1);
  const y = (v) => T + ih * (1 - v);
  return (
    <div>
      <svg className="tp-chart" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Métricas por época">
        {[0, 0.25, 0.5, 0.75, 1].map((t) => (
          <g key={t}>
            <line className="grid" x1={L} x2={W - R} y1={y(t)} y2={y(t)} />
            <text x={L - 6} y={y(t) + 4} textAnchor="end">{Math.round(t * 100)}%</text>
          </g>
        ))}
        {[1, Math.round(total / 2), total].map((e) => <text key={e} x={x(e)} y={H - 6} textAnchor="middle">{e}</text>)}
        {SERIES.map(([k, , cor]) => {
          const pts = historico.filter((h) => h[k] != null).map((h) => `${x(h.epoca)},${y(h[k])}`).join(' ');
          return pts && <polyline key={k} points={pts} fill="none" stroke={cor} strokeWidth="2.5" strokeLinejoin="round" />;
        })}
      </svg>
      <div className="tp-legend" style={{ marginTop: 6 }}>
        {SERIES.map(([k, rot, cor]) => <span key={k}><i style={{ background: cor }} />{rot}</span>)}
        <span>Eixo de baixo: época</span>
      </div>
    </div>
  );
}

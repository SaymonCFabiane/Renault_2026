// Gauge semicircular: trecho c1 até split, c2 depois; ponteiro no valor.
export default function Gauge({ value, w = 220, label = '', unit = '%', max = 100, split = 0.6, c1 = 'var(--data-alt)', c2 = 'var(--success)' }) {
  const cx = w / 2, cy = w * 0.52, r = w * 0.36, sw = w * 0.075;
  const pt = (a) => [cx + r * Math.cos(Math.PI * (1 - a)), cy - r * Math.sin(Math.PI * (1 - a))];
  const arc = (a0, a1, col) => {
    const [x0, y0] = pt(a0), [x1, y1] = pt(a1);
    return <path d={`M${x0.toFixed(1)},${y0.toFixed(1)} A${r},${r} 0 0 1 ${x1.toFixed(1)},${y1.toFixed(1)}`} fill="none" stroke={col} strokeWidth={sw} strokeLinecap="round" />;
  };
  const f = Math.min(value / max, 1);
  const nx = cx + (r - sw * 0.2) * Math.cos(Math.PI * (1 - f)), ny = cy - (r - sw * 0.2) * Math.sin(Math.PI * (1 - f));
  return (
    <>
      <svg className="tp-chart" viewBox={`0 0 ${w} ${w * 0.72}`} style={{ maxWidth: w, margin: 'auto' }} role="img" aria-label={`${String(value).replace('.', ',')}${unit}`}>
        {arc(0, split, c1)}
        {arc(split, 1, c2)}
        <line x1={cx} y1={cy} x2={nx.toFixed(1)} y2={ny.toFixed(1)} stroke="var(--text)" strokeWidth="4" strokeLinecap="round" />
        <circle cx={cx} cy={cy} r="8" fill="var(--surface)" stroke="var(--text)" strokeWidth="4" />
        <text x={cx - r} y={cy + 26} textAnchor="middle">0{unit}</text>
        <text x={cx + r} y={cy + 26} textAnchor="middle">{max}{unit}</text>
        <text x={cx} y={cy + 44} textAnchor="middle" style={{ fill: 'var(--text)', fontSize: 26, fontWeight: 800 }}>
          {String(value).replace('.', ',')}<tspan style={{ fontSize: 14 }}>{unit}</tspan>
        </text>
      </svg>
      {label && <div className="tp-cap" style={{ textAlign: 'center' }}>{label}</div>}
    </>
  );
}

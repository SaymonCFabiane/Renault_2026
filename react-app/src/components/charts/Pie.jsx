// Pizza com a fatia destacada deslocada (porta de pie() do protótipo).
export default function Pie({ a, b, la, lb }) {
  const cx = 90, cy = 90, r = 72, ang = (a / (a + b)) * 2 * Math.PI;
  const p = (t, rr = r, ox = 0, oy = 0) => [ox + cx + rr * Math.sin(t), oy + cy - rr * Math.cos(t)];
  const off = [8 * Math.sin(ang / 2), -8 * Math.cos(ang / 2)];
  const [x1, y1] = p(0, r, ...off), [x2, y2] = p(ang, r, ...off), [x3, y3] = p(ang), [x4, y4] = p(2 * Math.PI - 0.0001);
  const [lx, ly] = p(ang / 2, r * 0.6, ...off), [mx, my] = p(ang + (2 * Math.PI - ang) / 2, r * 0.55);
  return (
    <svg className="tp-chart" viewBox="0 0 180 180" style={{ maxWidth: 180 }} role="img" aria-label={`${la} e ${lb}`}>
      <path d={`M${cx},${cy} L${x3},${y3} A${r},${r} 0 ${ang < Math.PI ? 1 : 0} 1 ${x4},${y4} Z`} fill="var(--data)" />
      <path d={`M${cx + off[0]},${cy + off[1]} L${x1},${y1} A${r},${r} 0 ${ang > Math.PI ? 1 : 0} 1 ${x2},${y2} Z`} fill="var(--data-light)" />
      <text x={lx} y={ly + 5} textAnchor="middle" style={{ fill: '#1E2F38', fontWeight: 800, fontSize: 14 }}>{la}</text>
      <text x={mx} y={my + 5} textAnchor="middle" style={{ fill: '#fff', fontWeight: 800, fontSize: 14 }}>{lb}</text>
    </svg>
  );
}

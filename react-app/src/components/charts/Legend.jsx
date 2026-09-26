export default function Legend({ items }) {
  return (
    <div className="tp-legend">
      {items.map(([c, t]) => (
        <span key={t}><i style={{ background: c }} />{t}</span>
      ))}
    </div>
  );
}

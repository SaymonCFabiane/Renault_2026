export default function Card({ title, extra, children, style }) {
  return (
    <section className="tp-card" style={style}>
      {(title || extra) && (
        <div className="tp-card__head">
          {title && <h2 className="tp-h2">{title}</h2>}
          {extra}
        </div>
      )}
      {children}
    </section>
  );
}

// Coluna do grid de 12 colunas.
export function Col({ span, children }) {
  return <div style={{ gridColumn: `span ${span}`, minWidth: 0 }}>{children}</div>;
}

export function Stat({ value, label, tone, style }) {
  return (
    <div className={`tp-stat${tone ? ` tp-stat--${tone}` : ''}`}>
      <b style={style}>{value}</b>
      <span>{label}</span>
    </div>
  );
}

/** Abas com sublinhado terracota. items: [{ value, label, count }] */
export default function Tabs({ items, value, onChange, style }) {
  return (
    <div className="tp-tabs" role="tablist" style={style}>
      {items.map((t) => (
        <button key={t.value} type="button" role="tab" aria-selected={value === t.value} className={`tp-tab${value === t.value ? ' on' : ''}`} onClick={() => onChange(t.value)}>
          {t.label}
          {t.count != null && <span className="count">{t.count}</span>}
        </button>
      ))}
    </div>
  );
}

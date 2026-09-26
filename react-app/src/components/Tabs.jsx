import Icon from './Icon.jsx';

// Abas com sublinhado terracota. items: [{ value, label, count }]
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

// Controle segmentado. items: [{ value, label, icon }]
export function Segmented({ items, value, onChange, className = '', label }) {
  return (
    <div className={`tp-seg ${className}`} role="group" aria-label={label}>
      {items.map((t) => (
        <button key={t.value} type="button" data-v={t.value} aria-pressed={value === t.value} className={value === t.value ? 'on' : ''} onClick={() => onChange(t.value)}>
          {t.icon && <Icon name={t.icon} />}
          {t.label}
        </button>
      ))}
    </div>
  );
}

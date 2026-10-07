import Icon from './Icon.jsx';

export function Card({ title, extra, children, style }) {
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

export function Button({ variant = 'primary', size, block, icon, children, ...rest }) {
  const cls = ['tp-btn', `tp-btn--${variant}`, size && `tp-btn--${size}`, block && 'tp-btn--block'].filter(Boolean).join(' ');
  return (
    <button type="button" className={cls} {...rest}>
      {icon && <Icon name={icon} />}
      {children}
    </button>
  );
}

export function Banner({ tone = 'info', icon, title, children }) {
  return (
    <div className={`tp-banner tp-banner--${tone}`}>
      {icon && <Icon name={icon} />}
      <div>
        {title && <b>{title}</b>}
        {children && <p>{children}</p>}
      </div>
    </div>
  );
}

export function Stat({ value, label, tone }) {
  return (
    <div className={`tp-stat${tone ? ` tp-stat--${tone}` : ''}`}>
      <b>{value}</b>
      <span>{label}</span>
    </div>
  );
}

export function Segmented({ items, value, onChange, label }) {
  return (
    <div className="tp-seg" role="group" aria-label={label}>
      {items.map((t) => (
        <button key={t.value} type="button" aria-pressed={value === t.value} className={value === t.value ? 'on' : ''} onClick={() => onChange(t.value)}>
          {t.label}
        </button>
      ))}
    </div>
  );
}

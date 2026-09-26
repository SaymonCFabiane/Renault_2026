import Icon from './Icon.jsx';

// tone: ok | warn | bad | info
export default function Banner({ tone = 'info', icon, title, children, style }) {
  return (
    <div className={`tp-banner tp-banner--${tone}`} style={style}>
      {icon && <Icon name={icon} />}
      <div>
        {title && <b>{title}</b>}
        {children && <p>{children}</p>}
      </div>
    </div>
  );
}

export function EmptyState({ icon, title, children }) {
  return (
    <div className="tp-empty">
      <div className="ring"><Icon name={icon} /></div>
      <b>{title}</b>
      {children && <span>{children}</span>}
    </div>
  );
}

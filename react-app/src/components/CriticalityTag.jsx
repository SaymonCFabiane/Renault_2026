import Icon from './Icon.jsx';

export default function CriticalityTag({ blocante }) {
  return blocante ? (
    <span className="tp-tag tp-tag--blocante"><Icon name="lock" />BLOCANTE</span>
  ) : (
    <span className="tp-tag tp-tag--nao">NÃO-BLOCANTE</span>
  );
}

export function PrioTag({ prio }) {
  const cls = prio === 'Alta' ? 'tp-tag--blocante' : prio === 'Média' ? 'tp-tag--warn' : 'tp-tag--info';
  return <span className={`tp-tag ${cls}`}>{prio === 'Alta' ? 'ALTA / URGENTE' : prio.toUpperCase()}</span>;
}

export function Tag({ tone = 'info', icon, children }) {
  return <span className={`tp-tag tp-tag--${tone}`}>{icon && <Icon name={icon} />}{children}</span>;
}

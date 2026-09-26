import Icon from './Icon.jsx';

// variant: '' (success) | data | alert
export default function KpiCard({ icon, value, label, variant = '', info = false }) {
  const box = variant === 'alert' ? 'tp-iconbox--accent' : variant === 'data' ? 'tp-iconbox--data' : '';
  return (
    <div className={`tp-kpi${variant === 'alert' ? ' tp-kpi--alert' : ''}`}>
      <div className={`tp-iconbox ${box}`}><Icon name={icon} /></div>
      <div>
        <div className="tp-kpi__num">{value}</div>
        <div className="tp-kpi__label">{label}</div>
      </div>
      {info && <span className="tp-kpi__info" title="Detalhes"><Icon name="info" /></span>}
    </div>
  );
}

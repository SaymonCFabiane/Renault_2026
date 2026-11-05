import Icon from './Icon.jsx';
import { useLeitura } from '../state/somenteLeitura.js';

// Botão em pílula. variant: primary | secondary | outline | ghost | success | danger | accent
// Na visão de consulta (somente leitura) fica desabilitado, a não ser que seja só de navegação (`consulta`).
export default function Button({ variant = 'primary', size, block, icon, children, className = '', consulta, ...rest }) {
  const leitura = useLeitura();
  if (leitura && !consulta) Object.assign(rest, { disabled: true, title: `Somente leitura: ação de ${leitura.dono}` });
  const cls = ['tp-btn', `tp-btn--${variant}`, size && `tp-btn--${size}`, block && 'tp-btn--block', className].filter(Boolean).join(' ');
  return (
    <button type="button" className={cls} {...rest}>
      {icon && <Icon name={icon} />}
      {children}
    </button>
  );
}

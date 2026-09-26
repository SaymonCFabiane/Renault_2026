import Icon from './Icon.jsx';

// Botão em pílula. variant: primary | secondary | outline | ghost | success | danger | accent
export default function Button({ variant = 'primary', size, block, icon, children, className = '', ...rest }) {
  const cls = ['tp-btn', `tp-btn--${variant}`, size && `tp-btn--${size}`, block && 'tp-btn--block', className].filter(Boolean).join(' ');
  return (
    <button type="button" className={cls} {...rest}>
      {icon && <Icon name={icon} />}
      {children}
    </button>
  );
}

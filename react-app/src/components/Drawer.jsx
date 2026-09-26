import Icon from './Icon.jsx';

export default function Drawer({ label, head, onClose, children }) {
  return (
    <aside className="tp-drawer" aria-label={label}>
      <div className="tp-drawer__head">
        <div style={{ flex: 1 }}>{head}</div>
        <button type="button" className="tp-icon-btn" onClick={onClose} aria-label="Fechar"><Icon name="x" /></button>
      </div>
      <div className="tp-drawer__body">{children}</div>
    </aside>
  );
}

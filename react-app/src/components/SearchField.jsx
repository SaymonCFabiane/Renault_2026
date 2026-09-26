import Icon from './Icon.jsx';

// Busca em pílula com botão de lupa.
export default function SearchField({ value, onChange, onSubmit, placeholder, label, id, style, autoFocus }) {
  return (
    <form className="tp-search" role="search" style={style} onSubmit={(e) => { e.preventDefault(); onSubmit?.(); }}>
      <input id={id} value={value} placeholder={placeholder} aria-label={label} autoFocus={autoFocus} onChange={(e) => onChange(e.target.value)} />
      <button type="submit" aria-label="Buscar"><Icon name="search" /></button>
    </form>
  );
}

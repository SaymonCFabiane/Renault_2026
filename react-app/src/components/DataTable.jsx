import Icon from './Icon.jsx';

// Cabeçalho com seta de ordenação (visual, como no protótipo).
export function SortTh({ children, align, width }) {
  return (
    <th style={{ textAlign: align, width }}>
      {children}
      <span className="sort"><Icon name="chevrons-up-down" /></span>
    </th>
  );
}

export default function DataTable({ head, children, compact }) {
  return (
    <div className="tp-table-wrap">
      <table className={`tp-table${compact ? ' tp-table--compact' : ''}`}>
        <thead><tr>{head}</tr></thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}

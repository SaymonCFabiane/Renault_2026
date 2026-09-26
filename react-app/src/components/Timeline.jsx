import Icon from './Icon.jsx';

// steps: [ícone, quando, evento, responsável/local]
export default function Timeline({ steps }) {
  return (
    <ol className="tp-timeline">
      {steps.map((s, i) => (
        <li key={s[2]} className={i === steps.length - 1 ? 'last' : ''}>
          <span className="dot"><Icon name={s[0]} /></span>
          <div>
            <div className="when">{s[1]}</div>
            <div className="tp-h3">{s[2]}</div>
            <div className="tp-muted">{s[3]}</div>
          </div>
        </li>
      ))}
    </ol>
  );
}

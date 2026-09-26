import { NOTES } from '../data/mock.js';
import Icon from './Icon.jsx';

const tone = (t) => ({
  background: `var(--${t === 'data' ? 'primary-soft' : t + '-bg'})`,
  color: `var(--${t === 'data' ? 'primary' : t === 'warning' ? 'warning-text' : t === 'accent' ? 'accent-text' : t})`,
});

export default function NotificationsPopover({ profileId }) {
  return (
    <div className="tp-pop" role="dialog" aria-label="Notificações">
      <h4>Notificações</h4>
      {NOTES[profileId].map((n) => (
        <div key={n[2]} className="tp-note">
          <span className="ico" style={tone(n[1])}><Icon name={n[0]} /></span>
          <div><p>{n[2]}</p><small>{n[3]}</small></div>
        </div>
      ))}
    </div>
  );
}

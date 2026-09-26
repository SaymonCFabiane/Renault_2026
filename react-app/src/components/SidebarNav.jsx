import { useState } from 'react';
import { MENUS } from '../data/mock.js';
import { useDemo } from '../state/useDemo.js';
import Icon from './Icon.jsx';

// Sidebar azul-petróleo: perfil no topo (abre o menu da demo), menu do módulo e "Trocar perfil".
export default function SidebarNav({ profile, current, onGo, onSwap }) {
  const { act } = useDemo();
  const [menu, setMenu] = useState(false);
  const run = (type) => { setMenu(false); act(type); };
  return (
    <aside className="tp-side">
      <div className="tp-side__who">
        <button type="button" className="tp-who-btn" aria-haspopup="menu" aria-expanded={menu} onClick={() => setMenu((m) => !m)} title="Opções da demo">
          <span className="tp-avatar tp-avatar--lg">{profile.ini}</span>
          <span className="name">{profile.name}</span>
          <span className="role">{profile.role} · {profile.org}</span>
        </button>
        <span className="mod"><Icon name={profile.icon} />{profile.mod}</span>
        {menu && (
          <>
            <div style={{ position: 'fixed', inset: 0, zIndex: 39 }} onClick={() => setMenu(false)} />
            <div className="tp-menu" role="menu">
              <div className="tp-cap">Demo</div>
              <button type="button" role="menuitem" onClick={() => run('skipEnd')}><Icon name="skip-forward" />Pular para o fim da história</button>
              <button type="button" role="menuitem" onClick={() => run('reset')}><Icon name="rotate-ccw" />Reiniciar demo</button>
            </div>
          </>
        )}
      </div>
      <nav className="tp-nav" aria-label="Menu">
        {MENUS[profile.id].map(([code, label, icon]) => (
          <button key={code} type="button" className={code === current ? 'on' : ''} aria-current={code === current ? 'page' : undefined} onClick={() => onGo(code)}>
            <Icon name={icon} />{label}
          </button>
        ))}
      </nav>
      <button type="button" className="tp-side__swap" onClick={onSwap}><Icon name="arrow-left-right" />Trocar perfil</button>
    </aside>
  );
}

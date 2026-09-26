import { useEffect, useState } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { MENUS, NOTES, PATHS, SEARCH } from '../data/mock.js';
import { useDemo } from '../state/useDemo.js';
import Icon from '../components/Icon.jsx';
import SidebarNav from '../components/SidebarNav.jsx';
import SearchField from '../components/SearchField.jsx';
import ThemeToggle from '../components/ThemeToggle.jsx';
import NotificationsPopover from '../components/NotificationsPopover.jsx';
import Toast from '../components/Toast.jsx';

function SearchPopover({ profileId, query, onPick }) {
  const q = query.trim().toLowerCase();
  const res = SEARCH.filter((x) => x[2] === profileId && (!q || x[0].toLowerCase().includes(q) || x[1].toLowerCase().includes(q)));
  return (
    <div className="tp-pop" style={{ right: 260 }} role="dialog" aria-label="Resultados da busca">
      <h4>Resultados para “{query}”</h4>
      {res.length ? res.map((r) => (
        <button key={r[0] + r[3]} type="button" className="tp-note" style={{ width: '100%', border: 0, background: 'none', cursor: 'pointer', textAlign: 'left' }} onClick={() => onPick(r)}>
          <span className="ico" style={{ background: 'var(--primary-soft)', color: 'var(--primary)' }}><Icon name="search" /></span>
          <div><p><b>{r[0]}</b></p><small>{r[1]}</small></div>
        </button>
      )) : (
        <div className="tp-empty" style={{ padding: 16 }}>
          <b>Nada encontrado no seu módulo</b>
          <span>Tente KT-0142, MN-0457 ou PC-000098.</span>
        </div>
      )}
    </div>
  );
}

export default function WebShell({ profile }) {
  const { act } = useDemo();
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const [pop, setPop] = useState(null);
  const [query, setQuery] = useState('');
  const current = MENUS[profile.id].find((m) => m[3] === pathname) || MENUS[profile.id][0];

  useEffect(() => {
    document.title = `${current[1]} · TracePro`;
  }, [current]);

  useEffect(() => {
    if (!pop) return undefined;
    const onKey = (e) => e.key === 'Escape' && setPop(null);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [pop]);

  const go = (code) => { setPop(null); act('closeDrawer'); navigate(PATHS[code]); };
  const pick = ([code, , , scr]) => { setPop(null); act('searchJump', { code, scr }); navigate(PATHS[scr]); };

  return (
    <div className="tp tp-app">
      <SidebarNav profile={profile} current={current[0]} onGo={go} onSwap={() => { act('closeDrawer'); navigate('/'); }} />
      <div className="tp-main">
        <header className="tp-head">
          <h1 className="tp-h1">Olá, {profile.first}!</h1>
          <SearchField id="hs-q" value={query} onChange={setQuery} onSubmit={() => setPop('search')} placeholder="Buscar kit, carga, peça…" label="Buscar" />
          <ThemeToggle />
          <button type="button" className="tp-icon-btn tp-bell" onClick={() => setPop(pop === 'bell' ? null : 'bell')} aria-label="Notificações" aria-expanded={pop === 'bell'}>
            <Icon name="bell" />
            <span className="dot">{NOTES[profile.id].length}</span>
          </button>
        </header>
        <main className="tp-content">
          <Outlet />
        </main>
      </div>
      {pop && <div style={{ position: 'fixed', inset: 0, zIndex: 39 }} onClick={() => setPop(null)} />}
      {pop === 'bell' && <NotificationsPopover profileId={profile.id} />}
      {pop === 'search' && <SearchPopover profileId={profile.id} query={query} onPick={pick} />}
      <Toast />
    </div>
  );
}

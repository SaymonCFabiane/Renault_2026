import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { MENUS, PROFILES } from '../data/mock.js';
import { useDemo } from '../state/useDemo.js';
import Icon from '../components/Icon.jsx';
import Button from '../components/Button.jsx';
import ThemeToggle from '../components/ThemeToggle.jsx';
import Toast from '../components/Toast.jsx';

export default function ProfilePicker() {
  const navigate = useNavigate();
  const { act } = useDemo();
  useEffect(() => { document.title = 'TracePro · Escolha um perfil'; }, []);
  return (
    <div className="tp tp-marca" style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 36, padding: 40, position: 'relative' }}>
      <div style={{ position: 'absolute', top: 20, right: 24 }}><ThemeToggle /></div>
      <div style={{ textAlign: 'center' }}>
        <div className="tp-row" style={{ justifyContent: 'center', gap: 10, marginBottom: 10 }}>
          <span className="tp-iconbox" style={{ background: '#ffffff26', color: '#fff', borderColor: 'transparent' }}><Icon name="route" /></span>
          <span style={{ fontSize: 32, fontWeight: 800, color: '#fff' }}>TracePro</span>
        </div>
        <h1 className="tp-h1" style={{ color: '#fff' }}>Escolha um perfil para entrar</h1>
        <p style={{ margin: '6px 0 0', color: '#E0D9EC' }}>Painel web dos administradores · Fornecedor → Estoque → Cliente</p>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 320px)', gap: 24 }}>
        {Object.values(PROFILES).map((p) => (
          <button key={p.id} type="button" className="tp-card" onClick={() => navigate(MENUS[p.id][0][3])}
            style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: '28px 24px', gap: 10, border: '1.5px solid transparent', cursor: 'pointer', width: '100%' }}>
            <span className="tp-avatar" style={{ width: 84, height: 84, fontSize: 28 }}>{p.ini}</span>
            <span><b style={{ display: 'block', fontSize: 20, lineHeight: '26px' }}>{p.name}</b><span className="tp-muted" style={{ display: 'block' }}>{p.role}</span></span>
            <span className="tp-tag tp-tag--info" style={{ height: 28, fontSize: 12, padding: '0 12px' }}><Icon name={p.icon} />{p.mod.toUpperCase()}</span>
            <span className="tp-cap">{p.org}</span>
            <span className="tp-btn tp-btn--primary" style={{ marginTop: 8 }}>Entrar como {p.first}</span>
          </button>
        ))}
      </div>
      <div className="tp-row" style={{ justifyContent: 'center' }}>
        <Button variant="ghost" size="sm" icon="skip-forward" onClick={() => act('skipEnd')}>Pular para o fim da história</Button>
        <Button variant="ghost" size="sm" icon="rotate-ccw" onClick={() => act('reset')}>Reiniciar demo</Button>
      </div>
      <p className="tp-cap">Protótipo de demonstração · dados fictícios · nada é salvo ao recarregar</p>
      <Toast />
    </div>
  );
}

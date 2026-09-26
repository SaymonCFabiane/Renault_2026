import { useDemo } from '../state/useDemo.js';
import Icon from './Icon.jsx';

export default function ThemeToggle() {
  const { S, act } = useDemo();
  return (
    <button type="button" className="tp-theme" onClick={() => act('theme')} aria-label={S.theme === 'light' ? 'Mudar para o tema escuro' : 'Mudar para o tema claro'}>
      <span className={S.theme === 'light' ? 'on' : ''}><Icon name="sun" /></span>
      <span className={S.theme === 'dark' ? 'on' : ''}><Icon name="moon" /></span>
    </button>
  );
}

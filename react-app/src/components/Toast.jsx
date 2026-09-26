import { useDemo } from '../state/useDemo.js';
import Icon from './Icon.jsx';

// Defeito 4: no máximo um toast visível, abaixo de modais e drawers.
export default function Toast() {
  const { S } = useDemo();
  const t = S.toast;
  return (
    <div className="tp-toasts" aria-live="polite">
      {t && (
        <div key={t.id} className={`tp-toast tp-toast--${t.k}`}>
          <span className="ico"><Icon name={t.k === 'ok' ? 'check' : t.k === 'bad' ? 'x' : 'triangle-alert'} /></span>
          {t.m}
        </div>
      )}
    </div>
  );
}

import { rotulo } from '../rotulos.js';

/** Caixas normalizadas (0–1) desenhadas sobre a imagem ou o vídeo, em porcentagem. */
export default function Caixas({ deteccoes }) {
  return (
    <div className="tp-caixas" aria-hidden="true">
      {deteccoes.map((d, i) => {
        const c = d.caixa;
        return (
          <div key={i} className={`tp-caixa${c.y1 < 0.06 ? ' dentro' : ''}`}
            style={{ left: `${c.x1 * 100}%`, top: `${c.y1 * 100}%`, width: `${(c.x2 - c.x1) * 100}%`, height: `${(c.y2 - c.y1) * 100}%` }}>
            <span>{rotulo(d.classe)} {Math.round(d.confianca * 100)}%</span>
          </div>
        );
      })}
    </div>
  );
}

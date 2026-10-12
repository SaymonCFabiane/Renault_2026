import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { urlImagem } from '../api.js';
import Icon from './Icon.jsx';
import { Banner, Button } from './ui.jsx';

let proximoId = 0;
const comId = (c) => ({ ...c, _id: ++proximoId });
const limitar = (v) => Math.min(1, Math.max(0, v));
const DIGITAVEL = new Set(['INPUT', 'SELECT', 'TEXTAREA']);

/**
 * Editor de caixas de uma foto. Arraste no vazio para desenhar; arraste a caixa para mover;
 * puxe os cantos para ajustar. Teclado: 1–9 classe, Delete apaga, Enter confirma, ←/→ navega, D descarta.
 */
export default function Anotador({ imagem, classes, posicao, total, onSalvar, onDescartar, onIr, onFechar }) {
  const [caixas, setCaixas] = useState(() => imagem.caixas.map(comId));
  const [sel, setSel] = useState(null);
  const [classeAtiva, setClasseAtiva] = useState(imagem.classe_esperada_id ?? classes[0]?.id);
  const [sujo, setSujo] = useState(false);
  const [novo, setNovo] = useState(null);
  const [tam, setTam] = useState({ w: 0, h: 0 });
  const [ocupado, setOcupado] = useState(false);
  const [erro, setErro] = useState(null);
  const [avisoVazio, setAvisoVazio] = useState(false);
  const palco = useRef(null);
  const area = useRef(null);
  const arrasto = useRef(null);
  const acoes = useRef({});
  const porId = Object.fromEntries(classes.map((c) => [c.id, c]));

  // A foto ocupa o maior tamanho que cabe no palco, sem distorcer.
  useLayoutEffect(() => {
    const ajustar = () => {
      const { clientWidth: pw, clientHeight: ph } = palco.current;
      const a = imagem.largura / imagem.altura;
      const w = Math.min(pw - 24, (ph - 24) * a);
      setTam({ w, h: w / a });
    };
    ajustar();
    const ro = new ResizeObserver(ajustar);
    ro.observe(palco.current);
    return () => ro.disconnect();
  }, [imagem.largura, imagem.altura]);

  const mexer = (id, f) => {
    setCaixas((cs) => cs.map((c) => (c._id === id ? f(c) : c)));
    setSujo(true);
  };

  function ponto(e) {
    const r = area.current.getBoundingClientRect();
    return [limitar((e.clientX - r.left) / r.width), limitar((e.clientY - r.top) / r.height)];
  }

  function aoApertar(e) {
    if (e.button !== 0) return;
    const [x, y] = ponto(e);
    const alca = e.target.dataset.alca;
    const id = Number(e.target.closest('[data-id]')?.dataset.id) || null;
    area.current.setPointerCapture(e.pointerId);
    if (id) {
      const c = caixas.find((k) => k._id === id);
      setSel(id);
      arrasto.current = alca ? { modo: 'alca', alca, id } : { modo: 'mover', id, dx: x - c.x1, dy: y - c.y1, w: c.x2 - c.x1, h: c.y2 - c.y1 };
    } else {
      setSel(null);
      arrasto.current = { modo: 'desenhar', x0: x, y0: y };
      setNovo({ x1: x, y1: y, x2: x, y2: y });
    }
  }

  function aoMover(e) {
    const a = arrasto.current;
    if (!a) return;
    const [x, y] = ponto(e);
    if (a.modo === 'desenhar') {
      setNovo({ x1: Math.min(a.x0, x), y1: Math.min(a.y0, y), x2: Math.max(a.x0, x), y2: Math.max(a.y0, y) });
    } else if (a.modo === 'mover') {
      const x1 = limitar(Math.min(x - a.dx, 1 - a.w)), y1 = limitar(Math.min(y - a.dy, 1 - a.h));
      mexer(a.id, (c) => ({ ...c, x1, y1, x2: x1 + a.w, y2: y1 + a.h, origem: 'manual', confianca: null }));
    } else {
      mexer(a.id, (c) => {
        const n = { ...c, origem: 'manual', confianca: null };
        if (a.alca.includes('n')) n.y1 = y; else n.y2 = y;
        if (a.alca.includes('w')) n.x1 = x; else n.x2 = x;
        return n;
      });
    }
  }

  function aoSoltar() {
    const a = arrasto.current;
    arrasto.current = null;
    if (a?.modo === 'desenhar') {
      if (novo && novo.x2 - novo.x1 > 0.01 && novo.y2 - novo.y1 > 0.01) {
        const c = comId({ classe_id: classeAtiva, ...novo, origem: 'manual', confianca: null });
        setCaixas((cs) => [...cs, c]);
        setSel(c._id);
        setSujo(true);
      }
      setNovo(null);
    } else if (a?.modo === 'alca') {
      // Cantos cruzados viram uma caixa válida.
      mexer(a.id, (c) => ({ ...c, x1: Math.min(c.x1, c.x2), x2: Math.max(c.x1, c.x2), y1: Math.min(c.y1, c.y2), y2: Math.max(c.y1, c.y2) }));
    }
  }

  const paraApi = () => caixas.map(({ _id, ...c }) => c);

  async function salvar(status) {
    setOcupado(true);
    setErro(null);
    try {
      await onSalvar(paraApi(), status);
      setSujo(false);
      return true;
    } catch (e) {
      setErro(`${e.message} (${e.codigo})`);
      return false;
    } finally {
      setOcupado(false);
    }
  }

  // Foto de uma pasta de peça sem nenhuma caixa: o primeiro Enter só avisa, para não ensinar "sem peça" por engano.
  const esperada = porId[imagem.classe_esperada_id];
  useEffect(() => { if (caixas.length) setAvisoVazio(false); }, [caixas.length]);
  const confirmar = async () => {
    if (!caixas.length && esperada && !avisoVazio) { setAvisoVazio(true); return; }
    if (await salvar('revisada')) onIr(1);
  };
  const ir = async (d) => { if (!sujo || (await salvar())) onIr(d); };
  const descartar = async () => {
    setOcupado(true);
    try { await onDescartar(); onIr(1); } catch (e) { setErro(e.message); } finally { setOcupado(false); }
  };
  const apagar = (id) => { setCaixas((cs) => cs.filter((c) => c._id !== id)); setSel(null); setSujo(true); };
  const escolherClasse = (id) => {
    setClasseAtiva(id);
    if (sel) mexer(sel, (c) => ({ ...c, classe_id: id }));
  };

  acoes.current = { confirmar, ir, descartar, apagar, escolherClasse, sel, onFechar, ocupado };
  useEffect(() => {
    const tecla = (e) => {
      if (DIGITAVEL.has(e.target.tagName) || e.metaKey || e.ctrlKey) return;
      const a = acoes.current;
      if (a.ocupado) return;
      const n = Number(e.key);
      if (n >= 1 && n <= classes.length) a.escolherClasse(classes[n - 1].id);
      else if ((e.key === 'Delete' || e.key === 'Backspace') && a.sel) a.apagar(a.sel);
      else if (e.key === 'Enter') a.confirmar();
      else if (e.key === 'ArrowRight') a.ir(1);
      else if (e.key === 'ArrowLeft') a.ir(-1);
      else if (e.key === 'd' || e.key === 'D') a.descartar();
      else if (e.key === 'Escape') { if (a.sel) setSel(null); else a.onFechar(); }
      else return;
      e.preventDefault();
    };
    window.addEventListener('keydown', tecla);
    return () => window.removeEventListener('keydown', tecla);
  }, [classes]);

  const pct = (c) => ({ left: `${c.x1 * 100}%`, top: `${c.y1 * 100}%`, width: `${(c.x2 - c.x1) * 100}%`, height: `${(c.y2 - c.y1) * 100}%` });
  const statusTexto = { pendente: 'Sem caixa', sugerida: 'Sugestão', revisada: 'Revisada', descartada: 'Descartada' }[imagem.status];

  return (
    <div className="tp-anot">
      <div className="tp-anot__palco" ref={palco}>
        <div ref={area} className="tp-anot__area" style={{ width: tam.w, height: tam.h }}
          onPointerDown={aoApertar} onPointerMove={aoMover} onPointerUp={aoSoltar} onPointerCancel={aoSoltar}>
          <img src={urlImagem(imagem.id)} alt={imagem.nome_original || 'Foto do dataset'} draggable={false} />
          {caixas.map((c) => {
            const cl = porId[c.classe_id];
            return (
              <div key={c._id} data-id={c._id} className={`tp-anot__caixa${sel === c._id ? ' sel' : ''}${c.origem !== 'manual' ? ' sugestao' : ''}${c.y1 < 0.05 ? ' topo' : ''}`}
                style={{ ...pct(c), borderColor: cl?.cor }}>
                <span style={{ background: cl?.cor }}>{cl?.rotulo}{c.origem !== 'manual' && c.confianca != null ? ` · ${Math.round(c.confianca * 100)}%` : ''}</span>
                {sel === c._id && ['nw', 'ne', 'sw', 'se'].map((k) => <i key={k} className="tp-anot__alca" data-alca={k} />)}
              </div>
            );
          })}
          {novo && <div className="tp-anot__novo" style={pct(novo)} />}
        </div>
      </div>

      <aside className="tp-anot__lado">
        <section className="tp-card" style={{ padding: 16 }}>
          <div className="tp-row" style={{ justifyContent: 'space-between' }}>
            <b>Foto {posicao} de {total}</b>
            <span className={`tp-tag ${imagem.status === 'revisada' ? 'tp-tag--ok' : imagem.status === 'pendente' ? 'tp-tag--blocante' : 'tp-tag--info'}`}>{statusTexto}{sujo ? ' · editada' : ''}</span>
          </div>
          <p className="tp-cap" style={{ margin: '6px 0 0', wordBreak: 'break-all' }}>{imagem.nome_original} · {imagem.divisao === 'validacao' ? 'validação' : 'treino'}</p>
        </section>

        <section className="tp-card" style={{ padding: 16 }}>
          <div className="tp-label">Classe da próxima caixa</div>
          <div className="tp-stack" style={{ gap: 6 }}>
            {classes.map((c, i) => (
              <button key={c.id} type="button" className={`tp-classe-opcao${classeAtiva === c.id ? ' on' : ''}`} onClick={() => escolherClasse(c.id)}>
                <i style={{ background: c.cor }} />{c.rotulo}<kbd>{i + 1}</kbd>
              </button>
            ))}
          </div>
        </section>

        <section className="tp-card" style={{ padding: 16 }}>
          <div className="tp-label">Caixas nesta foto ({caixas.length})</div>
          {caixas.length ? (
            <div className="tp-stack" style={{ gap: 6 }}>
              {caixas.map((c) => (
                <div key={c._id} className={`tp-caixa-item${sel === c._id ? ' sel' : ''}`} onClick={() => setSel(c._id)}>
                  <i style={{ width: 10, height: 10, borderRadius: 2, background: porId[c.classe_id]?.cor, flex: 'none' }} />
                  <select className="tp-select" value={c.classe_id} aria-label="Classe da caixa" onChange={(e) => mexer(c._id, (k) => ({ ...k, classe_id: Number(e.target.value) }))}>
                    {classes.map((k) => <option key={k.id} value={k.id}>{k.rotulo}</option>)}
                  </select>
                  {c.origem !== 'manual' && c.confianca != null && <span className="tp-cap">{Math.round(c.confianca * 100)}%</span>}
                  <button type="button" className="tp-icon-btn" style={{ width: 30, height: 30 }} aria-label="Apagar caixa" onClick={(e) => { e.stopPropagation(); apagar(c._id); }}><Icon name="trash" size={16} /></button>
                </div>
              ))}
            </div>
          ) : (
            <p className="tp-cap" style={{ margin: 0 }}>Arraste sobre a peça para marcar. Se a foto não tiver nenhuma peça, confirme assim mesmo: ela vira exemplo de fundo.</p>
          )}
        </section>

        {avisoVazio && (
          <Banner tone="warn" icon="circle-alert" title={`Esta foto veio da pasta ${esperada?.rotulo} e está sem caixa`}>
            Arraste sobre a peça para marcar. Se ela realmente não aparece, confirme de novo (Enter) e a foto entra como exemplo sem peça.
          </Banner>
        )}
        {erro && <Banner tone="bad" icon="circle-x" title="Não salvou">{erro}</Banner>}

        <div className="tp-stack" style={{ gap: 8 }}>
          <Button block icon="check" disabled={ocupado} onClick={confirmar}>Confirmar e próxima</Button>
          <div className="tp-row" style={{ gap: 8, flexWrap: 'nowrap' }}>
            <Button variant="outline" icon="chevron-left" disabled={ocupado || posicao === 1} onClick={() => ir(-1)} style={{ flex: 1 }}>Anterior</Button>
            <Button variant="outline" disabled={ocupado} onClick={() => ir(1)} style={{ flex: 1 }}>Pular<Icon name="chevron-right" /></Button>
          </div>
          <Button variant="ghost" icon="ban" disabled={ocupado} onClick={descartar}>Descartar foto</Button>
          <Button variant="ghost" icon="arrow-left" onClick={onFechar}>Voltar para a grade</Button>
        </div>

        <section className="tp-atalhos" aria-label="Atalhos de teclado">
          <kbd>Enter</kbd><span>Confirmar e ir para a próxima</span>
          <kbd>← →</kbd><span>Anterior / próxima (salva o que mudou)</span>
          <kbd>1 2 …</kbd><span>Classe (muda a caixa selecionada)</span>
          <kbd>Delete</kbd><span>Apagar a caixa selecionada</span>
          <kbd>D</kbd><span>Descartar a foto (fora do treino)</span>
          <kbd>Esc</kbd><span>Tirar seleção / voltar</span>
        </section>
      </aside>
    </div>
  );
}

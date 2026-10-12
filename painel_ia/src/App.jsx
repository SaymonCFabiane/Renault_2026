import { useCallback, useEffect, useState } from 'react';
import { apiBase, buscarStatus } from './api.js';
import Icon from './components/Icon.jsx';
import AoVivo from './paginas/AoVivo.jsx';
import Dataset from './paginas/Dataset.jsx';
import Status from './paginas/Status.jsx';
import TesteImagem from './paginas/TesteImagem.jsx';
import Treinos from './paginas/Treinos.jsx';

const PAGINAS = [
  ['ao-vivo', 'Ao vivo', 'camera', AoVivo],
  ['imagem', 'Teste por imagem', 'image-up', TesteImagem],
  ['dataset', 'Dataset', 'images', Dataset],
  ['treinos', 'Treinos', 'activity', Treinos],
  ['status', 'Status e modelo', 'server', Status],
];

function paginaInicial() {
  const h = location.hash.slice(1);
  return PAGINAS.some((p) => p[0] === h) ? h : 'ao-vivo';
}

export default function App() {
  const [pagina, setPagina] = useState(paginaInicial);
  const [status, setStatus] = useState(null);
  const [erro, setErro] = useState(null);
  const [tema, setTema] = useState(() => (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'));

  const atualizar = useCallback(async () => {
    try {
      setStatus(await buscarStatus());
      setErro(null);
    } catch (e) {
      setStatus(null);
      setErro(e.message);
    }
  }, []);

  // O status da API é consultado a cada 5 s.
  useEffect(() => {
    atualizar();
    const t = setInterval(atualizar, 5000);
    return () => clearInterval(t);
  }, [atualizar]);

  useEffect(() => { document.documentElement.dataset.theme = tema; }, [tema]);
  // Links e o botão voltar do navegador trocam de página pelo #endereço.
  useEffect(() => {
    const aoMudar = () => setPagina(paginaInicial());
    window.addEventListener('hashchange', aoMudar);
    return () => window.removeEventListener('hashchange', aoMudar);
  }, []);

  const ir = (id) => { location.hash = id; };
  const [, titulo, , Pagina] = PAGINAS.find((p) => p[0] === pagina);
  const pill = status?.status === 'ok' ? ['ok', `${status.modelo} · ${status.dispositivo?.toUpperCase()}`] : status ? ['warn', 'API sem modelo'] : ['bad', 'API fora do ar'];

  return (
    <div className="tp tp-app">
      <aside className="tp-side">
        <div className="tp-side__brand">
          <span className="logo"><Icon name="scan-eye" /></span>
          <span><b>TracePro</b><span>Painel de IA</span></span>
        </div>
        <nav className="tp-nav" aria-label="Menu">
          {PAGINAS.map(([id, nome, icone]) => (
            <button key={id} type="button" className={id === pagina ? 'on' : ''} aria-current={id === pagina ? 'page' : undefined} onClick={() => ir(id)}>
              <Icon name={icone} />{nome}
            </button>
          ))}
        </nav>
        <p className="tp-side__foot">API em {apiBase().replace(/^https?:\/\//, '')}</p>
      </aside>
      <div className="tp-main">
        <header className="tp-head">
          <h1 className="tp-h1">{titulo}</h1>
          <span className={`tp-pill-status ${pill[0]}`} style={{ marginLeft: 'auto' }} title={erro || undefined}><i />{pill[1]}</span>
          <button type="button" className="tp-theme" onClick={() => setTema(tema === 'light' ? 'dark' : 'light')} aria-label={tema === 'light' ? 'Mudar para o tema escuro' : 'Mudar para o tema claro'}>
            <span className={tema === 'light' ? 'on' : ''}><Icon name="sun" /></span>
            <span className={tema === 'dark' ? 'on' : ''}><Icon name="moon" /></span>
          </button>
        </header>
        <main className="tp-content">
          <Pagina status={status} erro={erro} atualizar={atualizar} />
        </main>
      </div>
    </div>
  );
}

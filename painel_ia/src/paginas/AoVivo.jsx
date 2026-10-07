import { useCallback, useEffect, useRef, useState } from 'react';
import { montarQuadro, wsUrl } from '../api.js';
import { rotulo } from '../rotulos.js';
import Caixas from '../components/Caixas.jsx';
import Icon from '../components/Icon.jsx';
import Parametros from '../components/Parametros.jsx';
import { Banner, Button, Card, Segmented, Stat } from '../components/ui.jsx';

const LARGURA = 640, ALTURA = 480, QUALIDADE = 0.7;

function p95(v) {
  if (!v.length) return null;
  const s = [...v].sort((a, b) => a - b);
  return s[Math.max(0, Math.ceil(s.length * 0.95) - 1)];
}

function Sparkline({ valores }) {
  if (valores.length < 2) return <div className="tp-cap">A latência aparece aqui quando os quadros começarem a voltar.</div>;
  const max = Math.max(320, ...valores);
  const pts = valores.map((v, i) => `${(i / (valores.length - 1)) * 300},${60 - (v / max) * 56}`).join(' ');
  return (
    <svg className="tp-spark" viewBox="0 0 300 64" preserveAspectRatio="none" role="img" aria-label={`Latência dos últimos ${valores.length} quadros, máximo ${Math.round(max)} ms`}>
      <line x1="0" x2="300" y1={60 - (300 / max) * 56} y2={60 - (300 / max) * 56} stroke="var(--danger)" strokeDasharray="4 4" opacity=".6" />
      <polyline points={pts} fill="none" stroke="var(--data)" strokeWidth="2" vectorEffect="non-scaling-stroke" />
    </svg>
  );
}

/** Ao vivo: webcam do Mac → WebSocket da API, com o mesmo protocolo e controle de fluxo do app. */
export default function AoVivo({ status }) {
  const video = useRef(null);
  const tela = useRef(null);
  const ws = useRef(null);
  const fluxo = useRef({ seq: 0, emTransito: null, ultimoEnvio: 0, timeout: null, laco: null, fps: 8 });
  const [camera, setCamera] = useState('parada'); // parada | iniciando | ativa
  const [conexao, setConexao] = useState('desconectada'); // desconectada | conectando | conectada
  const [erro, setErro] = useState(null);
  const [fps, setFps] = useState(8);
  const [params, setParams] = useState({ confianca: 0.25, imgsz: 640, classes: [] });
  const [deteccoes, setDeteccoes] = useState([]);
  const [met, setMet] = useState({ lat: [], inf: [], respostas: [], descartados: 0, erros: 0 });

  fluxo.current.fps = fps;

  const enviarConfig = useCallback((p) => {
    if (ws.current?.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({ tipo: 'config', confianca: p.confianca, imgsz: p.imgsz, classes: p.classes }));
    }
  }, []);

  // Ajustes de parâmetros vão para a API logo depois de pararem de mudar.
  useEffect(() => {
    const t = setTimeout(() => enviarConfig(params), 250);
    return () => clearTimeout(t);
  }, [params, enviarConfig]);

  const parar = useCallback(() => {
    const f = fluxo.current;
    clearInterval(f.laco);
    clearTimeout(f.timeout);
    f.emTransito = null;
    ws.current?.close();
    ws.current = null;
    video.current?.srcObject?.getTracks().forEach((t) => t.stop());
    if (video.current) video.current.srcObject = null;
    setCamera('parada');
    setConexao('desconectada');
    setDeteccoes([]);
  }, []);

  useEffect(() => parar, [parar]);

  function capturarEEnviar() {
    const f = fluxo.current, v = video.current, sock = ws.current;
    if (!v || !sock || sock.readyState !== WebSocket.OPEN || f.emTransito != null || !v.videoWidth) return;
    const agora = Date.now();
    if (agora - f.ultimoEnvio < 1000 / f.fps) return;
    f.ultimoEnvio = agora;
    // Recorte central 4:3, igual ao que o visor mostra (object-fit: cover).
    const vw = v.videoWidth, vh = v.videoHeight;
    const sw = Math.min(vw, (vh * 4) / 3), sh = Math.min(vh, (vw * 3) / 4);
    const ctx = tela.current.getContext('2d');
    ctx.drawImage(v, (vw - sw) / 2, (vh - sh) / 2, sw, sh, 0, 0, LARGURA, ALTURA);
    const seq = ++f.seq;
    f.emTransito = seq;
    tela.current.toBlob(async (blob) => {
      if (!blob || ws.current !== sock) return;
      sock.send(montarQuadro(seq, agora, await blob.arrayBuffer()));
      clearTimeout(f.timeout);
      f.timeout = setTimeout(() => { if (f.emTransito === seq) f.emTransito = null; }, 1000);
    }, 'image/jpeg', QUALIDADE);
  }

  function aoMensagem(ev) {
    const m = JSON.parse(ev.data);
    const f = fluxo.current;
    if (m.seq != null && m.seq === f.emTransito && ['deteccoes', 'descartado', 'erro'].includes(m.tipo)) {
      f.emTransito = null;
      clearTimeout(f.timeout);
    }
    if (m.tipo === 'deteccoes') {
      const agora = Date.now();
      setDeteccoes(m.deteccoes);
      setMet((x) => ({
        ...x,
        lat: [...x.lat, agora - m.capturado_em].slice(-60),
        inf: [...x.inf, m.inferencia_ms].slice(-60),
        respostas: [...x.respostas.filter((t) => agora - t < 2000), agora],
      }));
    } else if (m.tipo === 'descartado') {
      setMet((x) => ({ ...x, descartados: x.descartados + 1 }));
    } else if (m.tipo === 'erro') {
      setErro(`${m.mensagem} (${m.codigo})`);
      setMet((x) => ({ ...x, erros: x.erros + 1 }));
    }
  }

  async function iniciar() {
    setErro(null);
    setCamera('iniciando');
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { width: { ideal: 1280 }, height: { ideal: 720 } }, audio: false });
      video.current.srcObject = stream;
      await video.current.play();
      setCamera('ativa');
    } catch (e) {
      setCamera('parada');
      setErro(e.name === 'NotAllowedError'
        ? 'O navegador não liberou a câmera. Permita o acesso e abra o painel em http://localhost:5174.'
        : `Não consegui abrir a câmera: ${e.message}`);
      return;
    }
    setConexao('conectando');
    const sock = new WebSocket(wsUrl());
    sock.binaryType = 'arraybuffer';
    ws.current = sock;
    sock.onopen = () => {
      setConexao('conectada');
      enviarConfig(params);
      fluxo.current.laco = setInterval(capturarEEnviar, 15);
    };
    sock.onmessage = aoMensagem;
    sock.onerror = () => setErro(`Não consegui conectar em ${wsUrl()}. A API está rodando?`);
    sock.onclose = () => {
      if (ws.current === sock) {
        setConexao('desconectada');
        clearInterval(fluxo.current.laco);
      }
    };
  }

  const fpsAtual = met.respostas.length / 2;
  const latMedia = met.lat.length ? met.lat.reduce((a, b) => a + b, 0) / met.lat.length : null;
  const infMedia = met.inf.length ? met.inf.reduce((a, b) => a + b, 0) / met.inf.length : null;
  const chip = conexao === 'conectada' ? ['ok', `${fpsAtual.toFixed(0)} fps · ${latMedia ? Math.round(latMedia) : '–'} ms`]
    : conexao === 'conectando' ? ['warn', 'Conectando…'] : ['bad', 'Desconectado'];
  const contagem = Object.entries(deteccoes.reduce((a, d) => ((a[d.classe] = (a[d.classe] || 0) + 1), a), {}));

  return (
    <div className="tp-grid">
      <div style={{ gridColumn: 'span 8', minWidth: 0 }} className="tp-stack">
        <Card title="Câmera do Mac" extra={
          <div className="tp-row">
            <Segmented label="Quadros por segundo" value={fps} onChange={setFps} items={[5, 8, 10, 15].map((v) => ({ value: v, label: `${v} fps` }))} />
            {camera === 'parada'
              ? <Button icon="play" onClick={iniciar} disabled={status?.status !== 'ok'}>Iniciar</Button>
              : <Button variant="outline" icon="square" onClick={parar}>Parar</Button>}
          </div>
        }>
          <div className="tp-video">
            <video ref={video} muted playsInline hidden={camera === 'parada'} />
            {camera === 'parada' && (
              <div className="tp-video__vazio">
                <div><Icon name="camera" size={32} /><b>Câmera parada</b><span>Toque em Iniciar para mandar a webcam para a API, como o app faz com o celular.</span></div>
              </div>
            )}
            {camera !== 'parada' && <Caixas deteccoes={deteccoes} />}
            {camera !== 'parada' && <span className={`tp-chip-video ${chip[0]}`}><i />{chip[1]}</span>}
          </div>
          <canvas ref={tela} width={LARGURA} height={ALTURA} hidden />
          {erro && <div style={{ marginTop: 12 }}><Banner tone="bad" icon="circle-x" title="Problema">{erro}</Banner></div>}
          {status?.status !== 'ok' && <div style={{ marginTop: 12 }}><Banner tone="warn" icon="circle-alert" title="API fora do ar">Suba a API (python -m app) para usar a câmera.</Banner></div>}
        </Card>
        <Card title="Desempenho" extra={<span className="tp-cap">Meta: abaixo de 300 ms (linha tracejada)</span>}>
          <div className="tp-metricas" style={{ marginBottom: 14 }}>
            <Stat value={fpsAtual.toFixed(1)} label="Quadros por segundo" />
            <Stat value={latMedia ? `${Math.round(latMedia)} ms` : '–'} label={`Latência · p95 ${p95(met.lat) ? Math.round(p95(met.lat)) + ' ms' : '–'}`} tone={latMedia > 300 ? 'bad' : latMedia ? 'ok' : undefined} />
            <Stat value={infMedia ? `${Math.round(infMedia)} ms` : '–'} label="Inferência no servidor" />
            <Stat value={`${met.descartados} · ${met.erros}`} label="Descartados · erros" tone={met.erros ? 'warn' : undefined} />
          </div>
          <Sparkline valores={met.lat} />
        </Card>
      </div>
      <div style={{ gridColumn: 'span 4', minWidth: 0 }} className="tp-stack">
        <Card title="Detectado agora">
          {contagem.length ? (
            <div className="tp-stack" style={{ gap: 8 }}>
              {contagem.map(([classe, n]) => (
                <div key={classe} className="tp-row" style={{ justifyContent: 'space-between' }}>
                  <b>{rotulo(classe)}</b><span className="tp-tag tp-tag--info">×{n}</span>
                </div>
              ))}
            </div>
          ) : <p className="tp-muted" style={{ margin: 0 }}>{camera === 'ativa' ? 'Nada acima da confiança mínima.' : 'Inicie a câmera.'}</p>}
        </Card>
        <Card title="Parâmetros">
          <Parametros valor={params} onChange={setParams} classes={status?.classes} />
        </Card>
      </div>
    </div>
  );
}

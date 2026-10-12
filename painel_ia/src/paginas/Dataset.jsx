import { useCallback, useEffect, useRef, useState } from 'react';
import {
  ajustarImagem, enviarFotoDataset, estadoSugestoes, iniciarSugestoes, listarImagens, resumoDataset, salvarCaixas, urlMiniatura,
} from '../api.js';
import Anotador from '../components/Anotador.jsx';
import Icon from '../components/Icon.jsx';
import { Banner, Button, Card, Stat } from '../components/ui.jsx';
import Tabs from '../components/Tabs.jsx';

const FILTROS = {
  revisar: ['A revisar', 'pendente,sugerida'],
  revisada: ['Revisadas', 'revisada'],
  descartada: ['Descartadas', 'descartada'],
  todas: ['Todas', ''],
};
const STATUS = { pendente: 'Sem caixa', sugerida: 'Sugestão', revisada: 'Revisada', descartada: 'Descartada' };

/** Caixas sobre a miniatura (object-fit: contain num quadro 3:4). */
function Molde({ item, cores }) {
  const a = item.largura / item.altura;
  const s = a > 0.75 ? { left: 0, width: '100%', height: `${(0.75 / a) * 100}%`, top: `${(100 - (0.75 / a) * 100) / 2}%` }
    : { top: 0, height: '100%', width: `${(a / 0.75) * 100}%`, left: `${(100 - (a / 0.75) * 100) / 2}%` };
  return (
    <div className="tp-foto__molde" style={s}>
      {item.caixas.map((c, i) => (
        <i key={i} style={{ left: `${c.x1 * 100}%`, top: `${c.y1 * 100}%`, width: `${(c.x2 - c.x1) * 100}%`, height: `${(c.y2 - c.y1) * 100}%`, borderColor: cores[c.classe_id], borderStyle: c.origem === 'manual' || item.status === 'revisada' ? 'solid' : 'dashed' }} />
      ))}
    </div>
  );
}

/** Dataset: fotos, caixas sugeridas e revisão. */
export default function Dataset({ status }) {
  const [resumo, setResumo] = useState(null);
  const [filtro, setFiltro] = useState('revisar');
  const [classeId, setClasseId] = useState('');
  const [itens, setItens] = useState([]);
  const [erro, setErro] = useState(null);
  const [sug, setSug] = useState(null);
  const [editor, setEditor] = useState(null); // { ids, i, mapa }
  const [aviso, setAviso] = useState(null);
  const [envio, setEnvio] = useState(null);
  const [classeEnvio, setClasseEnvio] = useState('');
  const entrada = useRef(null);

  const carregar = useCallback(async () => {
    try {
      const [r, l] = await Promise.all([resumoDataset(), listarImagens({ status: FILTROS[filtro][1], classe_id: classeId })]);
      setResumo(r);
      setItens(l.itens);
      setErro(null);
    } catch (e) {
      setErro(e.message);
    }
  }, [filtro, classeId]);

  useEffect(() => { carregar(); }, [carregar]);
  useEffect(() => { estadoSugestoes().then(setSug).catch(() => {}); }, []);
  // Enquanto as sugestões rodam, acompanha o progresso e recarrega no fim.
  useEffect(() => {
    if (!sug?.rodando) return undefined;
    const t = setInterval(async () => {
      try {
        const s = await estadoSugestoes();
        setSug(s);
        if (!s.rodando) carregar();
      } catch { /* a API pode estar reiniciando */ }
    }, 1000);
    return () => clearInterval(t);
  }, [sug?.rodando, carregar]);

  const classes = resumo?.classes || [];
  const cores = Object.fromEntries(classes.map((c) => [c.id, c.cor]));
  const im = resumo?.imagens;

  function abrir(i) {
    setAviso(null);
    setEditor({ ids: itens.map((x) => x.id), i, mapa: Object.fromEntries(itens.map((x) => [x.id, x])) });
  }

  function fecharEditor(msg) {
    setEditor(null);
    if (msg) setAviso(msg);
    carregar();
  }

  function ir(d) {
    const i = editor.i + d;
    if (i < 0) return;
    if (i >= editor.ids.length) fecharEditor('Você chegou ao fim desta lista.');
    else setEditor({ ...editor, i });
  }

  async function salvar(caixas, st) {
    const id = editor.ids[editor.i];
    const novo = await salvarCaixas(id, caixas, st);
    setEditor((e) => ({ ...e, mapa: { ...e.mapa, [id]: novo } }));
  }

  async function descartar() {
    const id = editor.ids[editor.i];
    const novo = await ajustarImagem(id, { status: 'descartada' });
    setEditor((e) => ({ ...e, mapa: { ...e.mapa, [id]: novo } }));
  }

  async function sugerir() {
    try {
      setSug(await iniciarSugestoes(false));
    } catch (e) {
      setErro(e.message);
    }
  }

  async function enviar(arquivos) {
    const lista = [...arquivos];
    let novas = 0, repetidas = 0, falhas = 0;
    for (let k = 0; k < lista.length; k++) {
      setEnvio(`Enviando ${k + 1} de ${lista.length}…`);
      try {
        const r = await enviarFotoDataset(lista[k], classeEnvio || null);
        if (r.nova) novas++; else repetidas++;
      } catch {
        falhas++;
      }
    }
    setEnvio(null);
    setAviso(`${novas} fotos novas${repetidas ? `, ${repetidas} já estavam no dataset` : ''}${falhas ? `, ${falhas} com erro` : ''}. Toque em "Sugerir caixas" para marcar as novas.`);
    carregar();
  }

  if (editor) {
    const id = editor.ids[editor.i];
    return (
      <Anotador key={id} imagem={editor.mapa[id]} classes={classes} posicao={editor.i + 1} total={editor.ids.length}
        onSalvar={salvar} onDescartar={descartar} onIr={ir} onFechar={() => fecharEditor()} />
    );
  }

  if (!status) return <Banner tone="bad" icon="circle-x" title="API fora do ar">Suba a API para ver o dataset.</Banner>;

  const semCaixa = im?.pendente ?? 0;
  const prontas = resumo?.revisadas_por_divisao;

  return (
    <div className="tp-stack">
      <Card title="Dataset de treino" extra={
        <div className="tp-row">
          <Button variant="outline" icon="upload" onClick={() => entrada.current.click()} disabled={!!envio}>{envio || 'Enviar fotos'}</Button>
          <Button icon="wand" onClick={sugerir} disabled={sug?.rodando || !semCaixa}>{sug?.rodando ? `Sugerindo ${sug.feitas}/${sug.total}…` : `Sugerir caixas (${semCaixa})`}</Button>
        </div>
      }>
        <input ref={entrada} type="file" accept="image/*" multiple hidden onChange={(e) => { enviar(e.target.files); e.target.value = ''; }} />
        {im && (
          <div className="tp-metricas" style={{ marginBottom: 16 }}>
            <Stat value={im.total} label="Fotos" />
            <Stat value={im.pendente + im.sugerida} label={`A revisar · ${im.sugerida} com sugestão`} tone={im.pendente + im.sugerida ? 'warn' : 'ok'} />
            <Stat value={im.revisada} label={`Revisadas · ${prontas?.treino ?? 0} treino, ${prontas?.validacao ?? 0} validação`} tone={im.revisada ? 'ok' : undefined} />
            <Stat value={im.descartada} label="Descartadas" />
          </div>
        )}
        <div className="tp-row" style={{ gap: 16 }}>
          {classes.map((c) => (
            <span key={c.id} className="tp-row" style={{ gap: 6, fontSize: 13 }}>
              <i style={{ width: 12, height: 12, borderRadius: 3, background: c.cor, display: 'inline-block' }} />
              <b>{c.rotulo}</b><span className="tp-muted">{c.imagens} fotos · {c.caixas_revisadas} caixas revisadas</span>
            </span>
          ))}
          <label className="tp-row" style={{ gap: 6, marginLeft: 'auto', fontSize: 13 }}>
            <span className="tp-muted">Fotos enviadas são da classe</span>
            <select className="tp-select" style={{ width: 170, height: 34 }} value={classeEnvio} onChange={(e) => setClasseEnvio(e.target.value)}>
              <option value="">não informada</option>
              {classes.map((c) => <option key={c.id} value={c.id}>{c.rotulo}</option>)}
            </select>
          </label>
        </div>
        {sug?.rodando && <div className="tp-progress" style={{ marginTop: 14 }}><i style={{ width: `${(sug.feitas / Math.max(1, sug.total)) * 100}%` }} /></div>}
        {sug && !sug.rodando && sug.concluida_em && sug.total > 0 && (
          <p className="tp-cap" style={{ margin: '10px 0 0' }}>Última sugestão: {sug.com_caixa} fotos com caixa, {sug.sem_caixa} sem. As sugestões usam como exemplo as suas caixas revisadas mais recentes.</p>
        )}
      </Card>

      {aviso && <Banner tone="ok" icon="circle-check" title={aviso} />}
      {erro && <Banner tone="bad" icon="circle-x" title="Problema">{erro}</Banner>}

      <Card title="Fotos" extra={
        <div className="tp-row">
          <select className="tp-select" style={{ width: 180, height: 36 }} value={classeId} onChange={(e) => setClasseId(e.target.value)} aria-label="Filtrar por classe">
            <option value="">Todas as classes</option>
            {classes.map((c) => <option key={c.id} value={c.id}>{c.rotulo}</option>)}
          </select>
          {itens.length > 0 && <Button icon="play" onClick={() => abrir(0)}>Revisar {itens.length} fotos</Button>}
        </div>
      }>
        <Tabs value={filtro} onChange={setFiltro} style={{ marginBottom: 16 }}
          items={Object.entries(FILTROS).map(([v, [rot]]) => ({ value: v, label: rot }))} />
        {itens.length ? (
          <div className="tp-galeria">
            {itens.map((x, i) => (
              <button key={x.id} type="button" className="tp-foto" onClick={() => abrir(i)} title={x.nome_original}>
                <img src={urlMiniatura(x.id)} alt="" loading="lazy" />
                <Molde item={x} cores={cores} />
                <span className={`tp-foto__status ${x.status}`}>
                  {STATUS[x.status]}{x.status === 'sugerida' && x.caixas[0]?.confianca != null ? ` · ${Math.round(x.caixas[0].confianca * 100)}%` : ''}
                </span>
              </button>
            ))}
          </div>
        ) : (
          <div className="tp-empty"><div className="ring"><Icon name="images" /></div><b>Nenhuma foto aqui</b><span>{filtro === 'revisar' ? 'Tudo revisado nesta seleção.' : 'Troque o filtro ou envie fotos.'}</span></div>
        )}
      </Card>
    </div>
  );
}

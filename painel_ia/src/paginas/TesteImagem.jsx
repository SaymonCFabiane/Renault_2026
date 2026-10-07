import { useEffect, useRef, useState } from 'react';
import { detectarImagem } from '../api.js';
import { rotulo } from '../rotulos.js';
import Caixas from '../components/Caixas.jsx';
import Icon from '../components/Icon.jsx';
import Parametros from '../components/Parametros.jsx';
import { Banner, Button, Card, Stat } from '../components/ui.jsx';

/** Teste por imagem: envia um arquivo para POST /detectar e mostra o resultado. */
export default function TesteImagem({ status }) {
  const entrada = useRef(null);
  const [arquivo, setArquivo] = useState(null);
  const [url, setUrl] = useState(null);
  const [params, setParams] = useState({ confianca: 0.25, imgsz: 640, classes: [] });
  const [res, setRes] = useState(null);
  const [erro, setErro] = useState(null);
  const [enviando, setEnviando] = useState(false);
  const [arrastando, setArrastando] = useState(false);

  useEffect(() => () => url && URL.revokeObjectURL(url), [url]);

  function escolher(f) {
    if (!f) return;
    if (!/^image\/(jpeg|png|webp|bmp)$/.test(f.type)) {
      setErro('Escolha uma imagem JPEG, PNG, WebP ou BMP.');
      return;
    }
    setArquivo(f);
    setUrl(URL.createObjectURL(f));
    setRes(null);
    setErro(null);
  }

  async function enviar() {
    setEnviando(true);
    setErro(null);
    const t0 = performance.now();
    try {
      const r = await detectarImagem(arquivo, params);
      setRes({ ...r, ida_e_volta_ms: performance.now() - t0 });
    } catch (e) {
      setErro(`${e.message} (${e.codigo})`);
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div className="tp-grid">
      <div style={{ gridColumn: 'span 8', minWidth: 0 }} className="tp-stack">
        <Card title="Imagem" extra={arquivo && <Button variant="outline" size="sm" icon="upload" onClick={() => entrada.current.click()}>Trocar imagem</Button>}>
          <input ref={entrada} type="file" accept="image/jpeg,image/png,image/webp,image/bmp" hidden onChange={(e) => escolher(e.target.files[0])} />
          {url ? (
            <div style={{ textAlign: 'center' }}>
              <div className="tp-imagem">
                <img src={url} alt={arquivo?.name} />
                {res && <Caixas deteccoes={res.deteccoes} />}
              </div>
            </div>
          ) : (
            <div role="button" tabIndex={0} className={`tp-drop${arrastando ? ' on' : ''}`} onClick={() => entrada.current.click()}
              onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && entrada.current.click()}
              onDragOver={(e) => { e.preventDefault(); setArrastando(true); }} onDragLeave={() => setArrastando(false)}
              onDrop={(e) => { e.preventDefault(); setArrastando(false); escolher(e.dataTransfer.files[0]); }}>
              <Icon name="image-up" size={32} />
              <b>Arraste uma imagem ou clique para escolher</b>
              <span>JPEG, PNG, WebP ou BMP, até 4 MB</span>
            </div>
          )}
          {erro && <div style={{ marginTop: 12 }}><Banner tone="bad" icon="circle-x" title="Não deu certo">{erro}</Banner></div>}
        </Card>
        {res && (
          <Card title="Resultado">
            <div className="tp-metricas" style={{ marginBottom: 16 }}>
              <Stat value={res.deteccoes.length} label="Objetos" />
              <Stat value={`${Math.round(res.inferencia_ms)} ms`} label="Inferência" />
              <Stat value={`${Math.round(res.processamento_ms)} ms`} label="No servidor (com decodificação)" />
              <Stat value={`${Math.round(res.ida_e_volta_ms)} ms`} label="Ida e volta (com upload)" />
            </div>
            {res.deteccoes.length ? (
              <div className="tp-table-wrap">
                <table className="tp-table">
                  <thead><tr><th>Classe</th><th>Id</th><th>Confiança</th><th>Caixa (x1, y1, x2, y2)</th></tr></thead>
                  <tbody>
                    {res.deteccoes.map((d, i) => (
                      <tr key={i}>
                        <td><b>{rotulo(d.classe)}</b> <span className="tp-cap">{d.classe}</span></td>
                        <td className="num">{d.classe_id}</td>
                        <td className="num">{(d.confianca * 100).toFixed(1)}%</td>
                        <td className="num">{[d.caixa.x1, d.caixa.y1, d.caixa.x2, d.caixa.y2].map((v) => v.toFixed(3)).join(', ')}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : <Banner tone="info" icon="info" title="Nenhum objeto acima da confiança mínima">Diminua a confiança ou confira se a classe está no modelo.</Banner>}
            <details style={{ marginTop: 14 }}>
              <summary className="tp-label" style={{ cursor: 'pointer' }}>Resposta JSON da API</summary>
              <pre className="tp-code">{JSON.stringify(res, null, 2)}</pre>
            </details>
          </Card>
        )}
      </div>
      <div style={{ gridColumn: 'span 4', minWidth: 0 }} className="tp-stack">
        <Card title="Parâmetros">
          <div className="tp-stack" style={{ gap: 16 }}>
            <Parametros valor={params} onChange={setParams} classes={status?.classes} />
            <Button block icon="scan-eye" disabled={!arquivo || enviando || status?.status !== 'ok'} onClick={enviar}>{enviando ? 'Detectando…' : 'Detectar objetos'}</Button>
          </div>
        </Card>
      </div>
    </div>
  );
}

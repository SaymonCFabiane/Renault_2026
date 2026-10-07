import { useState } from 'react';
import { API_PADRAO, apiBase, buscarStatus, salvarApiBase } from '../api.js';
import { rotulo } from '../rotulos.js';
import { Banner, Button, Card, Stat } from '../components/ui.jsx';

/** Status do servidor, modelo carregado e endereço da API. */
export default function Status({ status, erro, atualizar }) {
  const [endereco, setEndereco] = useState(apiBase());
  const [teste, setTeste] = useState(null);
  const [busca, setBusca] = useState('');

  async function testar() {
    setTeste({ tom: 'info', msg: 'Testando…' });
    try {
      const s = await buscarStatus(endereco.replace(/\/+$/, ''));
      setTeste({ tom: 'ok', msg: `Encontrei a API ${s.versao}: modelo ${s.modelo} em ${s.dispositivo}.` });
    } catch (e) {
      setTeste({ tom: 'bad', msg: e.message });
    }
  }

  function salvar() {
    salvarApiBase(endereco);
    atualizar();
    setTeste({ tom: 'ok', msg: 'Endereço salvo neste navegador.' });
  }

  const classes = Object.entries(status?.classes || {}).filter(([id, n]) => !busca || id === busca || n.includes(busca.toLowerCase()) || rotulo(n).includes(busca.toLowerCase()));

  return (
    <div className="tp-grid">
      <div style={{ gridColumn: 'span 8', minWidth: 0 }} className="tp-stack">
        <Card title="Servidor" extra={<Button variant="outline" size="sm" icon="refresh-cw" onClick={atualizar}>Atualizar</Button>}>
          {status ? (
            <>
              <div className="tp-metricas" style={{ marginBottom: 16 }}>
                <Stat value={status.status === 'ok' ? 'No ar' : 'Com erro'} label="Situação" tone={status.status === 'ok' ? 'ok' : 'bad'} />
                <Stat value={status.dispositivo?.toUpperCase() || '–'} label="Dispositivo de inferência" />
                <Stat value={status.conexoes_ativas} label="Conexões abertas" />
                <Stat value={status.versao} label="Versão da API" />
              </div>
              {status.erro && <Banner tone="bad" icon="circle-x" title="O modelo não carregou">{status.erro}</Banner>}
              <dl className="tp-kv">
                <dt>Modelo</dt><dd>{status.modelo}</dd>
                <dt>Classes</dt><dd>{Object.keys(status.classes || {}).length}</dd>
                <dt>Confiança padrão</dt><dd>{Math.round(status.parametros.confianca * 100)}%</dd>
                <dt>imgsz padrão</dt><dd>{status.parametros.imgsz} px</dd>
                <dt>IoU</dt><dd>{status.parametros.iou}</dd>
                <dt>Filtro de classes</dt><dd>{status.parametros.classes?.join(', ') || 'nenhum (todas)'}</dd>
                {status.versoes && <><dt>Bibliotecas</dt><dd>Ultralytics {status.versoes.ultralytics} · PyTorch {status.versoes.torch}</dd></>}
              </dl>
            </>
          ) : (
            <Banner tone="bad" icon="circle-x" title="API fora do ar">
              {erro || 'Sem resposta.'} Para subir: cd detector_api && .venv/bin/python -m app
            </Banner>
          )}
        </Card>
        {status && (
          <Card title="Classes do modelo" extra={<input className="tp-input" style={{ width: 220, height: 36 }} placeholder="Buscar por nome ou id" value={busca} onChange={(e) => setBusca(e.target.value)} aria-label="Buscar classe" />}>
            <div className="tp-table-wrap" style={{ maxHeight: 420 }}>
              <table className="tp-table">
                <thead><tr><th style={{ width: 70 }}>Id</th><th>Nome no modelo</th><th>No app e no painel</th></tr></thead>
                <tbody>{classes.map(([id, n]) => <tr key={id}><td className="num">{id}</td><td>{n}</td><td><b>{rotulo(n)}</b></td></tr>)}</tbody>
              </table>
            </div>
          </Card>
        )}
      </div>
      <div style={{ gridColumn: 'span 4', minWidth: 0 }} className="tp-stack">
        <Card title="Endereço da API">
          <div className="tp-stack" style={{ gap: 12 }}>
            <div>
              <label className="tp-label" htmlFor="api-url">URL</label>
              <input id="api-url" className="tp-input" value={endereco} onChange={(e) => setEndereco(e.target.value)} placeholder={API_PADRAO} />
            </div>
            <p className="tp-cap" style={{ margin: 0 }}>A webcam só funciona com o painel aberto em localhost. Para usar a API de outro computador, troque a URL e libere a origem em TRACEPRO_CORS_ORIGENS.</p>
            {teste && <Banner tone={teste.tom} icon={teste.tom === 'ok' ? 'circle-check' : teste.tom === 'bad' ? 'circle-x' : 'info'} title={teste.msg} />}
            <div className="tp-row">
              <Button variant="outline" icon="wifi" onClick={testar}>Testar</Button>
              <Button icon="check" onClick={salvar}>Salvar</Button>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

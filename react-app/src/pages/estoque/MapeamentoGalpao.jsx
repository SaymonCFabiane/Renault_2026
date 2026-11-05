import { CATALOG, GALPAO, KIT142, SALDO } from '../../data/mock.js';
import { useDemo } from '../../state/useDemo.js';
import { descreverEndereco, enderecoDoMapa, lotesQualidade } from '../../state/logic.js';
import Card, { Col } from '../../components/Card.jsx';
import Button from '../../components/Button.jsx';
import CriticalityTag, { Tag } from '../../components/CriticalityTag.jsx';
import QrCode from '../../components/QrCode.jsx';
import Barcode from '../../components/Barcode.jsx';
import Legend from '../../components/charts/Legend.jsx';
import { Segmented } from '../../components/Tabs.jsx';

const pad = (n) => String(n).padStart(2, '0');
const faixa = (n) => Array.from({ length: n }, (_, i) => pad(i + 1));
const modulo = (end) => end.split('-').slice(0, 3).join('-'); // "A-07-16"
const ROTA = KIT142.filter((i) => i.end).map((i) => i.end);
// Ocupação fictícia e fixa dos demais módulos da Zona A, para a planta parecer um CD em uso.
const ocupadoFicticio = (z, c, m) => z === 'A' && (+c * 13 + +m * 7) % 10 < 4;

const PARTES = [
  ['z', 'Zona', (v) => `Setor de armazenagem ${v}: ${GALPAO[v].nome.toLowerCase()}`],
  ['c', 'Corredor', (v) => `${+v}º corredor da zona`],
  ['m', 'Módulo', (v) => `${+v}º módulo (vão de armazenagem) do corredor`],
  ['n', 'Nível', (v) => `${+v}º nível, contando de baixo para cima`],
  ['p', 'Posição', (v) => `${+v}ª posição do módulo nesse nível`],
];

const saldo = (S, peca) => (peca === 'Farol LED esquerdo' ? (S.mn0457 === 'Recebido' ? 5 : 0) : SALDO[peca]);

function Field({ id, label, value, options, onChange }) {
  return (
    <div>
      <label className="tp-label" htmlFor={id}>{label}</label>
      <select id={id} className="tp-select" value={value} onChange={(e) => onChange(e.target.value)}>
        {options.map((o) => <option key={o}>{o}</option>)}
      </select>
    </div>
  );
}

/** Quem ocupa cada endereço: peças do catálogo e lotes bloqueados na quarentena. */
function ocupantes(S) {
  const o = {};
  for (const [peca, end] of Object.entries(S.enderecos)) o[end] = peca;
  for (const l of lotesQualidade(S)) {
    const n = l.pecas.filter((p) => p.status === 'bloqueada').length;
    if (n) o[l.end] = `${l.remessa} · ${n} ${n === 1 ? 'bloqueada' : 'bloqueadas'}`;
  }
  return o;
}

function Planta({ S, act, ocup }) {
  const m = S.map, Z = GALPAO[m.z];
  const mods = new Set(Object.keys(ocup).map(modulo));
  const rota = ROTA.map(modulo);
  const sel = `${m.z}-${m.c}-${m.m}`;
  return (
    <Card title="Planta do galpão" extra={<Segmented label="Zona" value={m.z} onChange={(z) => act('map', { z })}
      items={Object.entries(GALPAO).map(([z, g]) => ({ value: z, label: `Zona ${z} · ${g.nome}`, icon: z === 'Q' ? 'shield-alert' : 'warehouse' }))} />}>
      <div className="tp-stack" style={{ gap: 16 }}>
        <div className="tp-cd" style={{ '--mods': Z.modulos }} role="grid" aria-label={`Zona ${m.z}: corredores e módulos`}>
          <div className="tp-cd__linha" aria-hidden="true"><span />{faixa(Z.modulos).map((x) => <span key={x}>{x}</span>)}</div>
          {faixa(Z.corredores).map((c) => (
            <div key={c} className="tp-cd__linha" role="row">
              <b>Corr. {c}</b>
              {faixa(Z.modulos).map((mm) => {
                const id = `${m.z}-${c}-${mm}`;
                const cls = rota.includes(id) ? ' hit' : mods.has(id) || ocupadoFicticio(m.z, c, mm) ? ' used' : '';
                return (
                  <button key={mm} type="button" role="gridcell" className={`tp-slot${cls}${id === sel ? ' sel' : ''}`} title={`Módulo ${id}`} aria-label={`Módulo ${id}`}
                    aria-selected={id === sel} onClick={() => act('map', { c, m: mm })} />
                );
              })}
            </div>
          ))}
        </div>
        <div className="tp-row" style={{ justifyContent: 'space-between' }}>
          <Legend items={[...(m.z === 'A' ? [['var(--primary)', 'Rota do KT-0142']] : []), ['var(--data-light)', 'Ocupado'], ['var(--surface-muted)', 'Livre'], ['var(--data)', 'Selecionado']]} />
          <span className="tp-cap">{Z.corredores} {Z.corredores === 1 ? 'corredor' : 'corredores'} · {Z.modulos} módulos · {Z.niveis} níveis · {Z.posicoes} posições</span>
        </div>
        {m.z === 'A' && <p className="tp-cap" style={{ margin: 0 }}>Rota do KT-0142: {ROTA.map((e) => modulo(e)).join(' → ')}</p>}

        <div>
          <div className="tp-h3" style={{ marginBottom: 10 }}>Módulo {sel} · níveis e posições</div>
          <div className="tp-mod" role="grid" aria-label={`Posições do módulo ${sel}`}>
            {faixa(Z.niveis).reverse().map((n) => (
              <div key={n} className="tp-mod__linha" role="row">
                <b>Nível {n}</b>
                {faixa(Z.posicoes).map((p) => {
                  const end = `${sel}-${n}-${p}`, quem = ocup[end];
                  const ficticio = !quem && ocupadoFicticio(m.z, m.c, m.m) && (+n + +p) % 3 === 0;
                  const cls = ROTA.includes(end) ? ' rota' : quem || ficticio ? ' ocupada' : '';
                  return (
                    <button key={p} type="button" role="gridcell" aria-selected={m.n === n && m.p === p}
                      className={`tp-mod__pos${cls}${m.n === n && m.p === p ? ' sel' : ''}`} onClick={() => act('map', { n, p })}>
                      <b>Posição {p}</b>{quem || (ficticio ? 'Outro item' : 'Livre')}
                    </button>
                  );
                })}
              </div>
            ))}
          </div>
        </div>
      </div>
    </Card>
  );
}

// E-ADM3 · Mapeamento do Galpão: endereçamento logístico Zona-Corredor-Módulo-Nível-Posição
export default function MapeamentoGalpao() {
  const { S, act } = useDemo();
  const m = S.map, Z = GALPAO[m.z];
  const end = enderecoDoMapa(m);
  const ocup = ocupantes(S);
  const peca = S.mapPeca, atual = S.enderecos[peca];
  const [, pn, blocante] = CATALOG.find((c) => c[0] === peca);
  const qtd = saldo(S, peca);
  const dono = ocup[end] && ocup[end] !== peca ? ocup[end] : null;
  const opcoes = { z: Object.keys(GALPAO), c: faixa(Z.corredores), m: faixa(Z.modulos), n: faixa(Z.niveis), p: faixa(Z.posicoes) };

  const copiar = async () => {
    try { await navigator.clipboard.writeText(end); } catch { /* sem permissão de área de transferência: o aviso ainda mostra o código */ }
    act('copiado', end);
  };

  return (
    <div className="tp-grid">
      <Col span={5}>
        <div className="tp-stack">
            <Card title="Gerador de endereço">
              <form className="tp-stack" style={{ gap: 14 }} onSubmit={(e) => { e.preventDefault(); act('saveMap'); }}>
                <Field id="m-peca" label="Peça" value={peca} options={CATALOG.map((c) => c[0])} onChange={(v) => act('mapPeca', v)} />
                <div className="tp-grid" style={{ gridTemplateColumns: 'repeat(5, 1fr)', gap: 10 }}>
                  {PARTES.map(([k, rot]) => <Field key={k} id={`m-${k}`} label={rot} value={m[k]} options={opcoes[k]} onChange={(v) => act('map', { [k]: v })} />)}
                </div>
                <div className="tp-stat">
                  <span>Endereço gerado</span>
                  <div className="tp-row" style={{ justifyContent: 'space-between', flexWrap: 'nowrap' }}>
                    <b className="tp-endereco">{end}</b>
                    <Button variant="outline" size="sm" icon="copy" consulta onClick={copiar}>Copiar</Button>
                  </div>
                  <span style={{ fontWeight: 400 }}>{descreverEndereco(end)}</span>
                </div>
                {m.z === 'Q' && <p className="tp-cap" style={{ margin: 0 }}>A Zona Q é reservada às peças bloqueadas pela qualidade. Escolha a Zona A para guardar peças liberadas.</p>}
                {dono && m.z === 'A' && <p className="tp-cap" style={{ margin: 0, color: 'var(--danger)' }}>Esta posição já guarda {dono}.</p>}
                <Button type="submit" icon="check" disabled={end === atual || m.z === 'Q' || !!dono}>
                  {end === atual ? 'Este já é o endereço da peça' : `Guardar ${peca} em ${end}`}
                </Button>
              </form>
            </Card>
            <Card title="Ficha de localização" extra={<Tag tone={qtd ? 'ok' : 'warn'} icon={qtd ? 'package-check' : 'triangle-alert'}>{qtd ? 'ARMAZENADO' : 'EM FALTA'}</Tag>}>
              <dl className="tp-ficha">
                <dt>Produto</dt><dd>{peca}</dd>
                <dt>Código da peça (PN)</dt><dd className="num">{pn.replace('PN ', '')}</dd>
                <dt>Criticidade</dt><dd><CriticalityTag blocante={blocante} /></dd>
                <dt>Quantidade</dt><dd>{qtd} {qtd === 1 ? 'unidade' : 'unidades'}{peca === 'Farol LED esquerdo' && qtd ? ' (mais 1 reservada para o KT-0142)' : ''}</dd>
              </dl>
              <div className="tp-stat" style={{ marginTop: 12 }}>
                <span>Endereço logístico</span>
                <b className="tp-endereco">{atual}</b>
              </div>
              <p className="tp-cap" style={{ margin: '10px 0 0' }}>O endereço é o lugar físico; o PN identifica a peça, que pode ocupar mais de um endereço.</p>
            </Card>
            <Card title="Etiqueta do endereço" extra={<span className="tp-cap">50 × 30 mm</span>}>
              <div className="tp-etiqueta" aria-label={`Prévia da etiqueta do endereço ${end}`}>
                <QrCode seed={end} size={84} />
                <div>
                  <small>TracePro · {m.z === 'Q' ? 'Quarentena' : 'Armazenagem'}</small>
                  <strong>{end}</strong>
                  <small>Corr. {m.c} · Mód. {m.m}<br />Nível {m.n} · Pos. {m.p}</small>
                </div>
                <div className="tp-etiqueta__barras">
                  <Barcode seed={end} height={34} />
                  <small>{end}</small>
                </div>
              </div>
              <Button variant="secondary" block icon="tag" style={{ marginTop: 14 }} onClick={() => act('imprimirEtiqueta', end)}>Imprimir etiqueta</Button>
              <p className="tp-cap" style={{ margin: '10px 0 0' }}>Cole na face da posição. O colaborador bipa o QR ou o código de barras para confirmar que guardou ou pegou a peça no lugar certo.</p>
            </Card>
        </div>
      </Col>
      <Col span={7}>
        <div className="tp-stack">
          <Planta S={S} act={act} ocup={ocup} />
            <Card title="Como ler o endereço">
              <table className="tp-table tp-table--compact">
                <thead><tr><th>Parte</th><th>Código</th><th>Significado</th></tr></thead>
                <tbody>
                  {PARTES.map(([k, rot, desc]) => (
                    <tr key={k}><td><b>{rot}</b></td><td className="num"><b>{m[k]}</b></td><td>{desc(m[k])}</td></tr>
                  ))}
                </tbody>
              </table>
              <p className="tp-cap" style={{ margin: '10px 0 0' }}>Corredores e módulos são numerados a partir da doca de entrada; os níveis, de baixo para cima.</p>
            </Card>
        </div>
      </Col>
    </div>
  );
}

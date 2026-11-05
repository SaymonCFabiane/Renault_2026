import { useDemo } from '../../state/useDemo.js';
import Card, { Col } from '../../components/Card.jsx';
import { Tag } from '../../components/CriticalityTag.jsx';
import DataTable from '../../components/DataTable.jsx';
import Icon from '../../components/Icon.jsx';

// [rótulo, tom]
const NIVEL = {
  G: ['Gerencia', 'ok'],
  C: ['Consulta', 'info'],
  P: ['Só os próprios', 'warn'],
  E: ['Executa no app', 'accent'],
  N: ['Sem acesso', 'nao'],
};
// [área, Carla (Fornecedor), Ricardo (Estoque), Juliana (Cliente), colaboradores no app]
const MATRIZ = [
  ['Ordens de produção, etiquetas e cargas do fornecedor', 'G', 'C', 'N', 'E'],
  ['Recebimento e inspeção de qualidade', 'P', 'G', 'N', 'E'],
  ['Bloqueios, descarte e devolução de peças', 'P', 'G', 'N', 'N'],
  ['Galpão, endereços e rastreabilidade', 'N', 'G', 'N', 'E'],
  ['Pedidos e separação de kits', 'N', 'G', 'P', 'E'],
  ['Painéis e indicadores do Cliente', 'N', 'C', 'G', 'N'],
  ['Acessos e registro de atividades', 'N', 'C', 'N', 'N'],
];
const PERFIS = ['Carla Mendes · Fornecedor', 'Ricardo Alves · Estoque', 'Juliana Costa · Cliente', 'Colaboradores (app)'];

const PRINCIPIOS = [
  ['key-round', 'Acesso por perfil', 'Cada pessoa entra no próprio perfil e só vê as telas do seu setor. O Fornecedor, que é uma empresa externa, vê só as próprias ordens e remessas.'],
  ['eye', 'Visão consolidada só para consulta', 'O gestor do Estoque consulta as telas do Fornecedor e do Cliente, mas não age por eles.'],
  ['shield-check', 'Dados pessoais só com finalidade', 'Nome do colaborador e foto da peça servem para rastrear quem fez cada etapa e comprovar a reprovação. Nada além disso é coletado.'],
  ['scroll-text', 'Tudo registrado', 'Liberações, decisões de qualidade, pedidos e consultas a outros setores ficam no registro abaixo, com data e responsável.'],
];

// E-ADM7 · Acessos e Permissões (governança e LGPD)
export default function Acessos() {
  const { S } = useDemo();
  return (
    <div className="tp-grid">
      <Col span={12}>
        <Card title="Quem acessa o quê" extra={<span className="tp-cap">Fornecedor → Estoque → Cliente</span>}>
          <DataTable head={<><th>Área</th>{PERFIS.map((p) => <th key={p}>{p}</th>)}</>}>
            {MATRIZ.map(([area, ...niveis]) => (
              <tr key={area}>
                <td><b>{area}</b></td>
                {niveis.map((n, i) => <td key={PERFIS[i]}><Tag tone={NIVEL[n][1]}>{NIVEL[n][0].toUpperCase()}</Tag></td>)}
              </tr>
            ))}
          </DataTable>
          <p className="tp-cap" style={{ margin: '12px 0 0' }}>“Só os próprios”: o Fornecedor vê as reprovações e devoluções das remessas dele; o Cliente vê e pede só os próprios kits.</p>
        </Card>
      </Col>
      <Col span={5}>
        <Card title="Governança e LGPD">
          <div className="tp-stack" style={{ gap: 14 }}>
            {PRINCIPIOS.map(([ic, t, d]) => (
              <div key={t} className="tp-row" style={{ alignItems: 'flex-start', flexWrap: 'nowrap', gap: 12 }}>
                <span className="tp-iconbox tp-iconbox--data"><Icon name={ic} /></span>
                <div><b>{t}</b><p className="tp-cap" style={{ margin: '2px 0 0' }}>{d}</p></div>
              </div>
            ))}
          </div>
        </Card>
      </Col>
      <Col span={7}>
        <Card title="Registro de atividades" extra={<span className="tp-cap">{S.auditoria.length} registros</span>}>
          <DataTable compact head={<><th style={{ width: 110 }}>Quando</th><th style={{ width: 200 }}>Quem</th><th>O quê</th></>}>
            {S.auditoria.map((r, i) => (
              <tr key={S.auditoria.length - i}>
                <td className="num">{r.quando}</td><td>{r.quem}</td><td>{r.oque}</td>
              </tr>
            ))}
          </DataTable>
        </Card>
      </Col>
    </div>
  );
}

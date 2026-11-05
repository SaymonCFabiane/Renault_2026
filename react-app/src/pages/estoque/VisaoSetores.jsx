import { useEffect, useRef, useState } from 'react';
import { useDemo } from '../../state/useDemo.js';
import { LeituraContext } from '../../state/somenteLeitura.js';
import Card, { Col } from '../../components/Card.jsx';
import { Tag } from '../../components/CriticalityTag.jsx';
import { Segmented } from '../../components/Tabs.jsx';
import FornecedorDashboard from '../fornecedor/Dashboard.jsx';
import OrdensProducao from '../fornecedor/OrdensProducao.jsx';
import ValidacaoCarga from '../fornecedor/ValidacaoCarga.jsx';
import ClienteDashboard from '../cliente/Dashboard.jsx';
import AcompanhamentoKits from '../cliente/AcompanhamentoKits.jsx';

const CARLA = 'Carla Mendes (Fornecedor)', JULIANA = 'Juliana Costa (Cliente)';
const VISOES = [
  { code: 'F-ADM1', label: 'Fornecedor · Painel', icon: 'factory', dono: CARLA, Tela: FornecedorDashboard },
  { code: 'F-ADM2', label: 'Ordens de Produção', icon: 'clipboard-list', dono: CARLA, Tela: OrdensProducao },
  { code: 'F-ADM3', label: 'Validação de Carga', icon: 'truck', dono: CARLA, Tela: ValidacaoCarga },
  { code: 'T-ADM1', label: 'Cliente · Painel', icon: 'flask-conical', dono: JULIANA, Tela: ClienteDashboard },
  { code: 'T-ADM3', label: 'Acompanhamento de Kits', icon: 'square-kanban', dono: JULIANA, Tela: AcompanhamentoKits },
];

// E-ADM6 · Visão dos Setores: o gestor do Estoque consulta as telas do Fornecedor e do Cliente, sem agir.
export default function VisaoSetores() {
  const { act } = useDemo();
  const [aba, setAba] = useState('F-ADM1');
  const v = VISOES.find((x) => x.code === aba);
  const registrado = useRef(null);

  // Toda consulta entra no registro de atividades (uma vez por troca de tela).
  useEffect(() => {
    if (registrado.current === aba) return;
    registrado.current = aba;
    act('consultar', `Consultou “${v.label}” de ${v.dono.replace(' (', ' · ').replace(')', '')}, somente leitura`);
  }, [aba, v, act]);

  const ir = (code) => { if (VISOES.some((x) => x.code === code)) setAba(code); };

  return (
    <div className="tp-grid">
      <Col span={12}>
        <Card title="Visão dos setores" extra={<Tag tone="info" icon="eye">SOMENTE LEITURA</Tag>}>
          <Segmented label="Tela consultada" value={aba} onChange={setAba} items={VISOES.map((x) => ({ value: x.code, label: x.label, icon: x.icon }))} />
          <p className="tp-cap" style={{ margin: '12px 0 0' }}>
            Você vê a tela de <b>{v.dono}</b> como ela vê. Pode consultar tudo; liberar, autorizar e pedir continuam com o dono do setor. Cada consulta fica no registro de atividades.
          </p>
        </Card>
      </Col>
      <Col span={12}>
        <LeituraContext.Provider value={{ ir, dono: v.dono }}>
          <div className="tp-leitura"><v.Tela /></div>
        </LeituraContext.Provider>
      </Col>
    </div>
  );
}

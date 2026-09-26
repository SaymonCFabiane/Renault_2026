import { Navigate, Route, Routes } from 'react-router-dom';
import { PROFILES } from './data/mock.js';
import WebShell from './layout/WebShell.jsx';
import ProfilePicker from './pages/ProfilePicker.jsx';
import FornecedorDashboard from './pages/fornecedor/Dashboard.jsx';
import OrdensProducao from './pages/fornecedor/OrdensProducao.jsx';
import ValidacaoCarga from './pages/fornecedor/ValidacaoCarga.jsx';
import EstoqueDashboard from './pages/estoque/Dashboard.jsx';
import PedidosKits from './pages/estoque/PedidosKits.jsx';
import MapeamentoGalpao from './pages/estoque/MapeamentoGalpao.jsx';
import Rastreabilidade from './pages/estoque/Rastreabilidade.jsx';
import TestesDashboard from './pages/testes/Dashboard.jsx';
import NovaRequisicao from './pages/testes/NovaRequisicao.jsx';
import AcompanhamentoKits from './pages/testes/AcompanhamentoKits.jsx';

// Cada módulo é de um único administrador: a rota define o perfil ativo.
export default function App() {
  return (
    <Routes>
      <Route path="/" element={<ProfilePicker />} />
      <Route path="/fornecedor" element={<WebShell profile={PROFILES.carla} />}>
        <Route index element={<Navigate to="painel" replace />} />
        <Route path="painel" element={<FornecedorDashboard />} />
        <Route path="ordens" element={<OrdensProducao />} />
        <Route path="validacao" element={<ValidacaoCarga />} />
      </Route>
      <Route path="/estoque" element={<WebShell profile={PROFILES.ricardo} />}>
        <Route index element={<Navigate to="painel" replace />} />
        <Route path="painel" element={<EstoqueDashboard />} />
        <Route path="pedidos" element={<PedidosKits />} />
        <Route path="galpao" element={<MapeamentoGalpao />} />
        <Route path="rastreabilidade" element={<Rastreabilidade />} />
      </Route>
      <Route path="/testes" element={<WebShell profile={PROFILES.juliana} />}>
        <Route index element={<Navigate to="painel" replace />} />
        <Route path="painel" element={<TestesDashboard />} />
        <Route path="requisicao" element={<NovaRequisicao />} />
        <Route path="acompanhamento" element={<AcompanhamentoKits />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

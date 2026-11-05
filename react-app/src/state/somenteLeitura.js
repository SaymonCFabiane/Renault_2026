import { createContext, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { PATHS } from '../data/mock.js';

// Telas de outro setor abertas pelo Ricardo em "Visão dos Setores": só consulta, sem ações.
export const LeituraContext = createContext(null);
export const useLeitura = () => useContext(LeituraContext);

/** Vai para outra tela do módulo; dentro da visão de consulta, troca a aba em vez de sair do Estoque. */
export function useIrPara() {
  const leitura = useLeitura();
  const navigate = useNavigate();
  return (code) => (leitura ? leitura.ir(code) : navigate(PATHS[code]));
}

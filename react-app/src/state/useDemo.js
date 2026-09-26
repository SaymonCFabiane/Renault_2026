import { createContext, useContext } from 'react';

export const DemoContext = createContext(null);

// Acesso ao estado da demo ({ S, act }) em qualquer componente.
export function useDemo() {
  return useContext(DemoContext);
}

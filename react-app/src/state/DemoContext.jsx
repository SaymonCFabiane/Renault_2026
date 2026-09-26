import { useCallback, useEffect, useMemo, useReducer } from 'react';
import { fresh, reducer } from './logic.js';
import { DemoContext } from './useDemo.js';

// Estado global da demo: só em memória; ao recarregar, volta ao início.
export function DemoProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, undefined, fresh);
  const act = useCallback((type, v) => dispatch({ type, v }), []);

  useEffect(() => {
    document.documentElement.dataset.theme = state.theme;
  }, [state.theme]);

  const toastId = state.toast?.id;
  useEffect(() => {
    if (!toastId) return undefined;
    const t = setTimeout(() => act('clearToast', toastId), 3400);
    return () => clearTimeout(t);
  }, [toastId, act]);

  const value = useMemo(() => ({ S: state, act }), [state, act]);
  return <DemoContext.Provider value={value}>{children}</DemoContext.Provider>;
}


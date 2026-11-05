// Código de barras fictício e determinístico (estilo Code 128, não é legível): só para ilustrar etiquetas.
// Mesmo algoritmo do app (BarcodePainter): barras e espaços de 1 a 3 módulos, com guardas de início e fim.
function larguras(seed) {
  let h = 0;
  for (const ch of seed) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  const out = [2, 1, 1, 2];
  for (const ch of seed) {
    for (let k = 0; k < 6; k++) {
      h ^= h << 13; h >>>= 0; h ^= h >> 17; h ^= h << 5; h >>>= 0;
      out.push(1 + ((h + ch.charCodeAt(0)) % 3));
    }
  }
  return [...out, 2, 3, 3, 1, 1, 1, 2];
}

/** Barras (os índices pares) com a posição x de cada uma. */
function barras(ws) {
  const out = [];
  ws.reduce((x, w, i) => {
    if (i % 2 === 0) out.push([x, w]);
    return x + w;
  }, 0);
  return out;
}

export default function Barcode({ seed, height = 36 }) {
  const ws = larguras(seed);
  const total = ws.reduce((a, b) => a + b, 0);
  return (
    <svg viewBox={`0 0 ${total} ${height}`} width="100%" height={height} preserveAspectRatio="none" role="img" aria-label={`Código de barras de ${seed}`}>
      <rect width={total} height={height} fill="#fff" />
      <g fill="#111">{barras(ws).map(([x, w]) => <rect key={x} x={x} y={0} width={w + 0.15} height={height} />)}</g>
    </svg>
  );
}

// QR fictício determinístico (não é legível): só para ilustrar etiquetas e rastreabilidade.
function qrModules(seed) {
  let h = 0;
  for (const ch of seed) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  const out = [];
  for (let y = 0; y < 21; y++) for (let x = 0; x < 21; x++) {
    if ((x < 8 && y < 8) || (x > 12 && y < 8) || (x < 8 && y > 12)) continue;
    h ^= h << 13; h >>>= 0; h ^= h >> 17; h ^= h << 5; h >>>= 0;
    if (h / 4294967296 > 0.52) out.push([x, y]);
  }
  return out;
}

export default function QrCode({ seed, size = 64 }) {
  const u = size / 21;
  const cells = qrModules(seed).map(([x, y]) => <rect key={`${x}-${y}`} x={x * u} y={y * u} width={u + 0.2} height={u + 0.2} />);
  const finder = (x, y) => (
    <g key={`f${x}${y}`}>
      <rect x={x * u} y={y * u} width={7 * u} height={7 * u} fill="#111" />
      <rect x={(x + 1) * u} y={(y + 1) * u} width={5 * u} height={5 * u} fill="#fff" />
      <rect x={(x + 2) * u} y={(y + 2) * u} width={3 * u} height={3 * u} fill="#111" />
    </g>
  );
  return (
    <svg viewBox={`0 0 ${size} ${size}`} width={size} height={size} role="img" aria-label={`QR Code de ${seed}`}>
      <rect width={size} height={size} fill="#fff" />
      <g fill="#111">{cells}</g>
      {finder(0, 0)}{finder(14, 0)}{finder(0, 14)}
    </svg>
  );
}

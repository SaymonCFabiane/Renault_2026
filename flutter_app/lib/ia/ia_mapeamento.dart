import 'dart:ui';

/// Região de um recorte central de aspecto [aspecto] dentro de um quadro de aspecto [base],
/// como fração da largura e da altura do quadro.
({double l, double a}) _regiao(double aspecto, double base) => aspecto < base ? (l: aspecto / base, a: 1.0) : (l: 1.0, a: base / aspecto);

/// Converte uma caixa normalizada no quadro analisado para coordenadas normalizadas do visor.
///
/// Todos os aspectos são largura/altura com a imagem "em pé". O quadro enviado à API é um recorte
/// central (4:3) do stream da câmera, e o stream tem o mesmo enquadramento da prévia (os dois usam
/// a mesma resolução). O visor mostra a prévia em modo "cover". Com aspectos iguais, nada muda.
Rect mapearCaixa(Rect caixa, {required double aspectoAnalise, required double aspectoPrevia, required double aspectoVisor}) {
  final an = _regiao(aspectoAnalise, aspectoPrevia);
  // Parte da prévia que aparece no visor (cover).
  final visL = aspectoPrevia > aspectoVisor ? aspectoVisor / aspectoPrevia : 1.0;
  final visA = aspectoPrevia > aspectoVisor ? 1.0 : aspectoPrevia / aspectoVisor;
  double x(double v) => .5 + (v - .5) * an.l / visL;
  double y(double v) => .5 + (v - .5) * an.a / visA;
  return Rect.fromLTRB(x(caixa.left), y(caixa.top), x(caixa.right), y(caixa.bottom));
}

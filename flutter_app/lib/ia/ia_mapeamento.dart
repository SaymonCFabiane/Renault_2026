import 'dart:ui';

/// Região de um recorte central do sensor, como fração da largura e altura do sensor.
({double l, double a}) _regiao(double aspecto, double aspectoSensor) =>
    aspecto < aspectoSensor ? (l: aspecto / aspectoSensor, a: 1.0) : (l: 1.0, a: aspectoSensor / aspecto);

/// Converte uma caixa normalizada no quadro analisado para coordenadas normalizadas do visor.
///
/// Todos os aspectos são largura/altura com a imagem "em pé". A prévia e o quadro analisado
/// são recortes centrais do mesmo sensor (suposto 4:3, isto é, 3/4 em pé), e o visor mostra a
/// prévia em modo "cover". Quando prévia, análise e visor têm o mesmo aspecto, nada muda.
Rect mapearCaixa(
  Rect caixa, {
  required double aspectoAnalise,
  required double aspectoPrevia,
  required double aspectoVisor,
  double aspectoSensor = 3 / 4,
}) {
  final an = _regiao(aspectoAnalise, aspectoSensor);
  final pr = _regiao(aspectoPrevia, aspectoSensor);
  // Parte da prévia que aparece no visor (cover).
  final visL = aspectoPrevia > aspectoVisor ? pr.l * aspectoVisor / aspectoPrevia : pr.l;
  final visA = aspectoPrevia > aspectoVisor ? pr.a : pr.a * aspectoPrevia / aspectoVisor;
  double x(double v) => .5 + ((.5 + (v - .5) * an.l) - .5) / visL;
  double y(double v) => .5 + ((.5 + (v - .5) * an.a) - .5) / visA;
  return Rect.fromLTRB(x(caixa.left), y(caixa.top), x(caixa.right), y(caixa.bottom));
}

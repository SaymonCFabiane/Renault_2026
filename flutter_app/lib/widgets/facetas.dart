import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Facetas translúcidas (como as peças de cristal da identidade Renault Geely do Brasil),
/// desenhadas por cima do degradê do cabeçalho.
class FacetasMarca extends StatelessWidget {
  const FacetasMarca({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(child: CustomPaint(painter: _Facetas(), size: Size.infinite));
}

class _Facetas extends CustomPainter {
  const _Facetas();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    void tri(List<Offset> p, Color c) => canvas.drawPath(Path()..addPolygon(p, true), Paint()..color = c);
    final branco = Colors.white;
    tri([Offset(w * .62, 0), Offset(w, 0), Offset(w * .86, h * .72)], TpMarca.roxo.withValues(alpha: .55));
    tri([Offset(w * .86, h * .72), Offset(w, 0), Offset(w, h)], branco.withValues(alpha: .07));
    tri([Offset(w * .72, h), Offset(w * .86, h * .72), Offset(w, h)], TpMarca.turquesa.withValues(alpha: .16));
    tri([Offset(w * .62, 0), Offset(w * .86, h * .72), Offset(w * .74, h * .2)], TpMarca.lavanda.withValues(alpha: .10));
    tri([Offset(0, h), Offset(w * .18, h * .55), Offset(w * .32, h)], TpMarca.lilas.withValues(alpha: .25));
  }

  @override
  bool shouldRepaint(_Facetas old) => false;
}

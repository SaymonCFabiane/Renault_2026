import 'package:flutter/material.dart';

/// QR fictício determinístico (não é legível): ilustra etiquetas e leituras.
class QrPainter extends CustomPainter {
  QrPainter(this.seed, {this.color = const Color(0xFF111111), this.background = Colors.white});
  final String seed;
  final Color color, background;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 21;
    final u = size.width / n;
    final ink = Paint()..color = color;
    if (background.a > 0) canvas.drawRect(Offset.zero & size, Paint()..color = background);
    var h = 0;
    for (final ch in seed.codeUnits) {
      h = (h * 31 + ch) & 0xFFFFFFFF;
    }
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if ((x < 8 && y < 8) || (x > 12 && y < 8) || (x < 8 && y > 12)) continue;
        h = (h ^ (h << 13)) & 0xFFFFFFFF;
        h = h ^ (h >> 17);
        h = (h ^ (h << 5)) & 0xFFFFFFFF;
        if (h / 4294967296 > .52) canvas.drawRect(Rect.fromLTWH(x * u, y * u, u + .2, u + .2), ink);
      }
    }
    void finder(int x, int y) {
      canvas.drawRect(Rect.fromLTWH(x * u, y * u, 7 * u, 7 * u), ink);
      canvas.drawRect(Rect.fromLTWH((x + 1) * u, (y + 1) * u, 5 * u, 5 * u), Paint()..color = background.a > 0 ? background : const Color(0xFF0D1A20));
      canvas.drawRect(Rect.fromLTWH((x + 2) * u, (y + 2) * u, 3 * u, 3 * u), ink);
    }

    finder(0, 0);
    finder(14, 0);
    finder(0, 14);
  }

  @override
  bool shouldRepaint(QrPainter old) => old.seed != seed || old.color != color;
}

class QrCode extends StatelessWidget {
  const QrCode(this.seed, {super.key, this.size = 64});
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(label: 'QR Code de $seed', child: CustomPaint(size: Size.square(size), painter: QrPainter(seed)));
}

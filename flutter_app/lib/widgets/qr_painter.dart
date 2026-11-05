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
      canvas.drawRect(Rect.fromLTWH((x + 1) * u, (y + 1) * u, 5 * u, 5 * u), Paint()..color = background.a > 0 ? background : const Color(0xFF0B0620));
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

/// Código de barras fictício e determinístico (estilo Code 128, não é legível): barras e espaços de 1 a 3 módulos.
class BarcodePainter extends CustomPainter {
  BarcodePainter(this.seed, {this.color = const Color(0xFF111111)});
  final String seed;
  final Color color;

  /// Larguras alternando barra/espaço, com guardas de início e fim.
  static List<int> larguras(String seed) {
    var h = 0;
    for (final ch in seed.codeUnits) {
      h = (h * 31 + ch) & 0xFFFFFFFF;
    }
    final out = <int>[2, 1, 1, 2]; // guarda de início
    for (final ch in seed.codeUnits) {
      for (var k = 0; k < 6; k++) {
        h = (h ^ (h << 13)) & 0xFFFFFFFF;
        h = h ^ (h >> 17);
        h = (h ^ (h << 5)) & 0xFFFFFFFF;
        out.add(1 + (h + ch) % 3);
      }
    }
    out.addAll([2, 3, 3, 1, 1, 1, 2]); // guarda de fim (termina em barra)
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ws = larguras(seed);
    final total = ws.fold<int>(0, (a, b) => a + b);
    final u = size.width / total;
    final ink = Paint()..color = color;
    var x = 0.0;
    for (var i = 0; i < ws.length; i++) {
      if (i.isEven) canvas.drawRect(Rect.fromLTWH(x, 0, ws[i] * u + .15, size.height), ink);
      x += ws[i] * u;
    }
  }

  @override
  bool shouldRepaint(BarcodePainter old) => old.seed != seed || old.color != color;
}

class Barcode extends StatelessWidget {
  const Barcode(this.seed, {super.key, this.height = 40});
  final String seed;
  final double height;

  @override
  Widget build(BuildContext context) =>
      Semantics(label: 'Código de barras de $seed', child: CustomPaint(size: Size(double.infinity, height), painter: BarcodePainter(seed)));
}

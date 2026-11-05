import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'qr_painter.dart';

/// Prévia da etiqueta térmica da peça: retângulo horizontal 50×30 mm (sempre em papel branco),
/// com QR Code, dados da peça e código de barras.
class LabelCard extends StatelessWidget {
  const LabelCard({super.key, required this.code, required this.index, required this.total});
  final String code;
  final int index, total;

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    const ink = TextStyle(color: Color(0xFF111111), fontSize: 12, height: 1.3);
    return AspectRatio(
      aspectRatio: 50 / 30,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
          border: Border.all(color: const Color(0xFF9AA9B1), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Row(children: [
              LayoutBuilder(builder: (context, box) => QrCode(code, size: box.maxHeight)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(code, style: ink.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Text('Farol LED esquerdo', style: ink),
                  Text('Peça ${two(index)}/${two(total)} · LT-2026-088', style: ink),
                  const Text('Fab. 24/09/2026 · MetalSul', style: ink),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Barcode(code, height: 36),
          const SizedBox(height: 2),
          Text(code, textAlign: TextAlign.center, style: ink.copyWith(fontSize: 11, letterSpacing: 2, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      ),
    );
  }
}

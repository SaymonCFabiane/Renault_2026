import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'qr_painter.dart';

/// Prévia de etiqueta térmica de peça (sempre em papel branco).
class LabelCard extends StatelessWidget {
  const LabelCard({super.key, required this.code, required this.index, required this.total});
  final String code;
  final int index, total;

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    const ink = TextStyle(color: Color(0xFF111111), fontSize: 12, height: 1.3);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
        border: Border.all(color: const Color(0xFF9AA9B1), width: 1.5),
      ),
      child: Row(children: [
        QrCode(code, size: 64),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(code, style: ink.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
            const Text('Farol LED esquerdo', style: ink),
            Text('Peça ${two(index)}/${two(total)} · LT-2026-088', style: ink),
            const Text('Fab. 24/09/2026 · MetalSul Autopeças', style: ink),
          ]),
        ),
      ]),
    );
  }
}

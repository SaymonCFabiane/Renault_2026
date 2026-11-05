import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../theme/tokens.dart';

/// Linha do histórico de leituras: verde (OK), vermelha (inválida) ou amarela
/// (lida, mas bloqueada pela inspeção de qualidade; [bloqueada] traz o motivo e o endereço é o da quarentena).
class ReadRow extends StatelessWidget {
  const ReadRow(this.read, {super.key, this.bloqueada});
  final ScanRead read;
  final String? bloqueada;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final ok = read.ok, blq = ok && bloqueada != null;
    final (Color fundo, Color borda, Color bola, IconData icone, Color cor) = blq
        ? (c.surface, c.warning, c.warningBg, LucideIcons.shieldAlert, c.warningText)
        : ok
            ? (c.surface, c.line, c.successBg, LucideIcons.check, c.success)
            : (c.dangerBg, c.danger, c.danger, LucideIcons.x, c.onStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
        border: Border.all(color: borda, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bola, shape: BoxShape.circle),
          child: Icon(icone, size: 18, color: cor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(read.code, style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
            Text(blq ? 'Bloqueada · $bloqueada · $quarentena' : ok ? (read.sub ?? 'Leitura OK') : read.msg!,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: blq ? c.warningText : ok ? c.textSecondary : c.danger,
                    fontWeight: ok && !blq ? FontWeight.w400 : FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(read.time, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

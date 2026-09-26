import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../theme/tokens.dart';

/// Linha do histórico de leituras: verde (OK) ou vermelha (inválida).
class ReadRow extends StatelessWidget {
  const ReadRow(this.read, {super.key});
  final ScanRead read;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final ok = read.ok;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? c.surface : c.dangerBg,
        borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
        border: Border.all(color: ok ? c.line : c.danger, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: ok ? c.successBg : c.danger, shape: BoxShape.circle),
          child: Icon(ok ? LucideIcons.check : LucideIcons.x, size: 18, color: ok ? c.success : c.onStatus),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(read.code, style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
            Text(ok ? (read.sub ?? 'Leitura OK') : read.msg!,
                style: TextStyle(fontSize: 13, height: 1.3, color: ok ? c.textSecondary : c.danger, fontWeight: ok ? FontWeight.w400 : FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(read.time, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

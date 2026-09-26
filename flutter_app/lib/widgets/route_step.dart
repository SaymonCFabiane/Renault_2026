import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'arrow_text.dart';
import '../theme/tokens.dart';

/// Card do passo atual da rota: corredor → prateleira → quantidade.
class RouteStepCard extends StatelessWidget {
  const RouteStepCard({super.key, required this.eyebrow, required this.where, this.detail, this.warning = false, this.extra});
  final String eyebrow, where;
  final String? detail;
  final bool warning;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final fg = warning ? const Color(0xFF1E2F38) : c.onPrimary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: warning ? c.warning : c.primary, borderRadius: BorderRadius.circular(TpRadius.radiusCard)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow, style: TextStyle(color: fg.withValues(alpha: .9), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .3)),
        const SizedBox(height: 6),
        ArrowText(where, style: TpText.step.copyWith(color: fg)),
        if (detail != null) ...[const SizedBox(height: 6), Text(detail!, style: TextStyle(color: fg.withValues(alpha: .9), fontSize: 15))],
        if (extra != null) ...[const SizedBox(height: 8), extra!],
      ]),
    );
  }
}

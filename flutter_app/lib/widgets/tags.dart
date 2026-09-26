import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum TagTone { blocante, nao, info, accent, ok, warn }

class TpTag extends StatelessWidget {
  const TpTag(this.label, {super.key, this.tone = TagTone.info, this.icon});
  final String label;
  final TagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final (Color bg, Color fg) = switch (tone) {
      TagTone.blocante => (c.dangerBg, c.danger),
      // Defeito 6: texto em `text` sobre surface-muted (> 4,5:1 nos dois temas).
      TagTone.nao => (c.surfaceMuted, c.text),
      TagTone.info => (c.primarySoft, c.primary),
      TagTone.accent => (c.accentBg, c.accentText),
      TagTone.ok => (c.successBg, c.success),
      TagTone.warn => (c.warningBg, c.warningText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TpRadius.radiusPill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
        Flexible(child: Text(label, style: TpText.tag.copyWith(color: fg))),
      ]),
    );
  }
}

/// BLOCANTE (cadeado, vermelho) ou NÃO-BLOCANTE (neutro): em toda lista de peças.
class CriticalityTag extends StatelessWidget {
  const CriticalityTag({super.key, required this.blocking});
  final bool blocking;

  @override
  Widget build(BuildContext context) =>
      blocking ? const TpTag('BLOCANTE', tone: TagTone.blocante, icon: LucideIcons.lock) : const TpTag('NÃO-BLOCANTE', tone: TagTone.nao);
}

class PrioTag extends StatelessWidget {
  const PrioTag(this.prio, {super.key});
  final String prio;

  @override
  Widget build(BuildContext context) => switch (prio) {
        'Alta' => const TpTag('ALTA / URGENTE', tone: TagTone.blocante),
        'Média' => const TpTag('MÉDIA', tone: TagTone.warn),
        _ => TpTag(prio.toUpperCase()),
      };
}

enum StatusTone { ok, bad, warn, accent, info, muted }

StatusTone statusTone(String s) {
  const ok = 'Recebido|Concluída|Entregue Completo|Pronto|Disponível|Liberado|OK|Lida|Etiquetad|impressas|Aceito|chegou|Na doca';
  if (RegExp(ok).hasMatch(s)) return StatusTone.ok;
  if (RegExp('Problema|Parado|Indisponível|Travad|Faltou|Cancel|Faltam').hasMatch(s)) return StatusTone.bad;
  if (RegExp('Parcial|Aguardando Aprovação|Conferência').hasMatch(s)) return StatusTone.warn;
  if (RegExp('Pendente|Aguardando').hasMatch(s)) return StatusTone.accent;
  return StatusTone.info;
}

/// Status em texto colorido, sem badge.
class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key, this.tone});
  final String text;
  final StatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final color = switch (tone ?? statusTone(text)) {
      StatusTone.ok => c.success,
      StatusTone.bad => c.danger,
      StatusTone.warn => c.warningText,
      StatusTone.accent => c.accentText,
      StatusTone.info => c.primary,
      StatusTone.muted => c.textSecondary,
    };
    return Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15));
  }
}

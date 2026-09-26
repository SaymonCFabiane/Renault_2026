import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';
import 'tags.dart';

enum KitItemState { pending, current, done, missing, locked }

/// Item de kit com tag de criticidade. Bloqueado (cadeado) até a leitura anterior.
class KitItem extends StatelessWidget {
  const KitItem(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.blocking,
      required this.state,
      this.onTap,
      this.selected = false,
      this.icon,
      this.showTag = true});
  final String title, subtitle;
  final bool blocking, selected, showTag;
  final KitItemState state;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final (Color bg, Color border, Color icBg, Color icFg, IconData ic) = switch (state) {
      KitItemState.done => (c.successBg, Colors.transparent, c.success, c.onStatus, LucideIcons.check),
      KitItemState.current => (c.surface, c.primary, c.primary, c.onPrimary, LucideIcons.hand),
      KitItemState.missing => (c.warningBg, c.warning, c.warning, const Color(0xFF1E2F38), LucideIcons.triangleAlert),
      KitItemState.locked => (c.surface, c.line, c.surfaceMuted, c.textSecondary, LucideIcons.lock),
      KitItemState.pending => (
          c.surface,
          selected ? c.primary : c.line,
          selected ? c.primary : c.surfaceMuted,
          selected ? c.onPrimary : c.textSecondary,
          LucideIcons.scanLine
        ),
    };
    final content = Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: icBg, shape: BoxShape.circle), child: Icon(icon ?? ic, size: 18, color: icFg)),
      const SizedBox(width: 12),
      Expanded(
        child: Opacity(
          opacity: state == KitItemState.locked ? .6 : 1,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.35)),
            Text(subtitle, style: TextStyle(fontSize: 13, height: 1.35, color: c.textSecondary)),
            if (showTag) ...[const SizedBox(height: 6), CriticalityTag(blocking: blocking)],
          ]),
        ),
      ),
    ]);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
          side: BorderSide(color: border, width: state == KitItemState.current || selected ? 2 : 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child:
              ConstrainedBox(constraints: const BoxConstraints(minHeight: TpSize.touchMin), child: Padding(padding: const EdgeInsets.all(12), child: content))),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class TpCard extends StatelessWidget {
  const TpCard({super.key, required this.child, this.onTap, this.highlight, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final VoidCallback? onTap;
  final Color? highlight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TpRadius.radiusCard),
      side: highlight != null ? BorderSide(color: highlight!, width: 2) : BorderSide.none,
    );
    return Material(
      color: c.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Linha "título à esquerda, status à direita".
class CardHeadRow extends StatelessWidget {
  const CardHeadRow({super.key, required this.title, required this.trailing});
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: TpText.cardTitle)),
        const SizedBox(width: 8),
        trailing,
      ]);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: TpText.h3);
}

class Muted extends StatelessWidget {
  const Muted(this.text, {super.key, this.size = 15, this.weight = FontWeight.w400});
  final String text;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: TpColors.of(context).textSecondary, fontSize: size, height: 1.35, fontWeight: weight));
}

class TpProgress extends StatelessWidget {
  const TpProgress(this.value, {super.key, this.ok = false});
  final double value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(TpRadius.radiusPill),
      child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, backgroundColor: c.surfaceMuted, color: ok ? c.success : c.data),
    );
  }
}

enum StatTone { none, ok, bad, warn }

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.tone = StatTone.none});
  final String label, value;
  final StatTone tone;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final (Color bg, Color fg) = switch (tone) {
      StatTone.none => (c.surfaceMuted, c.text),
      StatTone.ok => (c.successBg, c.success),
      StatTone.bad => (c.dangerBg, c.danger),
      StatTone.warn => (c.warningBg, c.warningText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TpRadius.radiusIcon)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TpText.label.copyWith(color: c.textSecondary)),
        Text(value,
            style: TextStyle(fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w800, color: fg, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.text, this.action});
  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle), child: Icon(icon, color: c.textSecondary)),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        if (text != null) ...[const SizedBox(height: 4), Text(text!, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary))],
        if (action != null) ...[const SizedBox(height: 14), action!],
      ]),
    );
  }
}

/// Avatar circular com iniciais.
class TpAvatar extends StatelessWidget {
  const TpAvatar(this.initials, {super.key, this.size = 44});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
      child: Text(initials, style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: size * .34)),
    );
  }
}

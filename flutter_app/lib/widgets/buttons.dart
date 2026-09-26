import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum TpVariant { primary, secondary, outline, ghost, success, danger, dangerOutline, accent }

/// Botão em pílula. Grande (52px) por padrão no mobile; `small` = 40px.
class TpButton extends StatelessWidget {
  const TpButton(
      {super.key,
      required this.label,
      this.icon,
      this.onPressed,
      this.variant = TpVariant.primary,
      this.block = false,
      this.small = false,
      this.semanticLabel});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final TpVariant variant;
  final bool block, small;

  /// Rótulo acessível para botões só com ícone.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final (Color bg, Color fg, Color? border) = switch (variant) {
      TpVariant.primary => (c.primary, c.onPrimary, null),
      TpVariant.secondary => (c.primarySoft, c.text, null),
      TpVariant.outline => (c.surface, c.text, c.primary),
      TpVariant.ghost => (Colors.transparent, c.primary, null),
      TpVariant.success => (c.success, c.onStatus, null),
      TpVariant.danger => (c.danger, c.onStatus, null),
      TpVariant.dangerOutline => (c.surface, c.danger, c.danger),
      // Defeito 6: fundo accent-text + on-status atinge 4,5:1 nos dois temas.
      TpVariant.accent => (c.accentText, c.onStatus, null),
    };
    final enabled = onPressed != null;
    final child = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: small ? 18 : 20, color: fg),
        if (icon != null && label.isNotEmpty) const SizedBox(width: 8),
        if (label.isNotEmpty)
          Flexible(
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: small ? 14 : 16, height: 1.2)),
          ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : .45,
        child: Material(
          color: bg,
          shape: StadiumBorder(side: border != null ? BorderSide(color: border, width: 1.5) : BorderSide.none),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: small ? 40 : TpSize.bigButton, minWidth: small ? 40 : TpSize.touchMin),
              child: Padding(padding: EdgeInsets.symmetric(horizontal: small ? 16 : 22, vertical: 8), child: Center(widthFactor: 1, child: child)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Link sublinhado (ações "Simular…").
class TpLink extends StatelessWidget {
  const TpLink({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TpSize.touchMin),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child:
                Text(label, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: c.primary)),
          ),
        ),
      ),
    );
  }
}

/// Botão redondo de ícone com alvo de 48px e tooltip.
class TpIconButton extends StatelessWidget {
  const TpIconButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.color, this.badge});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: TpSize.touchMin,
            height: TpSize.touchMin,
            child: Stack(alignment: Alignment.center, children: [
              Icon(icon, color: color ?? c.text, size: 22),
              if (badge != null)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(9), border: Border.all(color: c.sidebar, width: 2)),
                    alignment: Alignment.center,
                    child: Text('$badge', style: TextStyle(color: c.onStatus, fontSize: 10, fontWeight: FontWeight.w800, height: 1)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

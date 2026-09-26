import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Texto com "→" desenhado como ícone: a Nunito não tem o glifo da seta.
class ArrowText extends StatelessWidget {
  const ArrowText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split(' → ');
    final size = (style.fontSize ?? 16) * .85;
    return Semantics(
      label: text.replaceAll('→', 'para'),
      excludeSemantics: true,
      child: Text.rich(TextSpan(style: style, children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) ...[
            const TextSpan(text: ' '),
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(LucideIcons.arrowRight, size: size, color: style.color)),
            const TextSpan(text: ' '),
          ],
          TextSpan(text: parts[i]),
        ],
      ])),
    );
  }
}

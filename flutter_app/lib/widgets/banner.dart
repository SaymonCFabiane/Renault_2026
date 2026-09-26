import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum BannerTone { ok, warn, bad, info }

/// Banner de retorno: fica enquanto a situação existir.
class TpBanner extends StatelessWidget {
  const TpBanner({super.key, required this.tone, required this.icon, required this.title, this.body, this.action, this.onTap});
  final BannerTone tone;
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final (Color bg, Color fg, Color? border) = switch (tone) {
      BannerTone.ok => (c.successBg, c.success, c.success.withValues(alpha: .4)),
      BannerTone.warn => (c.warningBg, c.warningText, c.warning),
      BannerTone.bad => (c.dangerBg, c.danger, c.danger.withValues(alpha: .4)),
      BannerTone.info => (c.primarySoft, c.text, null),
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TpRadius.radiusCard),
        side: border != null ? BorderSide(color: border, width: 1.5) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, color: fg, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 16, height: 1.35)),
                if (body != null) ...[const SizedBox(height: 2), Text(body!, style: TextStyle(color: c.text, fontSize: 15, height: 1.4))],
                if (action != null) action!,
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

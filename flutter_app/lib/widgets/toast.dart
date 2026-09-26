import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../state/demo_state.dart';
import '../theme/tokens.dart';

/// Defeito 4: um único toast; o novo substitui o anterior.
class ToastView extends StatelessWidget {
  const ToastView({super.key, required this.toast});
  final ToastMessage toast;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final (Color icBg, Color icFg, IconData ic) = switch (toast.kind) {
      ToastKind.ok => (c.success, c.onStatus, LucideIcons.check),
      ToastKind.bad => (c.danger, c.onStatus, LucideIcons.x),
      ToastKind.warn => (c.warning, const Color(0xFF1E2F38), LucideIcons.triangleAlert),
    };
    return Semantics(
      liveRegion: true,
      child: Material(
        key: ValueKey(toast.id),
        color: c.text,
        elevation: 6,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(TpRadius.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(color: icBg, shape: BoxShape.circle), child: Icon(ic, size: 15, color: icFg)),
            const SizedBox(width: 10),
            Expanded(child: Text(toast.message, style: TextStyle(color: c.surface, fontWeight: FontWeight.w600, fontSize: 15, height: 1.3))),
          ]),
        ),
      ),
    );
  }
}

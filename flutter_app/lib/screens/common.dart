import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/banner.dart';
import '../widgets/buttons.dart';

/// Coluna padrão das telas: itens esticados com 14px entre eles.
class ScreenColumn extends StatelessWidget {
  const ScreenColumn({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: children);
}

/// Aviso de bloqueio com o link "Simular…" que destrava o passo de outro perfil.
class LockedNote extends StatelessWidget {
  const LockedNote({super.key, required this.title, required this.action, required this.onTap});
  final String title, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TpBanner(tone: BannerTone.info, icon: LucideIcons.lock, title: title, action: TpLink(label: action, onTap: onTap));
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../ia/ia_config_sheet.dart';
import '../ia/ia_servico.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/facetas.dart';
import '../widgets/tags.dart';
import '../widgets/toast.dart';

/// Seleção de perfil: não há login; tocar no card entra com o perfil.
class ProfilePicker extends StatelessWidget {
  const ProfilePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    const white = Colors.white;
    return Scaffold(
      backgroundColor: c.contentBg,
      body: Stack(children: [
        Column(children: [
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(gradient: c.degradeMarca, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Stack(children: [
              const Positioned.fill(child: FacetasMarca()),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 8, 26),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(TpRadius.radiusIcon)),
                        child: const Icon(LucideIcons.route, color: white),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('TracePro', style: TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.w800))),
                      TpIconButton(
                        icon: s.dark ? LucideIcons.sun : LucideIcons.moon,
                        tooltip: s.dark ? 'Mudar para o tema claro' : 'Mudar para o tema escuro',
                        color: white,
                        onTap: s.toggleTheme,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Semantics(header: true, child: Text('Quem vai trabalhar agora?', style: TpText.title.copyWith(color: white))),
                    const SizedBox(height: 2),
                    const Text('Toque no seu perfil para entrar', style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 14)),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                for (final p in profiles) ...[
                  TpCard(
                    onTap: () => s.pickProfile(p.id),
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      TpAvatar(p.initials, size: 60),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(fontSize: 18, height: 26 / 18, fontWeight: FontWeight.w700)),
                          Muted(p.role),
                          const SizedBox(height: 6),
                          TpTag(p.module.toUpperCase(), icon: p.icon),
                        ]),
                      ),
                      Icon(LucideIcons.chevronRight, color: c.textSecondary),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 4),
                TpButton(label: 'Pular para o fim da história', icon: LucideIcons.skipForward, variant: TpVariant.ghost, small: true, onPressed: s.skipEnd),
                TpButton(label: 'Reiniciar demo', icon: LucideIcons.rotateCcw, variant: TpVariant.ghost, small: true, onPressed: s.reset),
                if (IaScope.read(context) != null)
                  TpButton(label: 'Servidor de IA', icon: LucideIcons.scanEye, variant: TpVariant.ghost, small: true, onPressed: () => abrirConfigIa(context)),
                const SizedBox(height: 8),
                const Center(child: Muted('Protótipo · dados fictícios · nada é salvo ao recarregar', size: 12)),
              ],
            ),
          ),
        ]),
        if (s.toast != null)
          Positioned(left: 16, right: 16, bottom: MediaQuery.paddingOf(context).bottom + 16, child: IgnorePointer(child: ToastView(toast: s.toast!))),
      ]),
    );
  }
}

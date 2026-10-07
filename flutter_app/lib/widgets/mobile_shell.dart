import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../ia/ia_config_sheet.dart';
import '../ia/ia_servico.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'bottom_nav.dart';
import 'buttons.dart';
import 'cards.dart';
import 'lock_screen.dart';
import 'modal.dart';
import 'toast.dart';

/// Menu da demo (toque no avatar): pular para o fim, reiniciar e trocar perfil.
Future<void> showDemoMenu(BuildContext context, DemoState s) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      Widget item(IconData ic, String label, VoidCallback run) => ListTile(
            minTileHeight: TpSize.touchMin,
            leading: Icon(ic),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(ctx);
              run();
            },
          );
      return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          item(LucideIcons.skipForward, 'Pular para o fim da história', s.skipEnd),
          item(LucideIcons.rotateCcw, 'Reiniciar demo', s.reset),
          item(LucideIcons.arrowLeftRight, 'Trocar perfil', s.swapProfile),
          if (IaScope.read(context) != null) item(LucideIcons.scanEye, 'Servidor de IA', () => abrirConfigIa(context)),
          const SizedBox(height: 8),
        ]),
      );
    },
  );
}

class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.state, required this.body, this.fab});
  final DemoState state;
  final Widget body;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final p = s.profile!;
    final c = TpColors.of(context);
    final back = screenHome[s.screen];
    final navInset = bottomNavHeight + MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (s.modal != null) {
          s.closeModal();
        } else if (s.lockShown) {
          s.unlock();
        } else if (back != null) {
          s.go(back);
        } else {
          s.swapProfile();
        }
      },
      child: Scaffold(
        backgroundColor: c.contentBg,
        body: Stack(children: [
          Column(children: [
            _Header(state: s, profile: p, back: back),
            Expanded(
              child: SingleChildScrollView(
                key: PageStorageKey(s.screen),
                // Defeito 5: espaço no fim da lista para o FAB (e o toast) não cobrirem cards.
                padding: EdgeInsets.fromLTRB(16, 18, 16, fab != null ? 104 : 88),
                child: body,
              ),
            ),
            BottomNav(items: menus[p.id]!, current: s.screen, onTap: s.go),
          ]),
          if (fab != null) Positioned(right: 20, bottom: navInset + 20, child: fab!),
          // Defeito 4: toast acima da navegação inferior, sem cobri-la, e abaixo de modais.
          if (s.toast != null) Positioned(left: 16, right: 16, bottom: navInset + 12, child: IgnorePointer(child: ToastView(toast: s.toast!))),
          if (s.notesOpen) ...[
            Positioned.fill(child: GestureDetector(onTap: s.toggleNotes, child: const ColoredBox(color: Color(0x33000000)))),
            Positioned(left: 12, right: 12, top: MediaQuery.paddingOf(context).top + 64, child: _NotesPanel(profileId: p.id)),
          ],
          if (s.modal != null) ModalLayer(state: s),
          if (s.lockShown) Positioned.fill(child: LockScreen(onBack: s.unlock)),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.profile, required this.back});
  final DemoState state;
  final Profile profile;
  final Screen? back;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    const white = Colors.white;
    return Container(
      decoration: BoxDecoration(color: c.sidebar, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Semantics(
                button: true,
                label: 'Opções da demo',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showDemoMenu(context, state),
                  child: Padding(padding: const EdgeInsets.all(2), child: TpAvatar(profile.initials)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile.name, style: const TextStyle(color: white, fontSize: 17, fontWeight: FontWeight.w700, height: 1.2)),
                  Text('${profile.role} · ${profile.module}', maxLines: 2, style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13, height: 1.3)),
                ]),
              ),
              TpIconButton(
                icon: state.dark ? LucideIcons.sun : LucideIcons.moon,
                tooltip: state.dark ? 'Mudar para o tema claro' : 'Mudar para o tema escuro',
                color: white,
                onTap: state.toggleTheme,
              ),
              // Defeito 3: "Trocar perfil" visível em todas as telas.
              TpIconButton(icon: LucideIcons.arrowLeftRight, tooltip: 'Trocar perfil', color: white, onTap: state.swapProfile),
              TpIconButton(icon: LucideIcons.bell, tooltip: 'Notificações', color: white, badge: notes[profile.id]!.length, onTap: state.toggleNotes),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              if (back != null) ...[
                Tooltip(
                  message: 'Voltar',
                  child: Semantics(
                    button: true,
                    label: 'Voltar',
                    child: InkResponse(
                      onTap: () => state.go(back!),
                      radius: 24,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Color(0x1FFFFFFF), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.chevronLeft, color: white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: Semantics(header: true, child: Text(screenTitles[state.screen]!, style: TpText.title.copyWith(color: white)))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    (Color, Color) tone(String t) => switch (t) {
          'danger' => (c.dangerBg, c.danger),
          'warning' => (c.warningBg, c.warningText),
          'success' => (c.successBg, c.success),
          'accent' => (c.accentBg, c.accentText),
          _ => (c.primarySoft, c.primary),
        };
    return Material(
      color: c.surface,
      elevation: 12,
      borderRadius: BorderRadius.circular(TpRadius.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.fromLTRB(10, 8, 10, 6), child: Text('Notificações', style: TextStyle(fontWeight: FontWeight.w700))),
          for (final n in notes[profileId]!)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: tone(n.tone).$1, shape: BoxShape.circle),
                    child: Icon(n.icon, size: 18, color: tone(n.tone).$2)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.text, style: const TextStyle(fontSize: 14, height: 1.35)),
                    Muted(n.when, size: 12),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

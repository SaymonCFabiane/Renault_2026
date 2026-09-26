import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// F-FUNC1 · Lotes liberados
class LotesScreen extends StatelessWidget {
  const LotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    final released = s.op3310 != 'Pendente';
    final ok = s.loadOk.length;
    return ScreenColumn(children: [
      const SectionTitle('Aguardando etiquetagem'),
      if (released)
        TpCard(
          highlight: c.accent,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const CardHeadRow(title: 'OP-3310', trailing: TpTag('EM DESTAQUE', tone: TagTone.accent)),
            const SizedBox(height: 6),
            const Text('Farol LED esquerdo × 10', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
            const Muted('Lote LT-2026-088 · reposição do KT-0142'),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              StatusText(s.labelsPrinted ? 'Etiquetas impressas' : 'Liberado'),
              const Muted('Liberado por Carla Mendes', size: 12),
            ]),
            const SizedBox(height: 12),
            TpButton(
              label: s.labelsPrinted ? 'Ver etiquetas' : 'Registrar e imprimir etiquetas',
              icon: LucideIcons.printer,
              block: true,
              onPressed: () => s.go(Screen.fFunc2),
            ),
          ]),
        )
      else
        TpCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Opacity(
              opacity: .55,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                CardHeadRow(title: 'OP-3310', trailing: TpTag('BLOQUEADO', tone: TagTone.nao, icon: LucideIcons.lock)),
                SizedBox(height: 6),
                Text('Farol LED esquerdo × 10', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
              ]),
            ),
            const SizedBox(height: 12),
            LockedNote(title: 'Aguardando liberação de Carla Mendes', action: 'Simular liberação pelo painel web', onTap: s.simRelease),
          ]),
        ),
      const SectionTitle('Outros lotes'),
      const TpCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CardHeadRow(title: 'OP-3306', trailing: StatusText('Etiquetado')),
        Muted('Amortecedor traseiro × 6 · 24/09'),
      ])),
      const TpCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CardHeadRow(title: 'OP-3308', trailing: StatusText('Pendente')),
        Muted('Pinça de freio traseira × 4 · aguardando liberação'),
      ])),
      const SectionTitle('Carregamento de hoje'),
      TpCard(
        onTap: () => s.go(Screen.fFunc3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Status à esquerda: o canto direito fica livre para o FAB (defeito 5).
          const Text('MN-0457', style: TpText.cardTitle),
          StatusText(s.mn0457),
          Muted('$ok de 10 peças bipadas'),
          const SizedBox(height: 10),
          TpProgress(ok / 10),
        ]),
      ),
    ]);
  }
}

/// Botão flutuante de acesso ao leitor (F-FUNC1).
class ScanFab extends StatelessWidget {
  const ScanFab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    return Tooltip(
      message: 'Abrir leitor',
      child: Semantics(
        button: true,
        label: 'Abrir leitor',
        child: Material(
          color: c.accentText,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => s.go(Screen.fFunc3),
            child: SizedBox(width: 64, height: 64, child: Icon(LucideIcons.scanLine, size: 28, color: c.onStatus)),
          ),
        ),
      ),
    );
  }
}

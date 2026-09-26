import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// T-FUNC1 · Kits esperados
class KitsEsperadosScreen extends StatelessWidget {
  const KitsEsperadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    final st = s.kits['KT-0142']!;
    String label(String k) =>
        const {
          'Em Separação': 'Em separação',
          'Aguardando Separação': 'Aguardando separação',
          'Em Trânsito': 'A caminho · chegou',
          'Entregue Parcial': 'Aceito · parcial'
        }[s.kits[k]] ??
        s.kits[k]!;
    final Widget banner = switch (st) {
      'Em Trânsito' => TpBanner(
          tone: BannerTone.ok,
          icon: LucideIcons.bell,
          title: 'KT-0142 chegou',
          body: 'Levado por ${s.shipCarrier.isEmpty ? 'transporte interno' : s.shipCarrier}. Toque para conferir.',
          onTap: () => s.go(Screen.tFunc2),
        ),
      'Entregue Parcial' => const TpBanner(tone: BannerTone.ok, icon: LucideIcons.circleCheck, title: 'KT-0142 aceito', body: 'SUV X liberado para montagem.'),
      _ => TpBanner(
          tone: BannerTone.info,
          icon: LucideIcons.timer,
          title: 'KT-0142 em separação no Estoque',
          body: 'Você recebe um aviso quando ele chegar.',
          action: TpLink(label: 'Simular chegada', onTap: s.simKitArrive),
        ),
    };
    return ScreenColumn(children: [
      banner,
      const SectionTitle('Kits a caminho'),
      for (final k in ['KT-0142', 'KT-0145', 'KT-0139'])
        TpCard(
          onTap: k == 'KT-0142' ? () => s.go(Screen.tFunc2) : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHeadRow(title: k, trailing: k == 'KT-0139' ? const TpTag('TRAVADO', tone: TagTone.blocante, icon: LucideIcons.lock) : PrioTag(kitPrio[k]!)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(LucideIcons.car, size: 18, color: c.text),
              const SizedBox(width: 6),
              Expanded(child: Text(kitProto[k]!, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Muted('${kitItemCount[k]} itens${k == 'KT-0142' ? ' · parcial autorizado' : ''}', size: 13)),
              StatusText(k == 'KT-0139' ? 'Travado' : label(k)),
            ]),
          ]),
        ),
    ]);
  }
}

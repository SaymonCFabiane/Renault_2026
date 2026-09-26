import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/arrow_text.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/kit_item.dart';
import '../../widgets/route_step.dart';
import '../../widgets/scanner_view.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// E-FUNC3 · Coleta e montagem do KT-0142 (rota)
class ColetaScreen extends StatelessWidget {
  const ColetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    final idx = s.routeIdx, total = kit142.length, done = idx >= total;
    final collected = idx.clamp(0, total);
    final cur = done ? null : kit142[idx];

    final List<Widget> step;
    if (done) {
      step = [
        const TpBanner(
            tone: BannerTone.ok,
            icon: LucideIcons.circleCheck,
            title: 'Coleta concluída · kit parcial',
            body: '5 de 6 itens coletados. O KT-0142 está em Kits para Despacho.'),
        TpButton(label: 'Ir para expedição', icon: LucideIcons.truck, block: true, onPressed: () => s.go(Screen.eFunc4)),
      ];
    } else if (cur!.missing) {
      step = [
        RouteStepCard(
          warning: true,
          eyebrow: '${idx + 1}º ITEM · SEM ENDEREÇO',
          where: cur.name,
          extra: const Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            CriticalityTag(blocking: false),
            Text('EM FALTA no estoque', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E2F38))),
          ]),
        ),
        TpButton(label: 'Registrar falta', icon: LucideIcons.circleAlert, variant: TpVariant.accent, block: true, onPressed: s.routeMiss),
      ];
    } else {
      final parts = cur.address!.split(' · ');
      step = [
        RouteStepCard(
          eyebrow: '${idx + 1}º PASSO · ${cur.name.toUpperCase()}',
          where: 'Corredor ${cur.aisle} → Prateleira ${cur.shelf.toString().padLeft(2, '0')} → Pegue ${cur.qty} ${cur.qty > 1 ? 'unidades' : 'unidade'}',
          detail: parts.skip(2).join(' · '),
        ),
        ScannerView(last: s.routeLast, idle: 'Leia o QR da caixa'),
        TpButton(label: 'Simular leitura do QR', icon: LucideIcons.scanLine, variant: TpVariant.secondary, block: true, onPressed: s.routeScan),
      ];
    }

    return ScreenColumn(children: [
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CardHeadRow(title: 'KT-0142', trailing: PrioTag('Alta')),
          const Muted(protoSuv),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ArrowText('ROTA A → B → C → D', style: TpText.label.copyWith(color: c.textSecondary))),
            Text('$collected de $total', style: TpText.label.copyWith(color: c.textSecondary)),
          ]),
          const SizedBox(height: 6),
          TpProgress(collected / total),
        ]),
      ),
      ...step,
      const SectionTitle('Itens do kit'),
      for (var i = 0; i < total; i++)
        KitItem(
          title: '${kit142[i].name} ×${kit142[i].qty}',
          subtitle: kit142[i].missing ? 'Em falta · sem endereço' : kit142[i].address!,
          blocking: kit142[i].blocking,
          state: i < idx
              ? (kit142[i].missing ? KitItemState.missing : KitItemState.done)
              : i == idx
                  ? KitItemState.current
                  : KitItemState.locked,
        ),
      TpButton(label: 'Ver exceção: KT-0139 com peça blocante em falta', icon: LucideIcons.lock, variant: TpVariant.ghost, block: true, onPressed: s.showLock),
    ]);
  }
}

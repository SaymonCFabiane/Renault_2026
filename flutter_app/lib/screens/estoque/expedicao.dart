import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/kit_item.dart';
import '../../widgets/read_row.dart';
import '../../widgets/scanner_view.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// E-FUNC4 · Expedição de kit
class ExpedicaoScreen extends StatelessWidget {
  const ExpedicaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    if (s.kits['KT-0142'] != 'Em Separação') {
      return ScreenColumn(children: [
        TpBanner(
            tone: BannerTone.ok,
            icon: LucideIcons.truck,
            title: 'KT-0142 expedido',
            body: 'Levado por ${s.shipCarrier.isEmpty ? 'transporte interno' : s.shipCarrier} até a oficina de protótipos.'),
        const EmptyState(icon: LucideIcons.inbox, title: 'Nenhum outro kit para despacho'),
      ]);
    }
    if (!s.k142ready) {
      return EmptyState(
        icon: LucideIcons.truck,
        title: 'Nenhum kit pronto para despacho',
        text: 'Termine a coleta do KT-0142 para expedir.',
        action: TpButton(label: 'Ir para a coleta', icon: LucideIcons.route, onPressed: () => s.go(Screen.eFunc3)),
      );
    }
    return ScreenColumn(children: [
      const TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CardHeadRow(title: 'KT-0142', trailing: TpTag('PARCIAL', tone: TagTone.warn)),
          Muted('$protoSuv · 5 de 6 itens · Farol LED esquerdo pendente'),
        ]),
      ),
      const SectionTitle('1. Leia o QR da caixa do kit'),
      if (s.shipScanned)
        ReadRow(ScanRead(code: 'CX-KT-0142', ok: true, sub: 'Caixa do kit confirmada', time: s.shipTime))
      else ...[
        const ScannerView(idle: 'Leia o QR da caixa do kit'),
        TpButton(label: 'Simular leitura', icon: LucideIcons.scanLine, variant: TpVariant.secondary, block: true, onPressed: s.shipScan),
      ],
      const SectionTitle('2. Quem leva o kit até a oficina?'),
      for (final o in carriers)
        Semantics(
          inMutuallyExclusiveGroup: true,
          checked: s.shipCarrier == o[0],
          child: KitItem(
            title: o[0],
            subtitle: o[1],
            blocking: false,
            showTag: false,
            state: KitItemState.pending,
            selected: s.shipCarrier == o[0],
            icon: s.shipCarrier == o[0] ? LucideIcons.check : LucideIcons.user,
            onTap: () => s.setCarrier(o[0]),
          ),
        ),
      TpButton(label: 'Confirmar expedição', icon: LucideIcons.truck, block: true, onPressed: s.shipScanned && s.shipCarrier.isNotEmpty ? s.shipConfirm : null),
    ]);
  }
}

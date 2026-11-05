import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../widgets/aviso_ia.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/kit_item.dart';
import '../../widgets/scanner_view.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// E-FUNC5 · Coleta do KT-0145: faltam 2 peças, validadas pela câmera (Engrenagem e Pinça de freio).
class ColetaIaScreen extends StatelessWidget {
  const ColetaIaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final total = kit145.length, feitas = s.col145.length, completo = feitas == total;
    final faltam = [for (var i = 0; i < total; i++) if (!s.col145.contains(i)) kit145[i]];
    return ScreenColumn(children: [
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CardHeadRow(title: 'KT-0145', trailing: PrioTag('Média')),
          const Muted(protoHatch),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Muted(completo ? 'Todas as peças coletadas' : faltam.length == 1 ? 'Falta 1 peça' : 'Faltam ${faltam.length} peças', size: 13, weight: FontWeight.w700)),
            Muted('$feitas de $total', size: 13, weight: FontWeight.w700),
          ]),
          const SizedBox(height: 6),
          TpProgress(feitas / total),
        ]),
      ),
      if (completo) ...[
        const TpBanner(
            tone: BannerTone.ok, icon: LucideIcons.circleCheck, title: 'Coleta concluída · kit completo', body: 'As 5 peças do KT-0145 foram coletadas.'),
        TpButton(label: 'Concluir montagem', icon: LucideIcons.check, block: true, onPressed: s.concluirKt0145),
      ] else ...[
        AvisoCameraIa(pecas: faltam.map((p) => 'a ${p.name.replaceAll(' dianteira', '')}').join(' e ')),
        ScannerView(last: s.col145Last, idle: 'Mostre a peça para a câmera', onPeca: s.coletarPorIa),
      ],
      const SectionTitle('Itens do kit'),
      for (var i = 0; i < total; i++)
        KitItem(
          title: '${kit145[i].name} ×${kit145[i].qty}',
          subtitle: s.col145.contains(i) ? '${kit145[i].address!} · coletada' : '${kit145[i].address!} · valide pela câmera',
          blocking: kit145[i].blocking,
          state: s.col145.contains(i) ? KitItemState.done : KitItemState.current,
          icon: s.col145.contains(i) ? null : LucideIcons.scanEye,
        ),
    ]);
  }
}

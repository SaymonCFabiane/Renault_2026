import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../widgets/aviso_ia.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/kit_item.dart';
import '../../widgets/route_step.dart';
import '../../widgets/scanner_view.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// E-FUNC3 · Coleta do KT-0142: as outras peças já foram coletadas; a Pinça de freio é validada pela câmera
/// e fecha o kit (parcial: o Farol LED está em falta e o envio parcial foi autorizado).
class ColetaScreen extends StatelessWidget {
  const ColetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final disponiveis = [for (var i = 0; i < kit142.length; i++) if (!kit142[i].missing) i];
    final feitas = s.col142.length, total = disponiveis.length, fechado = s.k142ready || feitas == total;
    final faltam = [for (final i in disponiveis) if (!s.col142.contains(i)) kit142[i]];

    return ScreenColumn(children: [
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CardHeadRow(title: 'KT-0142', trailing: PrioTag('Alta')),
          const Muted(protoSuv),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: Muted(fechado ? 'Kit fechado' : (faltam.length == 1 ? 'Falta 1 peça' : 'Faltam ${faltam.length} peças'),
                    size: 13, weight: FontWeight.w700)),
            Muted('$feitas de ${kit142.length}', size: 13, weight: FontWeight.w700),
          ]),
          const SizedBox(height: 6),
          TpProgress(feitas / kit142.length),
        ]),
      ),
      if (fechado) ...[
        const TpBanner(
            tone: BannerTone.ok,
            icon: LucideIcons.circleCheck,
            title: 'Kit fechado · parcial',
            body: '5 de 6 itens coletados. O Farol LED esquerdo está em falta e o Cliente autorizou o envio parcial.'),
        TpButton(label: 'Ir para expedição', icon: LucideIcons.truck, block: true, onPressed: () => s.go(Screen.eFunc4)),
      ] else ...[
        for (final p in faltam)
          RouteStepCard(eyebrow: 'PEGUE · ${p.name.toUpperCase()} ×${p.qty}', where: p.address!, detail: descreverEndereco(p.address!)),
        AvisoCameraIa(pecas: faltam.map((p) => 'a ${p.name.replaceAll(' dianteira', '')}').join(' e ')),
        ScannerView(last: s.routeLast, idle: 'Mostre a peça para a câmera', onPeca: s.coletarRotaPorIa),
      ],
      const SectionTitle('Itens do kit'),
      for (var i = 0; i < kit142.length; i++)
        KitItem(
          title: '${kit142[i].name} ×${kit142[i].qty}',
          subtitle: kit142[i].missing
              ? 'Em falta · envio parcial autorizado'
              : s.col142.contains(i)
                  ? '${kit142[i].address!} · coletada'
                  : '${kit142[i].address!} · valide pela câmera',
          blocking: kit142[i].blocking,
          state: kit142[i].missing
              ? KitItemState.missing
              : s.col142.contains(i)
                  ? KitItemState.done
                  : KitItemState.current,
          icon: kit142[i].missing || s.col142.contains(i) ? null : LucideIcons.scanEye,
        ),
      TpButton(label: 'Ver exceção: KT-0139 com peça blocante em falta', icon: LucideIcons.lock, variant: TpVariant.ghost, block: true, onPressed: s.showLock),
    ]);
  }
}

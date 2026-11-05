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

/// T-FUNC2 · Conferência do kit (Pedido x Entregue)
class ConferenciaKitScreen extends StatelessWidget {
  const ConferenciaKitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final st = s.kits['KT-0142']!;
    final arrived = st == 'Em Trânsito', accepted = st.startsWith('Entregue');
    final got = s.accGot, allIn = got.length == 5;
    if (!arrived && !accepted) {
      return LockedNote(title: 'O KT-0142 ainda não chegou na oficina', action: 'Simular chegada do kit', onTap: s.simKitArrive);
    }
    return ScreenColumn(children: [
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CardHeadRow(title: 'KT-0142', trailing: StatusText(accepted ? 'Entregue Parcial' : 'Na oficina', tone: accepted ? StatusTone.warn : StatusTone.info)),
          const Muted(protoSuv),
        ]),
      ),
      if (accepted)
        const TpBanner(
            tone: BannerTone.ok,
            icon: LucideIcons.circleCheck,
            title: 'Kit aceito e liberado para montagem',
            body: 'Juliana Costa vê o KT-0142 como Entregue Parcial.')
      else ...[
        if (!allIn) const AvisoCameraIa(pecas: 'a Pinça de freio'),
        ScannerView(last: s.accLast, idle: allIn ? 'Todas as peças conferidas' : 'Mostre a peça para a câmera', onPeca: s.conferirPorIa),
      ],
      const SectionTitle('Pedido x Entregue'),
      for (var i = 0; i < kit142.length; i++)
        Builder(builder: (_) {
          final it = kit142[i];
          final has = got.contains(i) || (accepted && !it.missing);
          return KitItem(
            title: it.name,
            subtitle: 'Pedido ${it.qty} · Entregue ${it.missing ? 0 : has ? it.qty : '—'}',
            blocking: it.blocking,
            state: it.missing
                ? KitItemState.missing
                : has
                    ? KitItemState.done
                    : KitItemState.pending,
          );
        }),
      const TpBanner(
        tone: BannerTone.warn,
        icon: LucideIcons.triangleAlert,
        title: 'Farol LED esquerdo ausente',
        body: 'Peça NÃO-BLOCANTE. O envio parcial foi autorizado; o teste pode começar sem ela.',
      ),
      if (s.accReported)
        const TpBanner(tone: BannerTone.info, icon: LucideIcons.info, title: 'Relato enviado ao Estoque', body: 'Ricardo Alves vai analisar a peça apontada.'),
      if (!accepted) ...[
        TpButton(
            label: 'Reportar Peça Danificada/Incompatível', icon: LucideIcons.camera, variant: TpVariant.dangerOutline, block: true, onPressed: s.openReport),
        TpButton(
            label: 'Dar Aceite e Liberar para Montagem',
            icon: LucideIcons.circleCheck,
            variant: TpVariant.success,
            block: true,
            onPressed: allIn ? s.accept : null),
        if (!allIn) const Muted('Confira a Pinça de freio dianteira pela câmera para liberar o aceite', size: 13),
      ],
    ]);
  }
}

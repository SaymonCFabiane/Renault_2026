import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/modal.dart';
import '../../widgets/read_row.dart';
import '../../widgets/route_step.dart';
import '../../widgets/scanner_view.dart';
import '../common.dart';

/// E-FUNC2 · Conferência de recebimento (MN-0457)
class RecebimentoScreen extends StatelessWidget {
  const RecebimentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final ok = s.recvOkCount, manifest = s.loadOk.length;
    final done = s.mn0457 == 'Recebido', more = s.recvSeqIdx < recvSeq.length;
    if (s.mn0457 != 'Em Trânsito' && !done) {
      return LockedNote(title: 'A carga MN-0457 ainda não chegou na doca', action: 'Simular chegada na doca', onTap: s.simArrive);
    }
    final last = s.recvLast;
    return ScreenColumn(children: [
      Row(spacing: 10, children: [
        Expanded(child: StatTile(label: 'MANIFESTO', value: '$manifest')),
        Expanded(child: StatTile(label: 'LIDO', value: '$ok', tone: ok >= manifest ? StatTone.ok : StatTone.none)),
      ]),
      if (done)
        TpBanner(tone: BannerTone.ok, icon: LucideIcons.circleCheck, title: 'Recebimento concluído', body: '$manifest peças guardadas em $guardAddress.')
      else
        ScannerView(last: last),
      if (!done && last != null && last.ok)
        RouteStepCard(eyebrow: 'GUARDAR EM', where: guardAddress.replaceAll(' · ', ' → '), detail: '${last.code} · Farol LED esquerdo'),
      if (!done && more) TpButton(label: 'Simular leitura', icon: LucideIcons.scanLine, variant: TpVariant.secondary, block: true, onPressed: s.recvScan),
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
          const SectionTitle('Registrar avaria'),
          if (s.recvPhoto) const PhotoThumb(name: 'IMG_0457_01.jpg') else PhotoPlaceholder(label: 'Tirar foto da peça', onTap: s.takeRecvPhoto),
          const TextField(maxLines: 2, decoration: InputDecoration(hintText: 'Descreva o dano (opcional)')),
          TpButton(
            label: s.recvDamage ? 'Avaria registrada' : 'Registrar avaria',
            icon: LucideIcons.triangleAlert,
            variant: TpVariant.outline,
            block: true,
            onPressed: s.recvDamage ? null : s.registerDamage,
          ),
        ]),
      ),
      const SectionTitle('Leituras'),
      for (final r in s.recvReads.reversed) ReadRow(r),
      // Defeito 1: habilita quando as 8 peças do manifesto forem lidas.
      if (!done) TpButton(label: 'Concluir recebimento', icon: LucideIcons.check, block: true, onPressed: ok >= manifest ? s.recvDone : null),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/read_row.dart';
import '../../widgets/scanner_view.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// F-FUNC3 · Carregamento (bipagem da MN-0457)
class CarregamentoScreen extends StatelessWidget {
  const CarregamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    final ok = s.loadOk.length;
    final more = s.loadSeqIdx < loadSeq.length;
    final sent = s.mn0457 != 'Em Conferência';
    return ScreenColumn(children: [
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Manifesto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textSecondary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            icon: const Icon(LucideIcons.chevronDown),
            initialValue: 'MN-0457',
            isExpanded: true,
            items: const [DropdownMenuItem(value: 'MN-0457', child: Text('MN-0457 · OP-3310 · Doca 2 da Montadora', overflow: TextOverflow.ellipsis))],
            onChanged: (_) {},
          ),
        ]),
      ),
      if (!sent) ScannerView(last: s.loadLast),
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BIPADAS', style: TpText.label.copyWith(color: c.textSecondary)),
                Semantics(
                  label: 'Bipadas $ok de 10',
                  child: Text.rich(TextSpan(style: TpText.count, children: [
                    TextSpan(text: '$ok'),
                    TextSpan(text: '/10', style: TextStyle(fontSize: 28, color: c.textSecondary)),
                  ])),
                ),
              ]),
            ),
            if (sent) StatusText(s.mn0457) else if (!more) StatusText('Faltam ${10 - ok}'),
          ]),
          const SizedBox(height: 8),
          TpProgress(ok / 10, ok: ok == 10),
        ]),
      ),
      if (sent)
        TpBanner(
          tone: BannerTone.ok,
          icon: LucideIcons.circleCheck,
          title: 'Conferência enviada',
          body: 'Carla Mendes ${s.mn0457 == 'Aguardando Aprovação' ? 'vai aprovar a expedição no painel web.' : 'autorizou a expedição.'}',
        )
      else if (more)
        TpButton(label: 'Simular leitura', icon: LucideIcons.scanLine, variant: TpVariant.secondary, block: true, onPressed: s.loadScan)
      else
        const TpBanner(
            tone: BannerTone.warn, icon: LucideIcons.triangleAlert, title: 'Sem mais peças no carrinho', body: 'PC-000209 e PC-000210 não foram encontradas.'),
      const SectionTitle('Histórico de leituras'),
      for (final r in s.loadReads.reversed) ReadRow(r),
      if (!sent) TpButton(label: 'Enviar para Aprovação do ADM', icon: LucideIcons.send, block: true, onPressed: s.loadSend),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../state/demo_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/label_card.dart';
import '../common.dart';

/// F-FUNC2 · Registro e etiquetas
class EtiquetasScreen extends StatelessWidget {
  const EtiquetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    final released = s.op3310 != 'Pendente';
    final n = s.labelQty;
    Widget label(String t) =>
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textSecondary)));
    return ScreenColumn(children: [
      if (!released) LockedNote(title: 'O lote OP-3310 ainda não foi liberado', action: 'Simular liberação pelo painel web', onTap: s.simRelease),
      TpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            label('Lote'),
            DropdownButtonFormField<String>(
              icon: const Icon(LucideIcons.chevronDown),
              initialValue: 'OP-3310',
              isExpanded: true,
              items: const [DropdownMenuItem(value: 'OP-3310', child: Text('OP-3310 · Farol LED esquerdo'))],
              onChanged: (_) {},
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            label('Quantidade produzida'),
            Row(spacing: 10, children: [
              TpButton(
                  label: '', semanticLabel: 'Diminuir quantidade', icon: LucideIcons.minus, variant: TpVariant.secondary, onPressed: () => s.labelQtyStep(-1)),
              Expanded(
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(TpRadius.radiusIcon)),
                  child: Semantics(
                      label: 'Quantidade produzida', value: '$n', child: Text('$n', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                ),
              ),
              TpButton(
                  label: '', semanticLabel: 'Aumentar quantidade', icon: LucideIcons.plus, variant: TpVariant.secondary, onPressed: () => s.labelQtyStep(1)),
            ]),
          ]),
          Row(spacing: 10, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, children: [label('Lote de matéria-prima'), TextFormField(initialValue: 'LT-2026-088')])),
            Expanded(
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [label('Data de fabricação'), TextFormField(initialValue: '24/09/2026')])),
          ]),
        ]),
      ),
      Row(children: [const Expanded(child: SectionTitle('Prévia das etiquetas')), Muted('$n etiquetas · 50×30 mm', size: 12)]),
      for (var i = 0; i < 3; i++) LabelCard(code: 'PC-0002${(i + 1).toString().padLeft(2, '0')}', index: i + 1, total: n),
      Muted('+ ${n - 3} etiquetas até PC-0002${n.toString().padLeft(2, '0')} (Peça $n/$n)', size: 12),
      if (s.labelsPrinted)
        TpBanner(
            tone: BannerTone.ok, icon: LucideIcons.circleCheck, title: '$n etiquetas impressas', body: 'Cole cada etiqueta na peça antes do carregamento.'),
      TpButton(
        label: s.labelsPrinted ? 'Imprimir novamente' : 'Imprimir Etiquetas',
        icon: LucideIcons.printer,
        block: true,
        onPressed: released ? s.printLabels : null,
      ),
    ]);
  }
}

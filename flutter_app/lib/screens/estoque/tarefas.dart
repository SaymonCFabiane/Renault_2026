import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/tags.dart';
import '../common.dart';

const _tabs = ['Recebimentos', 'Montagem de Kits', 'Kits para Despacho'];
const _tabLabels = {'Recebimentos': 'Recebimentos', 'Montagem de Kits': 'Montagem', 'Kits para Despacho': 'Despacho'};

/// E-FUNC1 · Fila de tarefas
class TarefasScreen extends StatelessWidget {
  const TarefasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final t = s.marcosTab;
    final arrived = s.mn0457 == 'Em Trânsito', received = s.mn0457 == 'Recebido';
    final ready = s.k142ready && s.kits['KT-0142'] == 'Em Separação';
    final sep = <String>[
      if (s.kits['KT-0142'] == 'Em Separação' && !s.k142ready) 'KT-0142',
      'KT-0139',
      if (s.kits['KT-0145'] == 'Em Separação') 'KT-0145',
    ];
    final counts = {'Recebimentos': received ? 0 : 1, 'Montagem de Kits': sep.length, 'Kits para Despacho': ready ? 1 : 0};

    final List<Widget> body = switch (t) {
      'Recebimentos' => received
          ? [const EmptyState(icon: LucideIcons.circleCheck, title: 'Nenhum recebimento pendente', text: 'MN-0457 conferida e guardada.')]
          : [
              TpCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  CardHeadRow(title: 'MN-0457', trailing: StatusText(arrived ? 'Na doca 2' : 'A caminho')),
                  const SizedBox(height: 4),
                  Text('MetalSul Autopeças · Farol LED esquerdo × ${s.loadOk.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Muted(arrived ? 'Chegou às 17:30' : 'Aguardando expedição do fornecedor'),
                  const SizedBox(height: 12),
                  if (arrived)
                    TpButton(label: 'Conferir recebimento', icon: LucideIcons.packageCheck, block: true, onPressed: () => s.go(Screen.eFunc2))
                  else
                    LockedNote(title: 'A carga ainda não saiu do fornecedor', action: 'Simular chegada na doca', onTap: s.simArrive),
                ]),
              ),
              const TpCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                CardHeadRow(title: 'MN-0455', trailing: StatusText('Em Trânsito')),
                Muted('Suporte do motor × 8 · previsão 26/09'),
              ])),
            ],
      'Montagem de Kits' => [
          for (final k in sep)
            if (k == 'KT-0139')
              TpCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const CardHeadRow(title: 'KT-0139', trailing: TpTag('TRAVADO', tone: TagTone.blocante, icon: LucideIcons.lock)),
                  const Muted(protoPickup),
                  const SizedBox(height: 8),
                  const Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('Falta Pinça de freio traseira', style: TextStyle(fontWeight: FontWeight.w700)),
                    CriticalityTag(blocking: true),
                  ]),
                  const SizedBox(height: 12),
                  TpButton(label: 'Ver situação da coleta', variant: TpVariant.outline, block: true, onPressed: s.showLock),
                ]),
              )
            else
              TpCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  CardHeadRow(title: k, trailing: PrioTag(kitPrio[k]!)),
                  Muted(kitProto[k]!),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    const TpTag('Contém BLOCANTE', tone: TagTone.blocante, icon: LucideIcons.lock),
                    if (k == 'KT-0142') const TpTag('PARCIAL AUTORIZADO', tone: TagTone.warn),
                    Muted('${kitItemCount[k]} itens', size: 12),
                  ]),
                  const SizedBox(height: 12),
                  if (k == 'KT-0142')
                    TpButton(
                        label: s.routeIdx > 0 ? 'Continuar coleta' : 'Iniciar coleta',
                        icon: LucideIcons.route,
                        block: true,
                        onPressed: () => s.go(Screen.eFunc3))
                  else
                    TpButton(
                      label: 'Iniciar coleta',
                      icon: LucideIcons.route,
                      variant: TpVariant.outline,
                      block: true,
                      onPressed: () => s.toastOnly(ToastKind.warn, 'Termine o KT-0142 antes: ele tem prioridade Alta.'),
                    ),
                ]),
              ),
        ],
      _ => ready
          ? [
              TpCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const CardHeadRow(title: 'KT-0142', trailing: TpTag('PARCIAL', tone: TagTone.warn)),
                  const Muted('$protoSuv · 5 de 6 itens'),
                  const SizedBox(height: 12),
                  TpButton(label: 'Expedir kit', icon: LucideIcons.truck, block: true, onPressed: () => s.go(Screen.eFunc4)),
                ]),
              ),
            ]
          : [const EmptyState(icon: LucideIcons.truck, title: 'Nenhum kit pronto para despacho', text: 'Os kits aparecem aqui quando a coleta termina.')],
    };

    return ScreenColumn(children: [
      _Tabs(value: t, counts: counts, onChange: s.setMarcosTab),
      ...body,
    ]);
  }
}

/// Defeito 5: as 3 abas cabem em 358px (rótulos curtos, contadores sempre visíveis).
class _Tabs extends StatelessWidget {
  const _Tabs({required this.value, required this.counts, required this.onChange});
  final String value;
  final Map<String, int> counts;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        for (final t in _tabs)
          Expanded(
            child: Semantics(
              selected: t == value,
              button: true,
              label: '$t, ${counts[t]}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onChange(t),
                child: Container(
                  height: TpSize.touchMin,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t == value ? c.accent : Colors.transparent, width: 3))),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_tabLabels[t]!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: t == value ? c.accentText : c.textSecondary)),
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(TpRadius.radiusPill)),
                        child: Text('${counts[t]}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

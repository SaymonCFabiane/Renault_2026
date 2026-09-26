import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../state/demo_state.dart';
import '../theme/tokens.dart';
import 'banner.dart';
import 'buttons.dart';
import 'cards.dart';

/// Camada de modal (impressão, kit parcial, relato de peça). Fica acima do toast.
class ModalLayer extends StatelessWidget {
  const ModalLayer({super.key, required this.state});
  final DemoState state;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final body = switch (state.modal!) {
      ModalKind.print => _print(context, c),
      ModalKind.partial => _partial(context, c),
      ModalKind.report => _report(context, c),
    };
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x660B1A22),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: c.surface,
                elevation: 12,
                borderRadius: BorderRadius.circular(TpRadius.radiusCard),
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: body)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(Color bg, Color fg, IconData ic) =>
      Container(width: 52, height: 52, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(ic, color: fg, size: 26));

  static const _h2 = TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700);
  static const _gap = SizedBox(height: 16);

  List<Widget> _print(BuildContext context, TpColors c) {
    final done = state.printProgress >= 100;
    final n = state.labelQty;
    return [
      _icon(done ? c.successBg : c.primarySoft, done ? c.success : c.primary, done ? LucideIcons.circleCheck : LucideIcons.printer),
      _gap,
      Text(done ? 'Etiquetas impressas' : 'Enviando $n etiquetas para a impressora térmica (Bluetooth)…', style: _h2),
      _gap,
      Muted(done ? 'PC-000201 a PC-0002${n.toString().padLeft(2, '0')} · Impressora ZT-01 da linha 3' : 'Impressora ZT-01 da linha 3'),
      _gap,
      TpProgress(state.printProgress / 100, ok: done),
      const SizedBox(height: 8),
      Muted('${(state.printProgress / 100 * n).round()} de $n enviadas', size: 13),
      if (done) ...[_gap, TpButton(label: 'Concluir', block: true, onPressed: state.closeModal)],
    ];
  }

  List<Widget> _partial(BuildContext context, TpColors c) => [
        _icon(c.warningBg, c.warningText, LucideIcons.circleAlert),
        _gap,
        const Text('Despachar Kit Parcial?', style: _h2),
        _gap,
        const TpBanner(
            tone: BannerTone.warn,
            icon: LucideIcons.triangleAlert,
            title: 'Farol LED esquerdo em falta',
            body: 'Peça NÃO-BLOCANTE. Juliana Costa autorizou envio parcial no pedido.'),
        _gap,
        const Muted('Os 5 itens coletados seguem agora. O farol vai depois, pela reposição OP-3310.'),
        _gap,
        TpButton(label: 'Despachar parcial', icon: LucideIcons.truck, block: true, onPressed: state.partialYes),
        const SizedBox(height: 8),
        TpButton(label: 'Aguardar a peça', variant: TpVariant.ghost, block: true, onPressed: state.partialNo),
      ];

  List<Widget> _report(BuildContext context, TpColors c) => [
        Row(children: [
          const Expanded(child: Text('Reportar peça', style: _h2)),
          TpIconButton(icon: LucideIcons.x, tooltip: 'Fechar', onTap: state.closeModal),
        ]),
        const SizedBox(height: 8),
        const _Label('Peça'),
        DropdownButtonFormField<String>(
          icon: const Icon(LucideIcons.chevronDown),
          initialValue: kit142.first.name,
          isExpanded: true,
          items: [for (final p in kit142.where((p) => !p.missing)) DropdownMenuItem(value: p.name, child: Text(p.name))],
          onChanged: (_) {},
        ),
        _gap,
        const _ReportKind(),
        _gap,
        if (state.reportPhoto) const PhotoThumb(name: 'IMG_KT0142_01.jpg') else PhotoPlaceholder(label: 'Tirar foto', onTap: state.takeReportPhoto),
        _gap,
        const _Label('Comentário'),
        const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'Ex.: rosca do suporte espanada')),
        _gap,
        TpButton(label: 'Enviar relato ao Estoque', icon: LucideIcons.send, variant: TpVariant.danger, block: true, onPressed: state.reportSend),
      ];
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TpColors.of(context).textSecondary)),
      );
}

class _ReportKind extends StatefulWidget {
  const _ReportKind();

  @override
  State<_ReportKind> createState() => _ReportKindState();
}

class _ReportKindState extends State<_ReportKind> {
  String value = 'Danificada';

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
        segments: const [ButtonSegment(value: 'Danificada', label: Text('Danificada')), ButtonSegment(value: 'Incompatível', label: Text('Incompatível'))],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (s) => setState(() => value = s.first),
      );
}

/// Placeholder de foto (câmera simulada).
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
              color: c.surfaceMuted, borderRadius: BorderRadius.circular(TpRadius.radiusIcon), border: Border.all(color: c.textSecondary, width: 2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.camera, color: c.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

/// Miniatura genérica depois de "tirar" a foto.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
            gradient:
                const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8AA8B6), Color(0xFF547C90), Color(0xFF3B5A69)]),
          ),
          child: const Icon(LucideIcons.image, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [const Text('Foto anexada', style: TextStyle(fontWeight: FontWeight.w700)), Muted(name, size: 13)])),
      ]);
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock_data.dart';
import '../../state/demo_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/modal.dart';
import '../../widgets/read_row.dart';
import '../../widgets/route_step.dart';
import '../../widgets/scanner_view.dart';
import '../../widgets/tags.dart';
import '../common.dart';

/// E-FUNC2 · Conferência de recebimento (MN-0457) com inspeção de qualidade peça a peça.
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
    final last = s.recvLast, lido = ok >= manifest, blq = s.recvReprovadas.length;
    return ScreenColumn(children: [
      Row(spacing: 10, children: [
        Expanded(child: StatTile(label: 'MANIFESTO', value: '$manifest')),
        Expanded(child: StatTile(label: 'LIDO', value: '$ok', tone: lido ? StatTone.ok : StatTone.none)),
        if (lido) Expanded(child: StatTile(label: 'BLOQUEIO', value: '$blq', tone: blq > 0 ? StatTone.warn : StatTone.none)),
      ]),
      if (done)
        TpBanner(
          tone: blq > 0 ? BannerTone.warn : BannerTone.ok,
          icon: blq > 0 ? LucideIcons.shieldAlert : LucideIcons.circleCheck,
          title: 'Recebimento concluído',
          body: blq > 0
              ? '${ok - blq} peças guardadas em $guardAddress. $blq ${blq == 1 ? 'bloqueada' : 'bloqueadas'} na quarentena $quarentena, aguardando a decisão de $gestorEstoque.'
              : '$manifest peças guardadas em $guardAddress.',
        )
      else if (!lido)
        ScannerView(last: last),
      if (!done && !lido && last != null && last.ok)
        RouteStepCard(
            eyebrow: 'GUARDAR EM', where: guardAddress, detail: '${descreverEndereco(guardAddress)}\n${last.code} · Farol LED esquerdo'),
      if (!done && more) TpButton(label: 'Simular leitura', icon: LucideIcons.scanLine, variant: TpVariant.secondary, block: true, onPressed: s.recvScan),
      if (lido && !done) const _Inspecao(),
      const SectionTitle('Leituras'),
      for (final r in s.recvReads.reversed) ReadRow(r, bloqueada: r.ok ? s.recvReprovadas[r.code] : null),
      // Defeito 1: habilita quando as 8 peças do manifesto forem lidas (e nenhuma reprovação estiver aberta).
      if (!done)
        TpButton(label: 'Concluir recebimento', icon: LucideIcons.check, block: true, onPressed: lido && s.inspPeca == null ? s.recvDone : null),
    ]);
  }
}

class _Inspecao extends StatelessWidget {
  const _Inspecao();

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final blq = s.recvReprovadas.length;
    return TpCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
        CardHeadRow(
          title: 'Inspeção de qualidade',
          trailing: blq > 0
              ? TpTag('$blq ${blq == 1 ? 'REPROVADA' : 'REPROVADAS'}', tone: TagTone.warn, icon: LucideIcons.shieldAlert)
              : const TpTag('TODAS APROVADAS', tone: TagTone.ok, icon: LucideIcons.shieldCheck),
        ),
        Muted('Confira peça a peça. As aprovadas vão para o estoque; as reprovadas ficam bloqueadas na quarentena (Zona Q) até $gestorEstoque decidir o destino.',
            size: 14),
        for (final code in s.recvLidas) _Peca(code),
        if (blq == 0 && s.inspPeca == null)
          TpButton(label: 'Simular inspeção', icon: LucideIcons.clipboardCheck, variant: TpVariant.secondary, block: true, onPressed: s.simularInspecao),
      ]),
    );
  }
}

class _Peca extends StatelessWidget {
  const _Peca(this.code);
  final String code;

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final c = TpColors.of(context);
    final motivo = s.recvReprovadas[code], aberta = s.inspPeca == code;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: motivo != null ? c.warningBg : c.surface,
        borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
        border: Border.all(color: aberta ? c.primary : motivo != null ? c.warning : c.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(code, style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
              Text(motivo != null ? 'Reprovada · $motivo' : aberta ? 'Reprovando…' : 'Aprovada',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: motivo != null ? c.warningText : aberta ? c.primary : c.success)),
            ]),
          ),
          if (motivo != null)
            TpButton(label: 'Desfazer', variant: TpVariant.ghost, small: true, onPressed: () => s.aprovar(code))
          else if (!aberta)
            TpButton(label: 'Reprovar', icon: LucideIcons.shieldAlert, variant: TpVariant.dangerOutline, small: true, onPressed: () => s.abrirInspecao(code)),
        ]),
        if (aberta) ...[
          const Text('Motivo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in motivosQualidade) _Chip(m, selecionado: s.inspMotivo == m, onTap: () => s.escolherMotivo(m)),
          ]),
          if (s.inspFoto) PhotoThumb(name: 'IMG_${code.substring(3)}.jpg') else PhotoPlaceholder(label: 'Tirar foto da peça', onTap: s.fotoInspecao),
          const TextField(maxLines: 2, decoration: InputDecoration(hintText: 'Comentário (opcional)')),
          Row(spacing: 8, children: [
            Expanded(child: TpButton(label: 'Confirmar reprovação', variant: TpVariant.danger, small: true, onPressed: s.reprovar)),
            TpButton(label: 'Cancelar', variant: TpVariant.ghost, small: true, onPressed: s.fecharInspecao),
          ]),
        ],
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.selecionado, required this.onTap});
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final forma = StadiumBorder(side: BorderSide(color: selecionado ? c.primary : c.line, width: 1.5));
    return Semantics(
      button: true,
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selecionado ? c.primarySoft : c.surface,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
              if (selecionado) Icon(LucideIcons.check, size: 14, color: c.primary),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selecionado ? c.primary : c.text)),
            ]),
          ),
        ),
      ),
    );
  }
}

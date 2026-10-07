import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';
import '../widgets/banner.dart';
import '../widgets/buttons.dart';
import 'ia_config.dart';
import 'ia_servico.dart';

/// Abre a configuração do servidor de IA (IP, porta, FPS) com teste de conexão.
Future<void> abrirConfigIa(BuildContext context) {
  final ia = IaScope.read(context);
  if (ia == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => IaScope(servico: ia, child: const _ConfigIa()),
  );
}

class _ConfigIa extends StatefulWidget {
  const _ConfigIa();

  @override
  State<_ConfigIa> createState() => _ConfigIaState();
}

class _ConfigIaState extends State<_ConfigIa> {
  late final IaServico ia = IaScope.read(context)!;
  late final _host = TextEditingController(text: ia.config.host);
  late final _porta = TextEditingController(text: '${ia.config.porta}');
  late bool _ativa = ia.config.ativa;
  late int _fps = ia.config.fps;
  bool _testando = false;
  (bool, String)? _teste;

  IaConfig get _rascunho => IaConfig(ativa: _ativa, host: _host.text.trim(), porta: int.tryParse(_porta.text) ?? 8000, fps: _fps);

  @override
  void dispose() {
    _host.dispose();
    _porta.dispose();
    super.dispose();
  }

  Future<void> _testar() async {
    setState(() {
      _testando = true;
      _teste = null;
    });
    final r = await IaServico.testarConexao(_rascunho);
    if (mounted) {
      setState(() {
        _testando = false;
        _teste = r;
      });
    }
  }

  Future<void> _salvar() async {
    await ia.aplicarConfig(_rascunho);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final atual = IaScope.of(context)!;
    Widget label(String t) =>
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textSecondary)));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: [
            const Text('Servidor de IA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(
              'A câmera dos leitores envia quadros para a API de detecção no Mac, pela mesma rede Wi-Fi. '
              'O IP aparece no terminal quando a API sobe (python -m app).',
              style: TextStyle(color: c.textSecondary, height: 1.4),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _ativa,
              onChanged: (v) => setState(() => _ativa = v),
              title: const Text('Câmera com IA nos leitores', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Desligada, o visor volta ao modo simulado.'),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
              Expanded(
                flex: 3,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  label('IP do servidor'),
                  TextField(
                    controller: _host,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z.\-]'))],
                    decoration: const InputDecoration(hintText: 'Ex.: 192.168.0.20'),
                  ),
                ]),
              ),
              Expanded(
                flex: 2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  label('Porta'),
                  TextField(controller: _porta, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                ]),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              label('Quadros por segundo'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 5, label: Text('5')),
                  ButtonSegment(value: 8, label: Text('8')),
                  ButtonSegment(value: 10, label: Text('10'))
                ],
                selected: {_fps},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _fps = s.first),
              ),
            ]),
            if (_teste != null)
              TpBanner(
                tone: _teste!.$1 ? BannerTone.ok : BannerTone.bad,
                icon: _teste!.$1 ? LucideIcons.circleCheck : LucideIcons.circleX,
                title: _teste!.$1 ? 'Servidor encontrado' : 'Não deu certo',
                body: _teste!.$2,
              ),
            if (atual.ultimoErro != null && _teste == null)
              TpBanner(tone: BannerTone.warn, icon: LucideIcons.triangleAlert, title: 'Último problema', body: atual.ultimoErro),
            if (atual.estado == IaEstado.conectada && atual.modeloServidor != null)
              TpBanner(
                tone: BannerTone.info,
                icon: LucideIcons.info,
                title: 'Em uso: ${atual.modeloServidor} em ${atual.dispositivoServidor}',
                body:
                    'Latência ${atual.latenciaMs?.round() ?? '–'} ms · inferência ${atual.inferenciaMs?.round() ?? '–'} ms · ${atual.fps.toStringAsFixed(1)} fps',
              ),
            TpButton(
              label: _testando ? 'Testando…' : 'Testar conexão',
              icon: LucideIcons.wifi,
              variant: TpVariant.outline,
              block: true,
              onPressed: _testando ? null : _testar,
            ),
            TpButton(label: 'Salvar', icon: LucideIcons.check, block: true, onPressed: _salvar),
          ]),
        ),
      ),
    );
  }
}

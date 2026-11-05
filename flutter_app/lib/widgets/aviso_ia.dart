import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ia/ia_config_sheet.dart';
import '../ia/ia_servico.dart';
import 'banner.dart';
import 'buttons.dart';

/// Orientação das leituras feitas só pela câmera: o que apontar, ou como ligar a IA se ela não estiver conectada.
class AvisoCameraIa extends StatelessWidget {
  const AvisoCameraIa({super.key, required this.pecas});

  /// O que o colaborador deve mostrar à câmera (ex.: "a Engrenagem e a Pinça de freio").
  final String pecas;

  @override
  Widget build(BuildContext context) {
    final ia = IaScope.of(context);
    if (ia != null && ia.estado == IaEstado.conectada) {
      return TpBanner(
        tone: BannerTone.info,
        icon: LucideIcons.scanEye,
        title: 'Mostre $pecas para a câmera',
        body: 'A leitura vale quando a peça fica cerca de 1 segundo no visor.',
      );
    }
    return TpBanner(
      tone: BannerTone.warn,
      icon: LucideIcons.scanEye,
      title: 'Esta leitura é feita pela câmera com a IA',
      body: ia == null || !ia.suportaCamera
          ? 'Abra o app no celular Android, com o servidor de IA ligado na mesma rede Wi-Fi.'
          : 'Conecte o servidor de IA para validar as peças.',
      action: ia != null && ia.suportaCamera ? TpLink(label: 'Configurar servidor de IA', onTap: () => abrirConfigIa(context)) : null,
    );
  }
}

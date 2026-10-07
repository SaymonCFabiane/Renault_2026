import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../ia/ia_config_sheet.dart';
import '../ia/ia_mapeamento.dart';
import '../ia/ia_protocolo.dart';
import '../ia/ia_servico.dart';
import '../ia/rotulos_coco.dart';
import '../theme/tokens.dart';
import 'qr_painter.dart';

const _okColor = Color(0xFF4FD39A);
const _badColor = Color(0xFFFF6B5E);
const _idleColor = Color(0xFFE9F3F7);
const _caixaColor = Color(0xFFFFB27A);

/// Visor do leitor. Com o servidor de IA, mostra a câmera real com as caixas detectadas;
/// sem câmera (web, testes) ou com a IA desligada, mostra o visor simulado.
/// As leituras de QR continuam simuladas nos dois casos.
class ScannerView extends StatefulWidget {
  const ScannerView({super.key, this.last, this.idle = 'Aponte a câmera para o QR Code'});
  final ScanRead? last;
  final String idle;

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with SingleTickerProviderStateMixin {
  late final AnimationController _laser = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  IaServico? _ia;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ia = IaScope.read(context);
    if (ia != _ia) {
      _ia?.liberar();
      _ia = ia?..adquirir();
    }
    _sync();
  }

  @override
  void didUpdateWidget(ScannerView old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = widget.last != null || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _laser.stop();
    } else if (!_laser.isAnimating) {
      _laser.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ia?.liberar();
    _laser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ia = IaScope.of(context);
    final last = widget.last;
    final color = last == null ? _idleColor : (last.ok ? _okColor : _badColor);
    final msg = last == null ? widget.idle : (last.ok ? '${last.code} · OK' : last.msg!);
    final msgIcon = last == null ? LucideIcons.scanLine : (last.ok ? LucideIcons.circleCheck : LucideIcons.circleX);
    final msgBg = last == null ? const Color(0x88000000) : (last.ok ? const Color(0xFF1F6B4C) : const Color(0xFFA3281C));
    final aoVivo = ia != null && ia.cameraPronta && ia.camera != null;
    final mostrarChip = ia != null && ia.suportaCamera;

    return Semantics(
      label: 'Visor da câmera. $msg${aoVivo && ia.deteccoes.isNotEmpty ? '. ${ia.deteccoes.length} objetos detectados' : ''}',
      child: AspectRatio(
        aspectRatio: aoVivo ? ia.aspectoAnalise : 4 / 3,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TpRadius.radiusCard),
            gradient: const RadialGradient(center: Alignment(0, -.1), radius: .9, colors: [Color(0xFF23404D), Color(0xFF0D1A20)]),
          ),
          foregroundDecoration: last == null
              ? null
              : BoxDecoration(borderRadius: BorderRadius.circular(TpRadius.radiusCard), border: Border.all(color: color, width: 4)),
          child: LayoutBuilder(builder: (context, box) {
            final side = box.maxWidth * .58;
            return Stack(alignment: Alignment.center, children: [
              if (aoVivo) ...[
                Positioned.fill(child: _Previa(camera: ia.camera!, aspecto: ia.aspectoPrevia)),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CaixasPainter(ia.deteccoes, aspectoAnalise: ia.aspectoAnalise, aspectoPrevia: ia.aspectoPrevia),
                  ),
                ),
              ] else if (last != null)
                Opacity(
                    opacity: .18,
                    child:
                        CustomPaint(size: Size.square(box.maxWidth * .56), painter: QrPainter(last.code, color: Colors.white, background: Colors.transparent))),
              AnimatedBuilder(
                animation: _laser,
                builder: (context, _) => CustomPaint(
                  size: Size.square(side),
                  painter: _FramePainter(color: color, laser: last == null ? _laser.value : null),
                ),
              ),
              if (mostrarChip) Positioned(top: 10, left: 10, child: _ChipIa(ia: ia)),
              if (last != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(TpRadius.radiusPill)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.volume2, size: 14, color: Color(0xFFCFE3EC)),
                      const SizedBox(width: 4),
                      Text(last.ok ? 'bipe' : 'bipe duplo', style: const TextStyle(color: Color(0xFFCFE3EC), fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: msgBg, borderRadius: BorderRadius.circular(TpRadius.radiusPill)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(msgIcon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                  ]),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

/// Prévia da câmera preenchendo o visor (modo "cover").
class _Previa extends StatelessWidget {
  const _Previa({required this.camera, required this.aspecto});
  final CameraController camera;
  final double aspecto;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: 1000 * aspecto, height: 1000, child: CameraPreview(camera)),
        ),
      );
}

/// Selo de estado da IA no canto do visor. Tocar abre a configuração do servidor.
class _ChipIa extends StatelessWidget {
  const _ChipIa({required this.ia});
  final IaServico ia;

  @override
  Widget build(BuildContext context) {
    final (Color ponto, String texto) = switch (ia.estado) {
      IaEstado.conectada => (
          ia.fps > 0 ? _okColor : const Color(0xFFE0A526),
          ia.fps > 0 ? 'IA · ${ia.fps.toStringAsFixed(0)} fps · ${ia.latenciaMs?.round() ?? '–'} ms' : 'IA conectada'
        ),
      IaEstado.conectando => (const Color(0xFFE0A526), 'Conectando à IA…'),
      IaEstado.iniciando => (const Color(0xFFE0A526), 'Abrindo câmera…'),
      IaEstado.semServidor => (_badColor, ia.config.configurada ? 'IA desconectada' : 'Configurar IA'),
      IaEstado.semPermissao => (_badColor, 'Câmera sem permissão'),
      IaEstado.semCamera => (_badColor, 'Câmera indisponível'),
      IaEstado.desligada => (const Color(0xFF9AA9B1), 'IA desligada'),
    };
    return Semantics(
      button: true,
      label: '$texto. Configurar servidor de IA',
      excludeSemantics: true,
      child: Material(
        color: const Color(0x99000000),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => abrirConfigIa(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: ponto, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(texto, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Caixas e rótulos das detecções, convertidos do quadro analisado para o visor.
class _CaixasPainter extends CustomPainter {
  _CaixasPainter(this.deteccoes, {required this.aspectoAnalise, required this.aspectoPrevia});
  final List<DeteccaoIa> deteccoes;
  final double aspectoAnalise, aspectoPrevia;

  @override
  void paint(Canvas canvas, Size size) {
    final traco = Paint()
      ..color = _caixaColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final sombra = Paint()
      ..color = const Color(0x88000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    for (final d in deteccoes) {
      final n = mapearCaixa(d.caixa, aspectoAnalise: aspectoAnalise, aspectoPrevia: aspectoPrevia, aspectoVisor: size.width / size.height);
      final r = Rect.fromLTRB(n.left * size.width, n.top * size.height, n.right * size.width, n.bottom * size.height);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
      canvas
        ..drawRRect(rr, sombra)
        ..drawRRect(rr, traco);
      final tp = TextPainter(
        text: TextSpan(
          text: '${rotuloClasse(d.classe)} ${(d.confianca * 100).round()}%',
          style: const TextStyle(color: Color(0xFF1E2F38), fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Nunito'),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: size.width - 8);
      final topo = r.top - tp.height - 6 < 0 ? r.top + 2 : r.top - tp.height - 6;
      final esquerda = r.left.clamp(0.0, size.width - tp.width - 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(esquerda, topo, tp.width + 8, tp.height + 4), const Radius.circular(4)),
        Paint()..color = _caixaColor,
      );
      tp.paint(canvas, Offset(esquerda + 4, topo + 2));
    }
  }

  @override
  bool shouldRepaint(_CaixasPainter old) => old.deteccoes != deteccoes || old.aspectoAnalise != aspectoAnalise || old.aspectoPrevia != aspectoPrevia;
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.color, this.laser});
  final Color color;
  final double? laser;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 26.0, r = 12.0;
    final w = size.width, h = size.height;
    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x, y + dy * l)
      ..lineTo(x, y + dy * r)
      ..quadraticBezierTo(x, y, x + dx * r, y)
      ..lineTo(x + dx * l, y);
    canvas.drawPath(corner(2, 2, 1, 1), p);
    canvas.drawPath(corner(w - 2, 2, -1, 1), p);
    canvas.drawPath(corner(2, h - 2, 1, -1), p);
    canvas.drawPath(corner(w - 2, h - 2, -1, -1), p);
    if (laser != null) {
      final y = h * (.1 + .78 * laser!);
      canvas.drawLine(
          Offset(w * .08, y),
          Offset(w * .92, y),
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4));
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.laser != laser || old.color != color;
}

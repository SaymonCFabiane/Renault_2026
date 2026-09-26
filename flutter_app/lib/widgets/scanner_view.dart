import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../theme/tokens.dart';
import 'qr_painter.dart';

const _okColor = Color(0xFF4FD39A);
const _badColor = Color(0xFFFF6B5E);
const _idleColor = Color(0xFFE9F3F7);

/// Visor de câmera simulado: moldura de leitura, laser animado e resultado da última leitura.
class ScannerView extends StatefulWidget {
  const ScannerView({super.key, this.last, this.idle = 'Aponte a câmera para o QR Code'});
  final ScanRead? last;
  final String idle;

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with SingleTickerProviderStateMixin {
  late final AnimationController _laser = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _laser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.last;
    final color = last == null ? _idleColor : (last.ok ? _okColor : _badColor);
    final msg = last == null ? widget.idle : (last.ok ? '${last.code} · OK' : last.msg!);
    final msgIcon = last == null ? LucideIcons.scanLine : (last.ok ? LucideIcons.circleCheck : LucideIcons.circleX);
    final msgBg = last == null ? const Color(0x88000000) : (last.ok ? const Color(0xFF1F6B4C) : const Color(0xFFA3281C));
    return Semantics(
      label: 'Visor da câmera. $msg',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TpRadius.radiusCard),
            gradient: const RadialGradient(center: Alignment(0, -.1), radius: .9, colors: [Color(0xFF23404D), Color(0xFF0D1A20)]),
            border: last == null ? null : Border.all(color: color, width: 4),
          ),
          child: LayoutBuilder(builder: (context, box) {
            final side = box.maxWidth * .58;
            return Stack(alignment: Alignment.center, children: [
              if (last != null)
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

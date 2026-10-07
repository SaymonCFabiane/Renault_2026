import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Quadro já comprimido em JPEG (recorte central 4:3, no máximo 640×480, em orientação do sensor).
class QuadroJpeg {
  const QuadroJpeg(this.bytes, this.largura, this.altura);
  final Uint8List bytes;
  final int largura, altura;
}

/// Converte o quadro da câmera (NV21 ou YUV_420_888) em JPEG no código nativo do Android
/// (MainActivity.kt). Em Dart puro a conversão levaria de 50 a 100 ms por quadro.
abstract final class JpegNativo {
  static const _canal = MethodChannel('tracepro/jpeg');

  static Future<QuadroJpeg> converter(CameraImage img, {int qualidade = 70, int larguraMax = 640}) async {
    final r = await _canal.invokeMapMethod<String, Object?>('paraJpeg', {
      'largura': img.width,
      'altura': img.height,
      'planos': [for (final p in img.planes) p.bytes],
      'linhas': [for (final p in img.planes) p.bytesPerRow],
      'pixels': [for (final p in img.planes) p.bytesPerPixel ?? 1],
      'qualidade': qualidade,
      'larguraMax': larguraMax,
    });
    return QuadroJpeg(r!['jpeg']! as Uint8List, r['largura']! as int, r['altura']! as int);
  }
}

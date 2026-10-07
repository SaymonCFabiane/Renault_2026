// Protocolo com a API de detecção (detector_api/app/protocolo.py).
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

/// Monta a mensagem binária de um quadro:
/// [4 bytes: tamanho do cabeçalho, big-endian][cabeçalho JSON UTF-8][bytes do JPEG].
Uint8List montarQuadro({required int seq, required int capturadoEm, required int rotacao, required Uint8List jpeg}) {
  final cabecalho = utf8.encode(jsonEncode({'tipo': 'quadro', 'seq': seq, 'capturado_em': capturadoEm, 'rotacao': rotacao}));
  final tamanho = ByteData(4)..setUint32(0, cabecalho.length, Endian.big);
  return (BytesBuilder(copy: false)
        ..add(tamanho.buffer.asUint8List())
        ..add(cabecalho)
        ..add(jpeg))
      .toBytes();
}

/// Uma detecção: caixa em coordenadas normalizadas (0–1) do quadro analisado, já "em pé".
class DeteccaoIa {
  const DeteccaoIa({required this.classeId, required this.classe, required this.confianca, required this.caixa});

  final int classeId;
  final String classe;
  final double confianca;
  final Rect caixa;

  factory DeteccaoIa.deJson(Map<String, dynamic> j) {
    final c = j['caixa'] as Map<String, dynamic>;
    double n(String k) => (c[k] as num).toDouble();
    return DeteccaoIa(
      classeId: (j['classe_id'] as num).toInt(),
      classe: j['classe'] as String,
      confianca: (j['confianca'] as num).toDouble(),
      caixa: Rect.fromLTRB(n('x1'), n('y1'), n('x2'), n('y2')),
    );
  }
}

/// Mensagem recebida da API.
sealed class RespostaIa {
  const RespostaIa();

  static RespostaIa? deTexto(String texto) {
    final Object? j;
    try {
      j = jsonDecode(texto);
    } on FormatException {
      return null;
    }
    if (j is! Map<String, dynamic>) return null;
    final seq = (j['seq'] as num?)?.toInt();
    return switch (j['tipo']) {
      'deteccoes' => RespostaDeteccoes(
          seq: seq,
          capturadoEm: (j['capturado_em'] as num?)?.toDouble(),
          inferenciaMs: (j['inferencia_ms'] as num?)?.toDouble() ?? 0,
          deteccoes: [for (final d in (j['deteccoes'] as List? ?? const [])) DeteccaoIa.deJson(d as Map<String, dynamic>)],
        ),
      'descartado' => RespostaDescartado(seq),
      'erro' => RespostaErro(seq: seq, codigo: '${j['codigo']}', mensagem: '${j['mensagem']}'),
      'status' => RespostaStatus(modelo: j['modelo'] as String?, dispositivo: j['dispositivo'] as String?, versao: j['versao'] as String?),
      _ => null,
    };
  }
}

class RespostaDeteccoes extends RespostaIa {
  const RespostaDeteccoes({required this.seq, required this.capturadoEm, required this.inferenciaMs, required this.deteccoes});
  final int? seq;
  final double? capturadoEm;
  final double inferenciaMs;
  final List<DeteccaoIa> deteccoes;
}

class RespostaDescartado extends RespostaIa {
  const RespostaDescartado(this.seq);
  final int? seq;
}

class RespostaErro extends RespostaIa {
  const RespostaErro({required this.seq, required this.codigo, required this.mensagem});
  final int? seq;
  final String codigo, mensagem;
}

class RespostaStatus extends RespostaIa {
  const RespostaStatus({this.modelo, this.dispositivo, this.versao});
  final String? modelo, dispositivo, versao;
}

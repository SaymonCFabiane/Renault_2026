// Conversa com a API Python de verdade (detector_api). Se ela não estiver rodando em
// localhost:8000, os testes são pulados. Para rodar: cd ../detector_api && .venv/bin/python -m app
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/ia/ia_config.dart';
import 'package:flutter_app/ia/ia_protocolo.dart';
import 'package:flutter_app/ia/ia_servico.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _cfg = IaConfig(host: '127.0.0.1', porta: 8000);
final _bus = File('../detector_api/.venv/lib/python3.12/site-packages/ultralytics/assets/bus.jpg');

Future<bool> _apiNoAr() async {
  try {
    final s = await Socket.connect('127.0.0.1', 8000, timeout: const Duration(milliseconds: 500));
    s.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool noAr;
  setUpAll(() async => noAr = await _apiNoAr() && _bus.existsSync());

  test('testarConexao encontra a API', () async {
    if (!noAr) return markTestSkipped('API não está rodando em localhost:8000');
    final (ok, msg) = await IaServico.testarConexao(_cfg);
    expect(ok, isTrue, reason: msg);
    expect(msg, contains('Conectado: modelo'));
  });

  test('quadro do app → detecções da API (protocolo dos dois lados)', () async {
    if (!noAr) return markTestSkipped('API não está rodando em localhost:8000');
    final canal = WebSocketChannel.connect(_cfg.urlWs);
    await canal.ready;
    final respostas = StreamIterator(canal.stream);
    final inicio = DateTime.now().millisecondsSinceEpoch;
    canal.sink.add(montarQuadro(seq: 7, capturadoEm: inicio, rotacao: 0, jpeg: await _bus.readAsBytes()));
    expect(await respostas.moveNext(), isTrue);
    final r = RespostaIa.deTexto(respostas.current as String);
    expect(r, isA<RespostaDeteccoes>());
    final d = r! as RespostaDeteccoes;
    expect((d.seq, d.capturadoEm), (7, inicio.toDouble()));
    // bus.jpg só tem classes do COCO: confere as classes com o modelo base; com um modelo treinado, só o protocolo.
    final status = jsonDecode(await (await HttpClient().getUrl(Uri.parse('http://127.0.0.1:8000/status'))).close().then((r) => r.transform(utf8.decoder).join()));
    if (status['modelo'] == 'yolo11n.pt') expect(d.deteccoes.map((x) => x.classe), containsAll(['person', 'bus']));
    for (final x in d.deteccoes) {
      expect(x.caixa.left >= 0 && x.caixa.right <= 1 && x.caixa.top >= 0 && x.caixa.bottom <= 1, isTrue);
    }

    canal.sink.add(jsonEncode({'tipo': 'config', 'imgsz': 333}));
    expect(await respostas.moveNext(), isTrue);
    final e = RespostaIa.deTexto(respostas.current as String);
    expect(e, isA<RespostaErro>());
    expect((e! as RespostaErro).codigo, 'PARAMETRO_INVALIDO');
    await canal.sink.close();
  });
}

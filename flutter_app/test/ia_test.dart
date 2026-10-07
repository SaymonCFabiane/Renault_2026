import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/ia/ia_mapeamento.dart';
import 'package:flutter_app/ia/ia_protocolo.dart';
import 'package:flutter_app/ia/ia_servico.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/state/demo_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  test('montarQuadro: cabeçalho com tamanho big-endian, JSON e JPEG', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);
    final b = montarQuadro(seq: 42, capturadoEm: 1000, rotacao: 90, jpeg: jpeg);
    final n = ByteData.sublistView(b, 0, 4).getUint32(0, Endian.big);
    final cab = jsonDecode(utf8.decode(b.sublist(4, 4 + n))) as Map;
    expect(cab, {'tipo': 'quadro', 'seq': 42, 'capturado_em': 1000, 'rotacao': 90});
    expect(b.sublist(4 + n), jpeg);
  });

  test('RespostaIa: interpreta as mensagens da API', () {
    final d = RespostaIa.deTexto(jsonEncode({
      'tipo': 'deteccoes',
      'seq': 3,
      'capturado_em': 99,
      'inferencia_ms': 12.5,
      'deteccoes': [
        {
          'classe_id': 0,
          'classe': 'person',
          'confianca': .9,
          'caixa': {'x1': .1, 'y1': .2, 'x2': .3, 'y2': .4}
        }
      ]
    }));
    expect(d, isA<RespostaDeteccoes>());
    final r = d! as RespostaDeteccoes;
    expect((r.seq, r.inferenciaMs, r.deteccoes.single.caixa), (3, 12.5, const Rect.fromLTRB(.1, .2, .3, .4)));
    expect(RespostaIa.deTexto('{"tipo":"descartado","seq":2}'), isA<RespostaDescartado>());
    final e = RespostaIa.deTexto('{"tipo":"erro","codigo":"IMAGEM_INVALIDA","mensagem":"x","seq":1}')! as RespostaErro;
    expect((e.codigo, e.seq), ('IMAGEM_INVALIDA', 1));
    expect(RespostaIa.deTexto('não é json'), isNull);
    expect(RespostaIa.deTexto('{"tipo":"outro"}'), isNull);
  });

  group('mapearCaixa', () {
    const caixa = Rect.fromLTRB(.2, .3, .6, .9);
    test('mesmo aspecto em tudo: não muda', () {
      final r = mapearCaixa(caixa, aspectoAnalise: .75, aspectoPrevia: .75, aspectoVisor: .75);
      expect(r.left, closeTo(.2, 1e-9));
      expect(r.bottom, closeTo(.9, 1e-9));
    });
    test('prévia 2:3 (720×480) e análise 3:4 (recorte 640×480) no visor 3:4', () {
      // O visor 3:4 mostra exatamente o recorte que foi analisado: as caixas não mudam.
      final r = mapearCaixa(caixa, aspectoAnalise: .75, aspectoPrevia: 2 / 3, aspectoVisor: .75);
      expect(r.top, closeTo(.3, 1e-9));
      expect(r.left, closeTo(.2, 1e-9));
    });
    test('visor 4:3 deitado sobre a mesma prévia: caixa central encolhe na largura e cresce na altura', () {
      // O visor mostra uma faixa horizontal do recorte analisado.
      final r = mapearCaixa(const Rect.fromLTRB(.25, .25, .75, .75), aspectoAnalise: .75, aspectoPrevia: 2 / 3, aspectoVisor: 4 / 3);
      expect(r.left, closeTo(.25, 1e-9));
      expect(r.height, greaterThan(.5));
    });
    test('visor mais largo que a análise corta em cima e embaixo', () {
      final r = mapearCaixa(const Rect.fromLTRB(0, 0, 1, 1), aspectoAnalise: .75, aspectoPrevia: .75, aspectoVisor: 4 / 3);
      expect(r.left, closeTo(0, 1e-9));
      expect(r.right, closeTo(1, 1e-9));
      expect(r.top, lessThan(0));
      expect(r.bottom, greaterThan(1));
    });
  });

  testWidgets('sem câmera: visor simulado com selo; o selo abre e salva a configuração da IA', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    await loadFonts();
    usePhone(tester);
    SharedPreferences.setMockInitialValues({});
    final ia = IaServico(suportaCamera: true);
    final s = DemoState()
      ..pickProfile('bruno')
      ..go(Screen.fFunc3);
    await tester.pumpWidget(TraceProApp(state: s, ia: ia));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Abrindo câmera…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    // No ambiente de teste não há câmera: o selo avisa e o visor continua simulado.
    expect(find.text('Câmera indisponível'), findsOneWidget);
    expect(find.text('Aponte a câmera para o QR Code'), findsOneWidget);

    await tester.tap(find.text('Câmera indisponível'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Servidor de IA'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '10.10.10.108');
    await tester.tap(find.text('10'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect((ia.config.host, ia.config.porta, ia.config.fps), ('10.10.10.108', 8000, 10));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ia_host'), '10.10.10.108');

    s.swapProfile();
    // Salvar reabre a câmera; espera o limite de 5 s do teste (sem câmera) e o desligamento.
    await tester.pump(const Duration(seconds: 7));
    ia.dispose();
  });
}

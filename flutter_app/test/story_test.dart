import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/state/demo_state.dart';
import 'package:flutter_app/widgets/toast.dart';

import 'helpers.dart';

/// Roteiro mobile completo, tocando na interface como na apresentação.
void main() {
  setUpAll(loadFonts);

  testWidgets('roteiro: Bruno → Marcos → Fernanda', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    usePhone(tester);
    final s = DemoState();
    await tester.pumpWidget(TraceProApp(state: s));

    Future<void> tap(String text, {int index = 0}) async {
      final f = find.text(text).at(index);
      await tester.ensureVisible(f);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(f);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 150));
    }

    Future<void> tapTip(String tip) async {
      await tester.tap(find.byTooltip(tip));
      await tester.pump(const Duration(milliseconds: 150));
    }

    // Bruno: libera (simulado), imprime e bipa 8/10 com 1 repetida.
    await tap('Bruno Lima');
    await tap('Simular liberação pelo painel web');
    await tap('Registrar e imprimir etiquetas');
    await tap('Imprimir Etiquetas');
    expect(find.textContaining('Enviando 10 etiquetas'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Concluir'), findsOneWidget);
    await tap('Concluir');
    expect(s.labelsPrinted, isTrue);
    await tap('Carregamento', index: 0);
    for (var i = 0; i < 3; i++) {
      await tap('Simular leitura');
    }
    expect(s.loadOk.length, 8);
    expect(find.text('Peça repetida'), findsWidgets);
    await tap('Enviar para Aprovação do ADM');
    expect(s.mn0457, 'Aguardando Aprovação');

    // Defeito 3: trocar perfil a partir de uma tela interna.
    await tapTip('Trocar perfil');
    expect(find.text('Quem vai trabalhar agora?'), findsOneWidget);

    // Marcos: chegada simulada, confere as 8 peças (defeito 1).
    await tap('Marcos Souza');
    await tap('Simular chegada na doca');
    await tap('Conferir recebimento');
    var bad = 0;
    while (s.recvSeqIdx < 9) {
      await tap('Simular leitura');
      if (s.recvLast?.ok == false) bad++;
    }
    expect(bad, 1);
    expect(s.recvOkCount, 8);
    await tap('Concluir recebimento');
    expect(s.mn0457, 'Recebido');

    // Coleta do KT-0142 com leitura inválida e kit parcial.
    await tap('Coleta');
    await tap('Simular leitura do QR');
    await tap('Simular leitura do QR');
    expect(find.text('Peça não pertence a este kit'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tap('Simular leitura do QR');
    }
    await tap('Registrar falta');
    expect(find.text('Despachar Kit Parcial?'), findsOneWidget);
    await tap('Despachar parcial');
    expect(s.k142ready, isTrue);

    // Exceção: coleta travada do KT-0139.
    await tap('Coleta');
    await tap('Ver exceção: KT-0139 com peça blocante em falta');
    expect(find.text('Coleta travada'), findsOneWidget);
    await tap('Voltar para a fila');

    // Expedição
    await tap('Expedição');
    await tap('Simular leitura');
    await tap('Fernanda Rocha');
    await tap('Confirmar expedição');
    expect(s.kits['KT-0142'], 'Em Trânsito');

    // Fernanda: confere, reporta com foto e dá o aceite.
    await tapTip('Trocar perfil');
    await tap('Fernanda Rocha');
    expect(find.text('KT-0142 chegou'), findsOneWidget);
    await tap('KT-0142 chegou');
    for (var i = 0; i < 6; i++) {
      await tap('Simular leitura');
    }
    await tap('Reportar Peça Danificada/Incompatível');
    await tap('Tirar foto');
    expect(find.text('Foto anexada'), findsOneWidget);
    await tap('Enviar relato ao Estoque');
    expect(s.accReported, isTrue);
    await tap('Dar Aceite e Liberar para Montagem');
    expect(s.kits['KT-0142'], 'Entregue Parcial');

    // Defeito 4: um toast por vez.
    expect(find.byType(ToastView), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(s.toast, isNull);
  });
}

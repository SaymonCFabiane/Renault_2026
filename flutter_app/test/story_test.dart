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

    // Inspeção de qualidade peça a peça: motivo e foto são obrigatórios.
    expect(find.text('Inspeção de qualidade'), findsOneWidget);
    await tap('Reprovar', index: 2); // PC-000203
    await tap('Confirmar reprovação');
    expect(s.recvReprovadas, isEmpty);
    await tap('Avaria ou trinca');
    await tap('Confirmar reprovação');
    expect(s.recvReprovadas, isEmpty);
    await tap('Tirar foto da peça');
    await tap('Confirmar reprovação');
    expect(s.recvReprovadas, {'PC-000203': 'Avaria ou trinca'});
    await tap('Reprovar', index: 4); // PC-000206
    await tap('Peça errada');
    await tap('Tirar foto da peça');
    await tap('Confirmar reprovação');
    expect(s.recvReprovadas.keys, ['PC-000203', 'PC-000206']);
    expect(find.text('Bloqueada · Peça errada · Q-01-03-01-01'), findsOneWidget);
    await tap('Concluir recebimento');
    expect(s.mn0457, 'Recebido');
    expect(find.textContaining('6 peças guardadas'), findsOneWidget);
    expect(find.textContaining('2 bloqueadas na quarentena Q-01-03-01-01'), findsOneWidget);

    // Coleta do KT-0142: só falta a Pinça de freio. A Engrenagem é recusada; a Pinça fecha o kit (parcial).
    await tap('Coleta');
    expect(find.text('Falta 1 peça'), findsOneWidget);
    expect(find.text('Simular leitura do QR'), findsNothing);
    s.coletarRotaPorIa('Engrenagem');
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Engrenagem não pertence a este kit'), findsOneWidget);
    expect(s.k142ready, isFalse);
    s.coletarRotaPorIa('Pinça de freio');
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Kit fechado · parcial'), findsOneWidget);
    expect(s.k142ready, isTrue);

    // KT-0145: faltam 2 peças, validadas pela câmera (a IA chama coletarPorIa com a classe detectada).
    await tap('Tarefas');
    await tap('Montagem');
    await tap('Coletar com a câmera');
    expect(find.text('Coleta do KT-0145'), findsWidgets);
    expect(find.text('Simular leitura'), findsNothing);
    expect(find.text('3 de 5'), findsOneWidget);
    s.coletarPorIa('Engrenagem');
    s.coletarPorIa('Pinça de freio');
    await tester.pump(const Duration(milliseconds: 150));
    expect(s.col145.length, 5);
    await tap('Concluir montagem');
    expect(s.k145ready, isTrue);

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
    // Só falta a Pinça de freio, conferida pela câmera; a Engrenagem é recusada.
    expect(find.text('Simular leitura'), findsNothing);
    expect(s.accGot.length, 4);
    s.conferirPorIa('Engrenagem');
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Engrenagem não pertence a este kit'), findsOneWidget);
    expect(s.accGot.length, 4);
    s.conferirPorIa('Pinça de freio');
    await tester.pump(const Duration(milliseconds: 150));
    expect(s.accGot.length, 5);
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

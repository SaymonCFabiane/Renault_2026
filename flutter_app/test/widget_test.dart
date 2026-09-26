import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/state/demo_state.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('Seleção de perfil mostra os 3 funcionários e abre Lotes liberados', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(TraceProApp(state: DemoState()));
    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Marcos Souza'), findsOneWidget);
    expect(find.text('Fernanda Rocha'), findsOneWidget);

    await tester.tap(find.text('Bruno Lima'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lotes liberados'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}

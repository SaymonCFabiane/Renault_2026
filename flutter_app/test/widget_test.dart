import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('Home renderiza', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Ambiente pronto. Aguardando escopo.'), findsOneWidget);
  });
}

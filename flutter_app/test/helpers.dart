import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carrega a Nunito real para medir textos como no app (evita falsos overflows da fonte de teste).
Future<void> loadFonts() async {
  final loader = FontLoader('Nunito');
  for (final f in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Nunito-$f.ttf'));
  }
  await loader.load();
}

/// Frame do protótipo: 390×844.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

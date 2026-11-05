import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/state/demo_state.dart';

import 'helpers.dart';

/// Renderiza as 10 telas e a seleção de perfil a 390×844, nos dois temas e em três
/// momentos da história. Qualquer overflow (faixa amarelo-e-preto) faz o teste falhar.
void main() {
  setUpAll(loadFonts);

  const owner = {
    Screen.fFunc1: 'bruno',
    Screen.fFunc2: 'bruno',
    Screen.fFunc3: 'bruno',
    Screen.eFunc1: 'marcos',
    Screen.eFunc2: 'marcos',
    Screen.eFunc3: 'marcos',
    Screen.eFunc4: 'marcos',
    Screen.eFunc5: 'marcos',
    Screen.tFunc1: 'fernanda',
    Screen.tFunc2: 'fernanda',
  };

  for (final dark in [false, true]) {
    for (final moment in ['inicio', 'meio', 'fim']) {
      testWidgets('todas as telas · ${dark ? 'escuro' : 'claro'} · $moment', (tester) async {
        usePhone(tester);
        final s = DemoState()..dark = dark;
        if (moment == 'meio') {
          s.advance('shipped');
        }
        if (moment == 'fim') s.advance('accepted');
        await tester.pumpWidget(TraceProApp(state: s));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Quem vai trabalhar agora?'), findsOneWidget);

        for (final entry in owner.entries) {
          s.pickProfile(entry.value);
          s.go(entry.key);
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text(screenTitles[entry.key]!), findsWidgets);
          // Rola até o fim para montar e medir todos os itens da tela.
          final scroll = find.byType(Scrollable).first;
          await tester.drag(scroll, const Offset(0, -4000));
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Tabs do Marcos
        for (final t in ['Recebimentos', 'Montagem de Kits', 'Kits para Despacho']) {
          s.pickProfile('marcos');
          s.setMarcosTab(t);
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Sobreposições: modais, tela travada e notificações
        s.pickProfile('marcos');
        s.go(Screen.eFunc3);
        for (final m in ModalKind.values) {
          s.modal = m;
          s.printProgress = 100;
          s.toastOnly(ToastKind.ok, 'Teste de toast longo para verificar quebra de linha.');
          await tester.pump(const Duration(milliseconds: 100));
        }
        s.closeModal();
        s.showLock();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Coleta travada'), findsOneWidget);
        s.unlock();
        s.toggleNotes();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Notificações'), findsOneWidget);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

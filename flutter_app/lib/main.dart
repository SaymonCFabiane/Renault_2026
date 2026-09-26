import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'screens/estoque/coleta.dart';
import 'screens/estoque/expedicao.dart';
import 'screens/estoque/recebimento.dart';
import 'screens/estoque/tarefas.dart';
import 'screens/fornecedor/carregamento.dart';
import 'screens/fornecedor/etiquetas.dart';
import 'screens/fornecedor/lotes.dart';
import 'screens/profile_picker.dart';
import 'screens/testes/conferencia_kit.dart';
import 'screens/testes/kits_esperados.dart';
import 'state/demo_state.dart';
import 'theme/app_theme.dart';
import 'widgets/mobile_shell.dart';

void main() {
  runApp(TraceProApp(state: DemoState()));
}

/// App mobile dos funcionários (Bruno, Marcos e Fernanda). Estado só em memória.
class TraceProApp extends StatelessWidget {
  const TraceProApp({super.key, required this.state});
  final DemoState state;

  @override
  Widget build(BuildContext context) {
    return DemoScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'TracePro',
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt', 'BR'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
          home: const _Root(),
        ),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    if (s.profile == null) return const ProfilePicker();
    final Widget body = switch (s.screen) {
      Screen.fFunc1 => const LotesScreen(),
      Screen.fFunc2 => const EtiquetasScreen(),
      Screen.fFunc3 => const CarregamentoScreen(),
      Screen.eFunc1 => const TarefasScreen(),
      Screen.eFunc2 => const RecebimentoScreen(),
      Screen.eFunc3 => const ColetaScreen(),
      Screen.eFunc4 => const ExpedicaoScreen(),
      Screen.tFunc1 => const KitsEsperadosScreen(),
      Screen.tFunc2 => const ConferenciaKitScreen(),
    };
    return MobileShell(state: s, body: body, fab: s.screen == Screen.fFunc1 ? const ScanFab() : null);
  }
}

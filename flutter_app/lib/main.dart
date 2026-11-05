import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/mock_data.dart';
import 'ia/ia_servico.dart';
import 'screens/estoque/coleta.dart';
import 'screens/estoque/coleta_ia.dart';
import 'screens/estoque/expedicao.dart';
import 'screens/estoque/recebimento.dart';
import 'screens/estoque/tarefas.dart';
import 'screens/fornecedor/carregamento.dart';
import 'screens/fornecedor/etiquetas.dart';
import 'screens/fornecedor/lotes.dart';
import 'screens/profile_picker.dart';
import 'screens/cliente/conferencia_kit.dart';
import 'screens/cliente/kits_esperados.dart';
import 'state/demo_state.dart';
import 'theme/app_theme.dart';
import 'widgets/mobile_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // O app é usado em pé; a câmera e as caixas assumem retrato.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Câmera com stream de quadros só no Android (APK). Na web o visor continua simulado.
  final ia = IaServico(suportaCamera: !kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  await ia.carregarConfig();
  WidgetsBinding.instance.addObserver(ia);
  runApp(TraceProApp(state: DemoState(), ia: ia));
}

/// App mobile dos colaboradores (Bruno, Marcos e Fernanda). Estado da demo só em memória.
class TraceProApp extends StatelessWidget {
  const TraceProApp({super.key, required this.state, this.ia});
  final DemoState state;

  /// Câmera + servidor de IA. Nulo nos testes: os visores ficam simulados.
  final IaServico? ia;

  @override
  Widget build(BuildContext context) {
    final app = _app();
    return ia == null ? app : IaScope(servico: ia!, child: app);
  }

  Widget _app() {
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
      Screen.eFunc5 => const ColetaIaScreen(),
      Screen.eFunc4 => const ExpedicaoScreen(),
      Screen.tFunc1 => const KitsEsperadosScreen(),
      Screen.tFunc2 => const ConferenciaKitScreen(),
    };
    return MobileShell(state: s, body: body, fab: s.screen == Screen.fFunc1 ? const ScanFab() : null);
  }
}

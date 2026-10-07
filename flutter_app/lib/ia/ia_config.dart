import 'package:shared_preferences/shared_preferences.dart';

/// Endereço do servidor de IA e parâmetros de transmissão, salvos no aparelho.
class IaConfig {
  const IaConfig({this.ativa = true, this.host = '', this.porta = 8000, this.fps = 8});

  final bool ativa;
  final String host;
  final int porta;
  final int fps;

  bool get configurada => host.trim().isNotEmpty;
  String get endereco => '${host.trim()}:$porta';
  Uri get urlWs => Uri.parse('ws://${host.trim()}:$porta/ws/detectar');

  IaConfig copyWith({bool? ativa, String? host, int? porta, int? fps}) =>
      IaConfig(ativa: ativa ?? this.ativa, host: host ?? this.host, porta: porta ?? this.porta, fps: fps ?? this.fps);

  static Future<IaConfig> carregar() async {
    final p = await SharedPreferences.getInstance();
    return IaConfig(
      ativa: p.getBool('ia_ativa') ?? true,
      host: p.getString('ia_host') ?? '',
      porta: p.getInt('ia_porta') ?? 8000,
      fps: p.getInt('ia_fps') ?? 8,
    );
  }

  Future<void> salvar() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ia_ativa', ativa);
    await p.setString('ia_host', host.trim());
    await p.setInt('ia_porta', porta);
    await p.setInt('ia_fps', fps);
  }
}

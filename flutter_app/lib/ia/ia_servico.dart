// Câmera + WebSocket com a API de detecção. Uma sessão só, compartilhada pelos visores.
import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ia_config.dart';
import 'ia_protocolo.dart';
import 'jpeg_nativo.dart';

enum IaEstado { desligada, semCamera, semPermissao, iniciando, conectando, conectada, semServidor }

class IaServico extends ChangeNotifier with WidgetsBindingObserver {
  IaServico({required this.suportaCamera, IaConfig? config}) : config = config ?? const IaConfig();

  /// Câmera com stream de quadros só existe no app Android; na web e nos testes o visor fica simulado.
  final bool suportaCamera;
  IaConfig config;

  IaEstado estado = IaEstado.desligada;
  CameraController? camera;
  int rotacao = 90;
  String? ultimoErro;
  String? modeloServidor, dispositivoServidor;

  // Resultado mais recente
  List<DeteccaoIa> deteccoes = const [];
  double? latenciaMs, inferenciaMs;
  double fps = 0;
  double aspectoAnalise = 3 / 4;

  WebSocketChannel? _canal;
  StreamSubscription<dynamic>? _assinatura;
  int _usuarios = 0;
  int _seq = 0;
  int? _seqEmTransito;
  bool _codificando = false;
  int _ultimoEnvio = 0;
  final List<int> _respostas = [];
  Timer? _timeoutQuadro, _reconexao, _desligamento, _vencimento;
  bool _ligando = false;
  bool _descartado = false;

  bool get cameraPronta => camera?.value.isInitialized == true && estado.index >= IaEstado.conectando.index;

  /// Aspecto (largura/altura) da prévia com o aparelho em pé.
  double get aspectoPrevia {
    final s = camera?.value.previewSize;
    if (s == null || s.width == 0) return 3 / 4;
    return s.height / s.width;
  }

  Future<void> carregarConfig() async {
    config = await IaConfig.carregar();
    _avisar();
  }

  /// Um visor entrou na tela.
  void adquirir() {
    _usuarios++;
    _desligamento?.cancel();
    if (_usuarios == 1) scheduleMicrotask(_ligar);
  }

  /// Um visor saiu da tela. Espera um pouco antes de desligar, para a troca entre telas não reiniciar a câmera.
  void liberar() {
    _usuarios = (_usuarios - 1).clamp(0, 1 << 20);
    if (_usuarios == 0) {
      _desligamento?.cancel();
      _desligamento = Timer(const Duration(milliseconds: 800), _desligar);
    }
  }

  Future<void> aplicarConfig(IaConfig nova) async {
    config = nova;
    await nova.salvar();
    await _desligar();
    if (_usuarios > 0) await _ligar();
    _avisar();
  }

  Future<void> _ligar() async {
    if (_ligando || _descartado) return;
    if (!suportaCamera) {
      _mudar(IaEstado.semCamera);
      return;
    }
    if (!config.ativa) {
      _mudar(IaEstado.desligada);
      return;
    }
    _ligando = true;
    try {
      if (camera == null) {
        _mudar(IaEstado.iniciando);
        await _iniciarCamera();
      }
      if (camera != null && _canal == null) await _conectar();
    } finally {
      _ligando = false;
    }
  }

  Future<void> _iniciarCamera() async {
    try {
      const limite = Duration(seconds: 5);
      final cams = await availableCameras().timeout(limite);
      if (cams.isEmpty) {
        _falhaCamera(IaEstado.semCamera, 'Nenhuma câmera encontrada');
        return;
      }
      final traseira = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final c = CameraController(traseira, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
      await c.initialize().timeout(limite);
      await c.lockCaptureOrientation(DeviceOrientation.portraitUp);
      rotacao = traseira.sensorOrientation;
      if (_usuarios == 0 || _descartado) {
        await c.dispose();
        return;
      }
      camera = c;
      await c.startImageStream(_aoQuadro);
      _avisar();
    } on CameraException catch (e) {
      final negada = e.code.contains('AccessDenied') || e.code.contains('Permission');
      _falhaCamera(negada ? IaEstado.semPermissao : IaEstado.semCamera, negada ? 'Permissão da câmera negada' : 'Câmera: ${e.description ?? e.code}');
    } on TimeoutException {
      _falhaCamera(IaEstado.semCamera, 'A câmera não respondeu');
    } catch (e) {
      _falhaCamera(IaEstado.semCamera, 'Câmera indisponível: $e');
    }
  }

  void _falhaCamera(IaEstado e, String msg) {
    ultimoErro = msg;
    _mudar(e);
  }

  Future<void> _conectar() async {
    _reconexao?.cancel();
    if (!config.configurada) {
      ultimoErro = 'Configure o IP do servidor de IA';
      _mudar(IaEstado.semServidor);
      return;
    }
    _mudar(IaEstado.conectando);
    try {
      final canal = WebSocketChannel.connect(config.urlWs);
      await canal.ready.timeout(const Duration(seconds: 4));
      if (_usuarios == 0 || _descartado) {
        await canal.sink.close();
        return;
      }
      _canal = canal;
      _assinatura = canal.stream.listen(
        _aoMensagem,
        onError: (Object e) => _aoCair('Conexão perdida com ${config.endereco}'),
        onDone: () => _aoCair('O servidor encerrou a conexão'),
      );
      canal.sink.add(jsonEncode({'tipo': 'status'}));
      ultimoErro = null;
      _mudar(IaEstado.conectada);
    } catch (_) {
      _aoCair('Sem resposta de ${config.endereco}. Confira o IP, a porta e o Wi-Fi.');
    }
  }

  void _aoCair(String msg) {
    _assinatura?.cancel();
    _assinatura = null;
    _canal = null;
    _seqEmTransito = null;
    deteccoes = const [];
    ultimoErro = msg;
    _mudar(IaEstado.semServidor);
    if (_usuarios > 0 && !_descartado) _reconexao = Timer(const Duration(seconds: 2), _conectar);
  }

  /// Controle de fluxo: no máximo 1 quadro em trânsito e no máximo [IaConfig.fps] por segundo.
  Future<void> _aoQuadro(CameraImage img) async {
    final canal = _canal;
    if (canal == null || _codificando || _seqEmTransito != null) return;
    final agora = DateTime.now().millisecondsSinceEpoch;
    if (agora - _ultimoEnvio < 1000 ~/ config.fps) return;
    _codificando = true;
    _ultimoEnvio = agora;
    try {
      final q = await JpegNativo.converter(img);
      if (_canal != canal) return;
      final emPe = rotacao % 180 == 0;
      aspectoAnalise = emPe ? q.largura / q.altura : q.altura / q.largura;
      final seq = ++_seq;
      canal.sink.add(montarQuadro(seq: seq, capturadoEm: agora, rotacao: rotacao, jpeg: q.bytes));
      _seqEmTransito = seq;
      // Se a resposta não vier em 1 s, segue com o próximo quadro.
      _timeoutQuadro?.cancel();
      _timeoutQuadro = Timer(const Duration(seconds: 1), () => _seqEmTransito = null);
    } catch (e) {
      ultimoErro = 'Falha ao comprimir o quadro: $e';
    } finally {
      _codificando = false;
    }
  }

  void _aoMensagem(dynamic dados) {
    if (dados is! String) return;
    final r = RespostaIa.deTexto(dados);
    switch (r) {
      case RespostaDeteccoes():
        _liberarTransito(r.seq);
        final agora = DateTime.now().millisecondsSinceEpoch;
        deteccoes = r.deteccoes;
        inferenciaMs = r.inferenciaMs;
        if (r.capturadoEm != null) {
          final l = agora - r.capturadoEm!;
          latenciaMs = latenciaMs == null ? l : latenciaMs! * .7 + l * .3;
        }
        _respostas
          ..add(agora)
          ..removeWhere((t) => agora - t > 2000);
        fps = _respostas.length / 2;
        // Caixas velhas somem se as respostas pararem.
        _vencimento?.cancel();
        _vencimento = Timer(const Duration(milliseconds: 1200), () {
          deteccoes = const [];
          fps = 0;
          _avisar();
        });
      case RespostaDescartado():
        _liberarTransito(r.seq);
      case RespostaErro():
        _liberarTransito(r.seq);
        ultimoErro = '${r.mensagem} (${r.codigo})';
      case RespostaStatus():
        modeloServidor = r.modelo;
        dispositivoServidor = r.dispositivo;
      case null:
        return;
    }
    _avisar();
  }

  void _liberarTransito(int? seq) {
    if (seq != null && seq == _seqEmTransito) {
      _seqEmTransito = null;
      _timeoutQuadro?.cancel();
    }
  }

  Future<void> _desligar() async {
    if (_usuarios > 0 && !_descartado) return;
    await _pararTudo();
    _mudar(IaEstado.desligada);
  }

  Future<void> _pararTudo() async {
    for (final t in [_timeoutQuadro, _reconexao, _vencimento]) {
      t?.cancel();
    }
    await _assinatura?.cancel();
    _assinatura = null;
    await _canal?.sink.close();
    _canal = null;
    _seqEmTransito = null;
    deteccoes = const [];
    fps = 0;
    final c = camera;
    camera = null;
    if (c != null) {
      try {
        if (c.value.isStreamingImages) await c.stopImageStream();
      } catch (_) {}
      await c.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Libera a câmera quando o app vai para segundo plano e retoma ao voltar.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (camera != null) _pararTudo().then((_) => _mudar(IaEstado.desligada));
    } else if (state == AppLifecycleState.resumed && _usuarios > 0) {
      _ligar();
    }
  }

  void _mudar(IaEstado e) {
    estado = e;
    _avisar();
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  /// Abre uma conexão rápida, pede o status e devolve uma frase para o usuário.
  static Future<(bool, String)> testarConexao(IaConfig cfg) async {
    if (!cfg.configurada) return (false, 'Informe o IP do servidor.');
    WebSocketChannel? canal;
    try {
      canal = WebSocketChannel.connect(cfg.urlWs);
      await canal.ready.timeout(const Duration(seconds: 4));
      canal.sink.add(jsonEncode({'tipo': 'status'}));
      final msg = await canal.stream.first.timeout(const Duration(seconds: 4));
      final r = msg is String ? RespostaIa.deTexto(msg) : null;
      if (r is RespostaStatus) return (true, 'Conectado: modelo ${r.modelo} em ${r.dispositivo} (API ${r.versao}).');
      if (r is RespostaErro) return (false, r.mensagem);
      return (false, 'O servidor respondeu algo inesperado.');
    } on TimeoutException {
      return (false, 'Sem resposta de ${cfg.endereco}. Confira o IP, a porta e se o Mac está na mesma rede Wi-Fi.');
    } catch (_) {
      return (false, 'Não consegui conectar em ${cfg.endereco}. A API está rodando (python -m app)?');
    } finally {
      await canal?.sink.close();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _desligamento?.cancel();
    _pararTudo();
    super.dispose();
  }
}

/// Disponibiliza o [IaServico] para a árvore (pode não existir: testes e web antigos).
class IaScope extends InheritedNotifier<IaServico> {
  const IaScope({super.key, required IaServico servico, required super.child}) : super(notifier: servico);

  static IaServico? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<IaScope>()?.notifier;
  static IaServico? read(BuildContext context) => context.getInheritedWidgetOfExactType<IaScope>()?.notifier;
}

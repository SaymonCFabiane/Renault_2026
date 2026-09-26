// Estado da demo em memória, portado de fresh(), advance() e do objeto A do protótipo.
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/mock_data.dart';

enum ToastKind { ok, bad, warn }

class ToastMessage {
  const ToastMessage(this.id, this.kind, this.message);
  final int id;
  final ToastKind kind;
  final String message;
}

enum ModalKind { print, partial, report }

String _clock() {
  final d = DateTime.now();
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class DemoState extends ChangeNotifier {
  DemoState() {
    _fresh();
  }

  // Sessão
  bool dark = false;
  String? profileId;
  Screen screen = Screen.fFunc1;
  bool notesOpen = false;
  ToastMessage? toast;
  ModalKind? modal;
  double printProgress = 0;
  bool reportPhoto = false;
  bool lockShown = false;

  // História
  late String op3310;
  late String mn0457; // Em Conferência → Aguardando Aprovação → Em Trânsito → Recebido
  late int labelQty;
  late bool labelsPrinted;
  late List<ScanRead> loadReads;
  late int loadSeqIdx;
  ScanRead? loadLast;
  late List<ScanRead> recvReads;
  late int recvSeqIdx;
  ScanRead? recvLast;
  late bool recvPhoto;
  late bool recvDamage;
  late Map<String, String> kits;
  late bool k142ready;
  late int routeIdx;
  late bool routeBadTried;
  ScanRead? routeLast;
  late bool shipScanned;
  late String shipCarrier;
  late String shipTime;
  late List<int> accGot;
  late int accSeqIdx;
  ScanRead? accLast;
  late bool accReported;
  late String marcosTab;

  Timer? _toastTimer;
  Timer? _printTimer;
  int _toastId = 0;

  void _fresh() {
    op3310 = 'Pendente';
    mn0457 = 'Em Conferência';
    labelQty = 10;
    labelsPrinted = false;
    loadReads = [
      for (var i = 0; i < 6; i++) ScanRead(code: 'PC-00020${i + 1}', ok: true, time: '16:${21 + i * 2}'),
    ];
    loadSeqIdx = 0;
    loadLast = null;
    recvReads = [];
    recvSeqIdx = 0;
    recvLast = null;
    recvPhoto = false;
    recvDamage = false;
    kits = {'KT-0142': 'Em Separação', 'KT-0139': 'Em Separação', 'KT-0145': 'Aguardando Separação'};
    k142ready = false;
    routeIdx = 0;
    routeBadTried = false;
    routeLast = null;
    shipScanned = false;
    shipCarrier = '';
    shipTime = '';
    accGot = [];
    accSeqIdx = 0;
    accLast = null;
    accReported = false;
    marcosTab = 'Recebimentos';
    modal = null;
    lockShown = false;
  }

  /* ===== Seletores ===== */
  List<String> get loadOk => loadReads.where((r) => r.ok).map((r) => r.code).toList();
  int get recvOkCount => recvReads.where((r) => r.ok).length;
  Profile? get profile => profileId == null ? null : profileById(profileId!);

  void _notify() => notifyListeners();

  /* ===== Toast único (defeito 4) ===== */
  void showToast(ToastKind kind, String message) {
    toast = ToastMessage(++_toastId, kind, message);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 3400), () {
      toast = null;
      _notify();
    });
  }

  /* ===== Navegação e sessão ===== */
  void pickProfile(String id) {
    profileId = id;
    screen = menus[id]!.first.screen;
    notesOpen = false;
    lockShown = false;
    _notify();
  }

  void swapProfile() {
    profileId = null;
    notesOpen = false;
    modal = null;
    lockShown = false;
    _notify();
  }

  void go(Screen s) {
    screen = s;
    notesOpen = false;
    _notify();
  }

  void toggleTheme() {
    dark = !dark;
    _notify();
  }

  void toggleNotes() {
    notesOpen = !notesOpen;
    _notify();
  }

  void closeModal() {
    modal = null;
    _printTimer?.cancel();
    _notify();
  }

  void toastOnly(ToastKind kind, String message) {
    showToast(kind, message);
    _notify();
  }

  /* ===== História: avanços encadeados ===== */
  static const _order = ['opReleased', 'loadDone', 'loadSent', 'shipped', 'received', 'routeDone', 'kitShipped', 'accepted'];

  void advance(String to) {
    final n = _order.indexOf(to);
    if (n >= 0 && op3310 == 'Pendente') op3310 = 'Liberado';
    if (n >= 1 && loadSeqIdx < loadSeq.length) {
      while (loadSeqIdx < loadSeq.length) {
        final r = loadSeq[loadSeqIdx++];
        loadReads.add(r.at('16:3$loadSeqIdx'));
      }
      loadLast = null;
    }
    if (n >= 2 && mn0457 == 'Em Conferência') mn0457 = 'Aguardando Aprovação';
    if (n >= 3 && mn0457 == 'Aguardando Aprovação') mn0457 = 'Em Trânsito';
    if ((n == 4 || to == 'accepted') && mn0457 != 'Recebido') {
      var i = 0;
      recvReads = [for (final r in recvSeq.where((r) => r.ok)) r.at('17:${35 + i++}', sub: 'Guardar em $guardAddress')];
      recvSeqIdx = recvSeq.length;
      mn0457 = 'Recebido';
    }
    if (n >= 5) {
      routeIdx = kit142.length;
      k142ready = true;
    }
    if (n >= 6 && kits['KT-0142'] == 'Em Separação') {
      kits['KT-0142'] = 'Em Trânsito';
      shipScanned = true;
      shipCarrier = shipCarrier.isEmpty ? 'Transporte interno' : shipCarrier;
      shipTime = '18:05';
    }
    if (n >= 7) {
      accGot = [0, 1, 2, 3, 4];
      accSeqIdx = accSeq.length;
      kits['KT-0142'] = 'Entregue Parcial';
    }
  }

  /* ===== Ações (mesmos nomes do objeto A do protótipo) ===== */
  void simRelease() {
    advance('opReleased');
    showToast(ToastKind.ok, 'Carla Mendes liberou a OP-3310.');
    _notify();
  }

  void labelQtyStep(int d) {
    labelQty = (labelQty + d).clamp(4, 10);
    _notify();
  }

  void printLabels() {
    modal = ModalKind.print;
    printProgress = 0;
    _printTimer?.cancel();
    _printTimer = Timer.periodic(const Duration(milliseconds: 220), (t) {
      printProgress = (printProgress + 10).clamp(0, 100);
      if (printProgress >= 100) {
        t.cancel();
        labelsPrinted = true;
      }
      _notify();
    });
    _notify();
  }

  void loadScan() {
    if (loadSeqIdx >= loadSeq.length) return;
    final r = loadSeq[loadSeqIdx++].at(_clock());
    loadReads.add(r);
    loadLast = r;
    _notify();
  }

  void loadSend() {
    mn0457 = 'Aguardando Aprovação';
    showToast(ToastKind.ok, 'Conferência enviada para Carla Mendes aprovar.');
    _notify();
  }

  void setMarcosTab(String t) {
    marcosTab = t;
    _notify();
  }

  void simArrive() {
    advance('shipped');
    showToast(ToastKind.ok, 'MN-0457 chegou na doca 2.');
    _notify();
  }

  void recvScan() {
    if (recvSeqIdx >= recvSeq.length) return;
    final r = recvSeq[recvSeqIdx++].at(_clock(), sub: 'Guardar em $guardAddress');
    recvReads.add(r);
    recvLast = r;
    _notify();
  }

  void takeRecvPhoto() {
    recvPhoto = true;
    _notify();
  }

  void takeReportPhoto() {
    reportPhoto = true;
    _notify();
  }

  void registerDamage() {
    if (!recvPhoto) {
      showToast(ToastKind.warn, 'Tire a foto da peça antes de registrar a avaria.');
    } else {
      recvDamage = true;
      showToast(ToastKind.ok, 'Avaria registrada e enviada para Ricardo Alves.');
    }
    _notify();
  }

  void recvDone() {
    mn0457 = 'Recebido';
    showToast(ToastKind.ok, 'MN-0457 recebida. 1 Farol LED reservado para completar o KT-0142.');
    _notify();
  }

  void routeScan() {
    final it = kit142[routeIdx];
    if (routeIdx == 1 && !routeBadTried) {
      routeBadTried = true;
      routeLast = const ScanRead(code: 'PC-000412', ok: false, msg: 'Peça não pertence a este kit');
    } else {
      routeLast = ScanRead(code: it.code!, ok: true);
      routeIdx++;
      showToast(ToastKind.ok, '${it.name} ×${it.qty} coletado.');
    }
    _notify();
  }

  void routeMiss() {
    modal = ModalKind.partial;
    _notify();
  }

  void partialYes() {
    modal = null;
    routeIdx = kit142.length;
    k142ready = true;
    marcosTab = 'Kits para Despacho';
    showToast(ToastKind.ok, 'KT-0142 pronto para despacho (parcial).');
    _notify();
  }

  void partialNo() {
    modal = null;
    showToast(ToastKind.warn, 'Coleta pausada até o Farol LED esquerdo chegar.');
    _notify();
  }

  void showLock() {
    lockShown = true;
    _notify();
  }

  void unlock() {
    lockShown = false;
    screen = Screen.eFunc1;
    marcosTab = 'Montagem de Kits';
    _notify();
  }

  void shipScan() {
    shipScanned = true;
    shipTime = _clock();
    showToast(ToastKind.ok, 'Caixa CX-KT-0142 confirmada.');
    _notify();
  }

  void setCarrier(String v) {
    shipCarrier = v;
    _notify();
  }

  void shipConfirm() {
    kits['KT-0142'] = 'Em Trânsito';
    showToast(ToastKind.ok, 'KT-0142 expedido para a oficina de protótipos.');
    _notify();
  }

  void simKitArrive() {
    advance('kitShipped');
    showToast(ToastKind.ok, 'KT-0142 chegou na oficina.');
    _notify();
  }

  void accScan() {
    if (accSeqIdx >= accSeq.length) return;
    final r = accSeq[accSeqIdx++];
    final it = kit142[r.index];
    accLast = ScanRead(code: it.code!, ok: r.ok, msg: r.msg);
    if (r.ok && !accGot.contains(r.index)) accGot.add(r.index);
    _notify();
  }

  void openReport() {
    modal = ModalKind.report;
    reportPhoto = false;
    _notify();
  }

  void reportSend() {
    modal = null;
    accReported = true;
    showToast(ToastKind.ok, 'Relato enviado ao Estoque com foto.');
    _notify();
  }

  void accept() {
    kits['KT-0142'] = 'Entregue Parcial';
    showToast(ToastKind.ok, 'KT-0142 aceito. SUV X liberado para montagem.');
    _notify();
  }

  void skipEnd() {
    advance('opReleased');
    labelsPrinted = true;
    advance('loadSent');
    advance('shipped');
    advance('received');
    advance('accepted');
    kits['KT-0145'] = 'Em Separação';
    notesOpen = false;
    showToast(ToastKind.ok, 'Demo no fim da história: KT-0142 entregue parcial.');
    _notify();
  }

  void reset() {
    _printTimer?.cancel();
    _fresh();
    notesOpen = false;
    showToast(ToastKind.ok, 'Demo reiniciada.');
    _notify();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _printTimer?.cancel();
    super.dispose();
  }
}

/// Disponibiliza o [DemoState] para a árvore e reconstrói quem depende dele.
class DemoScope extends InheritedNotifier<DemoState> {
  const DemoScope({super.key, required DemoState state, required super.child}) : super(notifier: state);

  static DemoState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<DemoScope>()!.notifier!;
}

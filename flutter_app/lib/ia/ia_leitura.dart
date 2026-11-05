// Transforma as detecções da API em leituras de peça: a peça precisa ficar na câmera por um tempo,
// com boa confiança, para valer como leitura (evita leituras falsas de um único quadro).
import 'ia_protocolo.dart';

/// Nome da classe do modelo sem acento e em minúsculas, reduzido à peça: "Pinça de freio" → "pinca".
String pecaDaClasse(String classe) {
  const acentos = {'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', 'í': 'i', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c'};
  final n = classe.toLowerCase().split('').map((ch) => acentos[ch] ?? ch).join();
  if (n.contains('engrenagem')) return 'engrenagem';
  if (n.contains('pinca')) return 'pinca';
  return n;
}

class EstabilizadorLeitura {
  EstabilizadorLeitura({this.confiancaMin = .6, this.tempo = const Duration(milliseconds: 900), this.pausa = const Duration(seconds: 3)});

  /// Confiança mínima para contar a detecção.
  final double confiancaMin;

  /// Tempo que a peça precisa ficar visível para virar leitura.
  final Duration tempo;

  /// Intervalo mínimo entre duas leituras da mesma peça (se ela continuar na câmera).
  final Duration pausa;

  final Map<String, DateTime> _desde = {};
  final Map<String, DateTime> _ultima = {};

  /// Recebe as detecções de um quadro; devolve a classe original da peça que acabou de ser lida, se houver.
  String? alimentar(Iterable<DeteccaoIa> deteccoes, DateTime agora) {
    final vistas = <String, String>{
      for (final d in deteccoes)
        if (d.confianca >= confiancaMin) pecaDaClasse(d.classe): d.classe,
    };
    _desde.removeWhere((k, _) => !vistas.containsKey(k));
    for (final MapEntry(key: k, value: classe) in vistas.entries) {
      final inicio = _desde.putIfAbsent(k, () => agora);
      final ultima = _ultima[k];
      if (agora.difference(inicio) >= tempo && (ultima == null || agora.difference(ultima) >= pausa)) {
        _ultima[k] = agora;
        return classe;
      }
    }
    return null;
  }

  void limpar() {
    _desde.clear();
    _ultima.clear();
  }
}

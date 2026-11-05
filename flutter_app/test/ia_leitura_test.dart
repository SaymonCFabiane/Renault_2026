import 'dart:ui';

import 'package:flutter_app/ia/ia_leitura.dart';
import 'package:flutter_app/ia/ia_protocolo.dart';
import 'package:flutter_test/flutter_test.dart';

DeteccaoIa det(String classe, double conf) => DeteccaoIa(classeId: 0, classe: classe, confianca: conf, caixa: const Rect.fromLTRB(.2, .2, .6, .6));

void main() {
  test('pecaDaClasse ignora acento e maiúsculas', () {
    expect(pecaDaClasse('Pinça de freio'), 'pinca');
    expect(pecaDaClasse('Pinça de freio dianteira'), 'pinca');
    expect(pecaDaClasse('ENGRENAGEM'), 'engrenagem');
  });

  test('a peça vira leitura só depois de ~1 s na câmera, e não repete logo em seguida', () {
    final e = EstabilizadorLeitura();
    final t0 = DateTime(2026);
    DateTime t(int ms) => t0.add(Duration(milliseconds: ms));
    expect(e.alimentar([det('Pinça de freio', .9)], t(0)), isNull);
    expect(e.alimentar([det('Pinça de freio', .9)], t(500)), isNull);
    expect(e.alimentar([det('Pinça de freio', .9)], t(950)), 'Pinça de freio');
    expect(e.alimentar([det('Pinça de freio', .9)], t(1500)), isNull); // pausa de 3 s
    expect(e.alimentar([det('Pinça de freio', .9)], t(4000)), 'Pinça de freio');
  });

  test('confiança baixa ou peça que sai da câmera zeram a contagem', () {
    final e = EstabilizadorLeitura();
    final t0 = DateTime(2026);
    DateTime t(int ms) => t0.add(Duration(milliseconds: ms));
    expect(e.alimentar([det('Engrenagem', .3)], t(0)), isNull);
    expect(e.alimentar([det('Engrenagem', .3)], t(2000)), isNull);
    expect(e.alimentar([det('Engrenagem', .8)], t(2100)), isNull);
    expect(e.alimentar(const [], t(2600)), isNull);
    expect(e.alimentar([det('Engrenagem', .8)], t(2700)), isNull);
    expect(e.alimentar([det('Engrenagem', .8)], t(3650)), 'Engrenagem');
  });
}

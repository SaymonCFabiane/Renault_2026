// Dados fictícios fixos da demo, portados do protótipo (docs/referencia/prototipo-tracepro.html).
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.module,
    required this.org,
    required this.icon,
    required this.first,
  });

  final String id, name, initials, role, module, org, first;
  final IconData icon;
}

const profiles = <Profile>[
  Profile(
      id: 'bruno',
      name: 'Bruno Lima',
      initials: 'BL',
      role: 'Operador de Produção',
      module: 'Fornecedor',
      org: 'MetalSul Autopeças',
      icon: LucideIcons.factory,
      first: 'Bruno'),
  Profile(
      id: 'marcos',
      name: 'Marcos Souza',
      initials: 'MS',
      role: 'Operador',
      module: 'Estoque',
      org: 'Montadora · Almoxarifado',
      icon: LucideIcons.warehouse,
      first: 'Marcos'),
  Profile(
      id: 'fernanda',
      name: 'Fernanda Rocha',
      initials: 'FR',
      role: 'Técnica',
      module: 'Testes',
      org: 'Montadora · Oficina de Protótipos',
      icon: LucideIcons.flaskConical,
      first: 'Fernanda'),
];

Profile profileById(String id) => profiles.firstWhere((p) => p.id == id);

/// Telas mobile (códigos do briefing).
enum Screen { fFunc1, fFunc2, fFunc3, eFunc1, eFunc2, eFunc3, eFunc4, tFunc1, tFunc2 }

class MenuItem {
  const MenuItem(this.screen, this.label, this.icon);
  final Screen screen;
  final String label;
  final IconData icon;
}

const menus = <String, List<MenuItem>>{
  'bruno': [
    MenuItem(Screen.fFunc1, 'Lotes', LucideIcons.house),
    MenuItem(Screen.fFunc2, 'Etiquetas', LucideIcons.printer),
    MenuItem(Screen.fFunc3, 'Carregamento', LucideIcons.scanBarcode),
  ],
  'marcos': [
    MenuItem(Screen.eFunc1, 'Tarefas', LucideIcons.inbox),
    MenuItem(Screen.eFunc2, 'Recebimento', LucideIcons.packageCheck),
    MenuItem(Screen.eFunc3, 'Coleta', LucideIcons.route),
    MenuItem(Screen.eFunc4, 'Expedição', LucideIcons.truck),
  ],
  'fernanda': [
    MenuItem(Screen.tFunc1, 'Kits', LucideIcons.house),
    MenuItem(Screen.tFunc2, 'Conferência', LucideIcons.clipboardCheck),
  ],
};

const screenTitles = <Screen, String>{
  Screen.fFunc1: 'Lotes liberados',
  Screen.fFunc2: 'Registro e etiquetas',
  Screen.fFunc3: 'Carregamento',
  Screen.eFunc1: 'Fila de tarefas',
  Screen.eFunc2: 'Conferência de recebimento',
  Screen.eFunc3: 'Coleta do KT-0142',
  Screen.eFunc4: 'Expedição de kit',
  Screen.tFunc1: 'Kits esperados',
  Screen.tFunc2: 'Conferência do kit',
};

/// Tela "de volta" (seta no header) das telas internas.
const screenHome = <Screen, Screen>{
  Screen.fFunc2: Screen.fFunc1,
  Screen.fFunc3: Screen.fFunc1,
  Screen.eFunc2: Screen.eFunc1,
  Screen.eFunc3: Screen.eFunc1,
  Screen.eFunc4: Screen.eFunc1,
  Screen.tFunc2: Screen.tFunc1,
};

const protoSuv = 'SUV X – Teste de Pista';
const protoPickup = 'Pickup Pro – Teste de Frenagem';
const protoHatch = 'Hatch E-Tech – Teste de Durabilidade';

class KitPart {
  const KitPart({required this.name, required this.qty, required this.blocking, this.address, this.aisle, this.shelf, this.code, this.missing = false});
  final String name;
  final int qty;
  final bool blocking;
  final String? address, aisle, code;
  final int? shelf;
  final bool missing;
}

const kit142 = <KitPart>[
  KitPart(
      name: 'Pinça de freio dianteira',
      qty: 2,
      blocking: true,
      address: 'Corredor A · Prateleira 02 · Nível 1 · Caixa 04',
      aisle: 'A',
      shelf: 2,
      code: 'PC-000098'),
  KitPart(
      name: 'Suporte do motor', qty: 2, blocking: true, address: 'Corredor B · Prateleira 04 · Nível 2 · Caixa 01', aisle: 'B', shelf: 4, code: 'PC-000121'),
  KitPart(
      name: 'Chicote elétrico do painel',
      qty: 1,
      blocking: true,
      address: 'Corredor B · Prateleira 07 · Nível 1 · Caixa 02',
      aisle: 'B',
      shelf: 7,
      code: 'PC-000133'),
  KitPart(name: 'Módulo de ECU', qty: 1, blocking: true, address: 'Corredor C · Prateleira 01 · Nível 3 · Caixa 05', aisle: 'C', shelf: 1, code: 'PC-000150'),
  KitPart(
      name: 'Amortecedor traseiro',
      qty: 2,
      blocking: false,
      address: 'Corredor D · Prateleira 03 · Nível 1 · Caixa 02',
      aisle: 'D',
      shelf: 3,
      code: 'PC-000164'),
  KitPart(name: 'Farol LED esquerdo', qty: 1, blocking: false, missing: true),
];

/// Kits exibidos no app: protótipo, prioridade e nº de itens.
const kitProto = {'KT-0142': protoSuv, 'KT-0139': protoPickup, 'KT-0145': protoHatch};
const kitPrio = {'KT-0142': 'Alta', 'KT-0139': 'Alta', 'KT-0145': 'Média'};
const kitItemCount = {'KT-0142': 6, 'KT-0139': 3, 'KT-0145': 3};

/// Notificação: [ícone, tom, texto, quando].
class Note {
  const Note(this.icon, this.tone, this.text, this.when);
  final IconData icon;
  final String tone, text, when;
}

const notes = <String, List<Note>>{
  'bruno': [
    Note(LucideIcons.clipboardList, 'data', 'OP-3310 aguardando liberação de Carla Mendes.', '25/09 · 08:00'),
    Note(LucideIcons.truck, 'data', 'Carga MN-0457: carregamento às 16:00.', '25/09 · 07:30'),
    Note(LucideIcons.triangleAlert, 'accent', 'MN-0451 voltou com 1 peça avariada.', '22/09 · 15:10'),
  ],
  'marcos': [
    Note(LucideIcons.package, 'data', 'MN-0457 chega na doca 2 às 17:30.', '25/09 · 16:50'),
    Note(LucideIcons.route, 'data', 'Nova coleta atribuída: KT-0142 (prioridade Alta).', '25/09 · 09:00'),
    Note(LucideIcons.lock, 'danger', 'KT-0139 travado até chegar a Pinça de freio traseira.', '25/09 · 09:41'),
  ],
  'fernanda': [
    Note(LucideIcons.truck, 'data', 'KT-0142 em separação no Estoque.', '25/09 · 09:00'),
    Note(LucideIcons.circleAlert, 'warning', 'KT-0142 virá sem o Farol LED esquerdo (autorizado).', '24/09 · 10:40'),
    Note(LucideIcons.circleCheck, 'success', 'Hatch E-Tech liberado para o Teste de Durabilidade.', '25/09 · 08:15'),
  ],
};

/// Uma leitura do leitor de QR (simulada).
class ScanRead {
  const ScanRead({required this.code, required this.ok, this.msg, this.time = '', this.sub});
  final String code;
  final bool ok;
  final String? msg, sub;
  final String time;

  ScanRead at(String t, {String? sub}) => ScanRead(code: code, ok: ok, msg: msg, time: t, sub: sub ?? this.sub);
}

/// Carregamento MN-0457 (Bruno): 6 lidas + esta sequência → 8/10 com 1 repetida.
const loadSeq = <ScanRead>[
  ScanRead(code: 'PC-000207', ok: true),
  ScanRead(code: 'PC-000207', ok: false, msg: 'Peça repetida'),
  ScanRead(code: 'PC-000208', ok: true),
];

/// Recebimento MN-0457 (Marcos). Defeito 1 corrigido: gera as 8 leituras válidas
/// (PC-000201 a PC-000208) com 1 leitura inválida no meio.
const recvSeq = <ScanRead>[
  ScanRead(code: 'PC-000201', ok: true),
  ScanRead(code: 'PC-000202', ok: true),
  ScanRead(code: 'PC-000203', ok: true),
  ScanRead(code: 'PC-000204', ok: true),
  ScanRead(code: 'PC-000315', ok: false, msg: 'Peça não pertence a esta carga'),
  ScanRead(code: 'PC-000205', ok: true),
  ScanRead(code: 'PC-000206', ok: true),
  ScanRead(code: 'PC-000207', ok: true),
  ScanRead(code: 'PC-000208', ok: true),
];

/// Conferência do KT-0142 (Fernanda): índice da peça em [kit142].
class AccRead {
  const AccRead(this.index, this.ok, [this.msg]);
  final int index;
  final bool ok;
  final String? msg;
}

const accSeq = <AccRead>[AccRead(0, true), AccRead(1, true), AccRead(1, false, 'Peça repetida'), AccRead(2, true), AccRead(3, true), AccRead(4, true)];

const guardAddress = 'Corredor D · Prateleira 05 · Nível 2 · Caixa 03';

/// Quem leva o kit até a oficina: [nome, detalhe].
const carriers = [
  ['Fernanda Rocha', 'Testes · retira no balcão'],
  ['Transporte interno', 'Carrinho elétrico 03'],
  ['Marcos Souza', 'Eu mesmo levo até a oficina'],
];

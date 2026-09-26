import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/mock_data.dart';
import '../theme/tokens.dart';

/// Tela vermelha de coleta travada (peça BLOCANTE em falta).
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC0392B);
    const white = Colors.white;
    return Material(
      color: red,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 120),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: Color(0x26FFFFFF), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.lock, size: 48, color: white)),
              const SizedBox(height: 14),
              Semantics(
                  header: true,
                  child: const Text('Coleta travada', style: TextStyle(color: white, fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w800))),
              const SizedBox(height: 6),
              const Text('Estoque ADM notificado', style: TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(TpRadius.radiusCard)),
                child: const Text.rich(
                  TextSpan(style: TextStyle(color: white, fontSize: 16, height: 1.45), children: [
                    TextSpan(text: 'KT-0139', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: ' · $protoPickup\nFalta '),
                    TextSpan(text: 'Pinça de freio traseira', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: ' (BLOCANTE). Sem ela o teste não acontece.\n'),
                    TextSpan(text: 'Ricardo Alves recebeu o alerta às 09:41. Reposição: OP-3308.', style: TextStyle(fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: white,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                        height: 52, child: Center(child: Text('Voltar para a fila', style: TextStyle(color: red, fontWeight: FontWeight.w700, fontSize: 16)))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

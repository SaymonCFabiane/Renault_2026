import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/tokens.dart';

const bottomNavHeight = 64.0;

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.items, required this.current, required this.onTap});
  final List<MenuItem> items;
  final Screen current;
  final ValueChanged<Screen> onTap;

  @override
  Widget build(BuildContext context) {
    final c = TpColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
      padding: EdgeInsets.fromLTRB(8, 4, 8, bottom > 0 ? bottom : 4),
      child: SizedBox(
        height: bottomNavHeight - 8,
        child: Row(children: [
          for (final it in items)
            Expanded(
              child: Semantics(
                selected: it.screen == current,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
                  onTap: () => onTap(it.screen),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 52,
                      height: 28,
                      decoration: BoxDecoration(
                          color: it.screen == current ? c.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(TpRadius.radiusPill)),
                      child: Icon(it.icon, size: 22, color: it.screen == current ? c.primary : c.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(it.label,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: it.screen == current ? c.primary : c.textSecondary)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

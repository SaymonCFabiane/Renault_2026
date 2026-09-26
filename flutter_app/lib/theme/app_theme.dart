import 'package:flutter/material.dart';

import 'tokens.dart';

/// Temas Material 3 claro e escuro montados sobre os tokens do TracePro.
abstract final class AppTheme {
  static ThemeData light() => _build(TpColors.light, Brightness.light);
  static ThemeData dark() => _build(TpColors.dark, Brightness.dark);

  static ThemeData _build(TpColors c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.text,
      secondary: c.accentText,
      onSecondary: c.onStatus,
      error: c.danger,
      onError: c.onStatus,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.line,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Nunito', brightness: b);
    return base.copyWith(
      scaffoldBackgroundColor: c.contentBg,
      extensions: [c],
      textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text, fontFamily: 'Nunito'),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(fontFamily: 'Nunito', color: c.surface, fontWeight: FontWeight.w600),
        decoration: BoxDecoration(color: c.text, borderRadius: BorderRadius.circular(TpRadius.radiusIcon)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        hintStyle: TextStyle(color: c.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(TpRadius.radiusIcon), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TpRadius.radiusIcon),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Estilos de texto do app mobile (grupo "Mobile" dos tokens).
abstract final class TpText {
  static const title = TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w800);
  static const step = TextStyle(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w800);
  static const body = TextStyle(fontSize: 16, height: 24 / 16);
  static const count = TextStyle(fontSize: 56, height: 60 / 56, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]);
  static const h3 = TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600);
  static const cardTitle = TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w800);
  static const caption = TextStyle(fontSize: 12, height: 16 / 12);
  static const label = TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, letterSpacing: .24);
  static const tag = TextStyle(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w800, letterSpacing: .44);
}

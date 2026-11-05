// Gerado a partir de docs/referencia/design-tokens.json (paleta Renault Geely do Brasil, tema claro e escuro).
import 'package:flutter/material.dart';

/// Cores semânticas do TracePro, disponíveis em `TpColors.of(context)`.
@immutable
class TpColors extends ThemeExtension<TpColors> {
  const TpColors({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.sidebar,
    required this.sidebarFim,
    required this.contentBg,
    required this.surface,
    required this.surfaceMuted,
    required this.text,
    required this.textSecondary,
    required this.line,
    required this.data,
    required this.dataLight,
    required this.dataAlt,
    required this.accent,
    required this.accentText,
    required this.accentBg,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningText,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.onStatus,
  });

  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color sidebar;
  final Color sidebarFim;
  final Color contentBg;
  final Color surface;
  final Color surfaceMuted;
  final Color text;
  final Color textSecondary;
  final Color line;
  final Color data;
  final Color dataLight;
  final Color dataAlt;
  final Color accent;
  final Color accentText;
  final Color accentBg;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningText;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color onStatus;

  static const light = TpColors(
    primary: Color(0xFF4713A4),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE0D9EC),
    sidebar: Color(0xFF2307AF),
    sidebarFim: Color(0xFF4713A4),
    contentBg: Color(0xFFE7E7E7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE0D9EC),
    text: Color(0xFF160B3D),
    textSecondary: Color(0xFF5B4E7A),
    line: Color(0xFFE0D9EC),
    data: Color(0xFF4B9AF6),
    dataLight: Color(0xFF66D8D0),
    dataAlt: Color(0xFF8467AD),
    accent: Color(0xFF66D8D0),
    accentText: Color(0xFF0B7A72),
    accentBg: Color(0xFFDDF5F3),
    success: Color(0xFF2F7A5B),
    successBg: Color(0xFFE3F5EE),
    warning: Color(0xFFE0A526),
    warningText: Color(0xFF7A5200),
    warningBg: Color(0xFFFFF4D6),
    danger: Color(0xFFC0392B),
    dangerBg: Color(0xFFFBE4E1),
    onStatus: Color(0xFFFFFFFF),
  );

  static const dark = TpColors(
    primary: Color(0xFFE0D9EC),
    onPrimary: Color(0xFF160B3D),
    primarySoft: Color(0xFF3A2580),
    sidebar: Color(0xFF2307AF),
    sidebarFim: Color(0xFF160B3D),
    contentBg: Color(0xFF160B3D),
    surface: Color(0xFF21114F),
    surfaceMuted: Color(0xFF2E1B6B),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC4B9DE),
    line: Color(0xFF36236F),
    data: Color(0xFF4B9AF6),
    dataLight: Color(0xFF66D8D0),
    dataAlt: Color(0xFF8467AD),
    accent: Color(0xFF66D8D0),
    accentText: Color(0xFF66D8D0),
    accentBg: Color(0xFF0F3A45),
    success: Color(0xFF5CC096),
    successBg: Color(0xFF15302A),
    warning: Color(0xFFE0A526),
    warningText: Color(0xFFF0C35A),
    warningBg: Color(0xFF3A2E10),
    danger: Color(0xFFEF6B5D),
    dangerBg: Color(0xFF3D1A16),
    onStatus: Color(0xFF160B3D),
  );

  static TpColors of(BuildContext context) => Theme.of(context).extension<TpColors>()!;

  /// Degradê da marca (menu lateral / cabeçalho): sidebar → sidebar-fim.
  LinearGradient get degradeMarca => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [sidebar, sidebarFim]);

  @override
  TpColors copyWith(
      {Color? primary,
      Color? onPrimary,
      Color? primarySoft,
      Color? sidebar,
      Color? sidebarFim,
      Color? contentBg,
      Color? surface,
      Color? surfaceMuted,
      Color? text,
      Color? textSecondary,
      Color? line,
      Color? data,
      Color? dataLight,
      Color? dataAlt,
      Color? accent,
      Color? accentText,
      Color? accentBg,
      Color? success,
      Color? successBg,
      Color? warning,
      Color? warningText,
      Color? warningBg,
      Color? danger,
      Color? dangerBg,
      Color? onStatus}) {
    return TpColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      sidebar: sidebar ?? this.sidebar,
      sidebarFim: sidebarFim ?? this.sidebarFim,
      contentBg: contentBg ?? this.contentBg,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      line: line ?? this.line,
      data: data ?? this.data,
      dataLight: dataLight ?? this.dataLight,
      dataAlt: dataAlt ?? this.dataAlt,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentBg: accentBg ?? this.accentBg,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      warningBg: warningBg ?? this.warningBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      onStatus: onStatus ?? this.onStatus,
    );
  }

  @override
  TpColors lerp(TpColors? other, double t) {
    if (other == null) return this;
    return TpColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarFim: Color.lerp(sidebarFim, other.sidebarFim, t)!,
      contentBg: Color.lerp(contentBg, other.contentBg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      line: Color.lerp(line, other.line, t)!,
      data: Color.lerp(data, other.data, t)!,
      dataLight: Color.lerp(dataLight, other.dataLight, t)!,
      dataAlt: Color.lerp(dataAlt, other.dataAlt, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentBg: Color.lerp(accentBg, other.accentBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
    );
  }
}

/// Paleta institucional (para ilustrações e fundos que não mudam com o tema).
abstract final class TpMarca {
  static const roxo = Color(0xFF4713A4);
  static const azulVioleta = Color(0xFF2307AF);
  static const lilas = Color(0xFF8467AD);
  static const noite = Color(0xFF160B3D);
  static const turquesa = Color(0xFF66D8D0);
  static const azul = Color(0xFF4B9AF6);
  static const lavanda = Color(0xFFE0D9EC);
  static const cinza = Color(0xFFE7E7E7);
}

/// Espaçamento (base de 4px).
abstract final class TpSpace {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double gridGutter = 20;
  static const double gridMargin = 30;
}

/// Raios.
abstract final class TpRadius {
  static const double radiusIcon = 8;
  static const double radiusCard = 12;
  static const double radiusPill = 999;
}

/// Medidas de layout e toque.
abstract final class TpSize {
  static const double touchMin = 48;
  static const double sidebarWidth = 240;
  static const double controlHeight = 40;
  static const double bigButton = 52;
}

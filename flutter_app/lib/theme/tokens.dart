// Gerado a partir de docs/referencia/design-tokens.json (tema claro e escuro).
import 'package:flutter/material.dart';

/// Cores semânticas do TracePro, disponíveis em `TpColors.of(context)`.
@immutable
class TpColors extends ThemeExtension<TpColors> {
  const TpColors({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.sidebar,
    required this.contentBg,
    required this.surface,
    required this.surfaceMuted,
    required this.text,
    required this.textSecondary,
    required this.line,
    required this.data,
    required this.dataLight,
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
  final Color contentBg;
  final Color surface;
  final Color surfaceMuted;
  final Color text;
  final Color textSecondary;
  final Color line;
  final Color data;
  final Color dataLight;
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
    primary: Color(0xFF265267),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFBCD2DD),
    sidebar: Color(0xFF265267),
    contentBg: Color(0xFFC8E1ED),
    surface: Color(0xFFF6FAFD),
    surfaceMuted: Color(0xFFD4E0E7),
    text: Color(0xFF1E2F38),
    textSecondary: Color(0xFF5B6B75),
    line: Color(0xFFD4E0E7),
    data: Color(0xFF547C90),
    dataLight: Color(0xFFB7CCD6),
    accent: Color(0xFFC2703D),
    accentText: Color(0xFF9E5528),
    accentBg: Color(0xFFF5DED1),
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
    primary: Color(0xFF8DBBD0),
    onPrimary: Color(0xFF10222B),
    primarySoft: Color(0xFF2C4F60),
    sidebar: Color(0xFF2E6078),
    contentBg: Color(0xFF193A4A),
    surface: Color(0xFF121212),
    surfaceMuted: Color(0xFF2A3E48),
    text: Color(0xFFEEF3F6),
    textSecondary: Color(0xFFA9BAC3),
    line: Color(0xFF2F4450),
    data: Color(0xFF6E97AB),
    dataLight: Color(0xFFB7CCD6),
    accent: Color(0xFFD98A57),
    accentText: Color(0xFFE9A277),
    accentBg: Color(0xFF3A2518),
    success: Color(0xFF5CC096),
    successBg: Color(0xFF15302A),
    warning: Color(0xFFE0A526),
    warningText: Color(0xFFF0C35A),
    warningBg: Color(0xFF3A2E10),
    danger: Color(0xFFEF6B5D),
    dangerBg: Color(0xFF3D1A16),
    onStatus: Color(0xFF121212),
  );

  static TpColors of(BuildContext context) => Theme.of(context).extension<TpColors>()!;

  @override
  TpColors copyWith(
      {Color? primary,
      Color? onPrimary,
      Color? primarySoft,
      Color? sidebar,
      Color? contentBg,
      Color? surface,
      Color? surfaceMuted,
      Color? text,
      Color? textSecondary,
      Color? line,
      Color? data,
      Color? dataLight,
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
      contentBg: contentBg ?? this.contentBg,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      line: line ?? this.line,
      data: data ?? this.data,
      dataLight: dataLight ?? this.dataLight,
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
      contentBg: Color.lerp(contentBg, other.contentBg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      line: Color.lerp(line, other.line, t)!,
      data: Color.lerp(data, other.data, t)!,
      dataLight: Color.lerp(dataLight, other.dataLight, t)!,
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

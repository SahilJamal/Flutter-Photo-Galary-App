import 'package:flutter/material.dart';

/// Semantic colour tokens for the app, exposed as a [ThemeExtension] so every
/// widget reads the same palette in light and dark mode.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.danger,
    required this.dangerSoft,
    required this.favorite,
    required this.skeleton,
    required this.scrim,
    required this.shadow,
  });

  /// Page background: a warm, neutral off-white (light) or near-black (dark).
  final Color background;

  /// Cards, sheets and grouped lists.
  final Color surface;

  /// Inputs, chips, placeholders.
  final Color surfaceMuted;

  /// Floating chrome (nav bar, toolbars).
  final Color surfaceElevated;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;

  /// The single accent. Used sparingly: selection, links, active filters.
  final Color accent;
  final Color accentSoft;
  final Color onAccent;

  final Color danger;
  final Color dangerSoft;
  final Color favorite;
  final Color skeleton;
  final Color scrim;
  final Color shadow;

  static const light = AppColors(
    background: Color(0xFFF7F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFEDE9),
    surfaceElevated: Color(0xF2FFFFFF),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF66666B),
    textTertiary: Color(0xFF9A999E),
    divider: Color(0xFFE5E3DE),
    accent: Color(0xFF2F62D9),
    accentSoft: Color(0xFFE4EBFB),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFD1453B),
    dangerSoft: Color(0xFFFBE7E5),
    favorite: Color(0xFFE5484D),
    skeleton: Color(0xFFE9E7E2),
    scrim: Color(0x66000000),
    shadow: Color(0x14000000),
  );

  static const dark = AppColors(
    background: Color(0xFF0E0E10),
    surface: Color(0xFF18181B),
    surfaceMuted: Color(0xFF232327),
    surfaceElevated: Color(0xF21B1B1F),
    textPrimary: Color(0xFFF2F2EF),
    textSecondary: Color(0xFFA3A3A8),
    textTertiary: Color(0xFF6E6E74),
    divider: Color(0xFF2A2A2F),
    accent: Color(0xFF85A6FF),
    accentSoft: Color(0xFF1E2A47),
    onAccent: Color(0xFF0E1530),
    danger: Color(0xFFFF6B60),
    dangerSoft: Color(0xFF3A1D1B),
    favorite: Color(0xFFFF6369),
    skeleton: Color(0xFF1F1F23),
    scrim: Color(0x99000000),
    shadow: Color(0x66000000),
  );

  @override
  AppColors copyWith({Color? accent}) => AppColors(
    background: background,
    surface: surface,
    surfaceMuted: surfaceMuted,
    surfaceElevated: surfaceElevated,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    divider: divider,
    accent: accent ?? this.accent,
    accentSoft: accentSoft,
    onAccent: onAccent,
    danger: danger,
    dangerSoft: dangerSoft,
    favorite: favorite,
    skeleton: skeleton,
    scrim: scrim,
    shadow: shadow,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      divider: l(divider, other.divider),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      favorite: l(favorite, other.favorite),
      skeleton: l(skeleton, other.skeleton),
      scrim: l(scrim, other.scrim),
      shadow: l(shadow, other.shadow),
    );
  }
}

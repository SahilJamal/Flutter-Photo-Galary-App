import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static TextTheme _text(AppColors c) {
    TextStyle s(
      double size,
      FontWeight w, {
      double ls = 0,
      double h = 1.3,
      Color? color,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: w,
      letterSpacing: ls,
      height: h,
      color: color ?? c.textPrimary,
    );
    return TextTheme(
      displaySmall: s(30, FontWeight.w700, ls: -0.8, h: 1.15),
      headlineMedium: s(26, FontWeight.w700, ls: -0.6, h: 1.2),
      headlineSmall: s(22, FontWeight.w600, ls: -0.4, h: 1.25),
      titleLarge: s(18, FontWeight.w600, ls: -0.25),
      titleMedium: s(16, FontWeight.w600, ls: -0.15),
      titleSmall: s(14, FontWeight.w600, ls: -0.1),
      bodyLarge: s(16, FontWeight.w400, ls: -0.1, h: 1.45),
      bodyMedium: s(15, FontWeight.w400, ls: -0.1, h: 1.45),
      bodySmall: s(13, FontWeight.w400, h: 1.4, color: c.textSecondary),
      labelLarge: s(15, FontWeight.w600, ls: -0.1),
      labelMedium: s(13, FontWeight.w500),
      labelSmall: s(11, FontWeight.w600, ls: 0.2),
    );
  }

  static ThemeData _build(AppColors c, Brightness b) {
    final isDark = b == Brightness.dark;
    final text = _text(c);
    final scheme = ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accent,
      secondary: c.textPrimary,
      onSecondary: c.background,
      error: c.danger,
      onError: Colors.white,
      surface: c.background,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.divider,
      outlineVariant: c.divider,
      shadow: c.shadow,
      scrim: c.scrim,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
    );

    final overlay = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.divider,
      splashFactory: InkRipple.splashFactory,
      splashColor: c.textPrimary.withValues(alpha: 0.06),
      highlightColor: c.textPrimary.withValues(alpha: 0.04),
      hoverColor: c.textPrimary.withValues(alpha: 0.04),
      extensions: [c],
      iconTheme: IconThemeData(color: c.textPrimary, size: IconSizes.md),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium,
        systemOverlayStyle: overlay.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: 0.6,
        space: 0.6,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.textTertiary.withValues(alpha: 0.5),
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        ),
        modalBarrierColor: c.scrim,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? c.surfaceMuted : c.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? c.textPrimary : c.background,
        ),
        actionTextColor: c.accent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.25),
        selectionHandleColor: c.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.textSecondary,
        linearTrackColor: c.surfaceMuted,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: text.labelMedium?.copyWith(color: c.background),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          c.textTertiary.withValues(alpha: 0.6),
        ),
        radius: const Radius.circular(Radii.pill),
        thickness: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.dragged) ? 8 : 4,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension ThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

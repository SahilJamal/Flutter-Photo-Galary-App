import 'package:flutter/services.dart';

/// Haptics reserved for meaningful moments, so they stay meaningful.
abstract final class Haptics {
  /// Tab changes, toggling a selection.
  static void tick() => HapticFeedback.selectionClick();

  /// Favouriting, confirming a small action.
  static void light() => HapticFeedback.lightImpact();

  /// Entering selection mode, destructive confirmation.
  static void medium() => HapticFeedback.mediumImpact();
}

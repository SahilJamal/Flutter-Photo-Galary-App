import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers.dart';

/// Tile size in the grid; maps to a target cell width.
enum ThumbSize {
  small('Small', 92),
  medium('Medium', 124),
  large('Large', 172);

  const ThumbSize(this.label, this.targetWidth);
  final String label;
  final double targetWidth;
}

/// Spacing and rounding between tiles.
enum GridDensity {
  compact('Compact', 2, 4),
  comfortable('Comfortable', 4, 10);

  const GridDensity(this.label, this.gap, this.radius);
  final String label;
  final double gap;
  final double radius;
}

enum DateGrouping {
  none('None'),
  day('Day'),
  month('Month'),
  year('Year');

  const DateGrouping(this.label);
  final String label;
}

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.thumbSize,
    required this.density,
    required this.grouping,
    required this.onboardingDone,
  });

  final ThemeMode themeMode;
  final ThumbSize thumbSize;
  final GridDensity density;
  final DateGrouping grouping;
  final bool onboardingDone;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ThumbSize? thumbSize,
    GridDensity? density,
    DateGrouping? grouping,
    bool? onboardingDone,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    thumbSize: thumbSize ?? this.thumbSize,
    density: density ?? this.density,
    grouping: grouping ?? this.grouping,
    onboardingDone: onboardingDone ?? this.onboardingDone,
  );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = ref.watch(preferencesProvider);
    T pick<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      themeMode: pick(ThemeMode.values, p.themeMode, ThemeMode.system),
      thumbSize: pick(ThumbSize.values, p.thumbSize, ThumbSize.medium),
      density: pick(GridDensity.values, p.density, GridDensity.compact),
      grouping: pick(DateGrouping.values, p.grouping, DateGrouping.month),
      onboardingDone: p.onboardingDone,
    );
  }

  void setThemeMode(ThemeMode v) {
    ref.read(preferencesProvider).themeMode = v.name;
    state = state.copyWith(themeMode: v);
  }

  void setThumbSize(ThumbSize v) {
    ref.read(preferencesProvider).thumbSize = v.name;
    state = state.copyWith(thumbSize: v);
  }

  void setDensity(GridDensity v) {
    ref.read(preferencesProvider).density = v.name;
    state = state.copyWith(density: v);
  }

  void setGrouping(DateGrouping v) {
    ref.read(preferencesProvider).grouping = v.name;
    state = state.copyWith(grouping: v);
  }

  void completeOnboarding() {
    ref.read(preferencesProvider).onboardingDone = true;
    state = state.copyWith(onboardingDone: true);
  }
}

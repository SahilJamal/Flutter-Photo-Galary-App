import 'package:flutter/widgets.dart';

/// Spacing scale. Everything in the app snaps to these values.
abstract final class Insets {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal gutter for screen-level content.
  static const double screen = 20;
}

/// Corner radii.
abstract final class Radii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double xxl = 28;
  static const double pill = 999;
}

/// Motion: short, calm, consistent.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration hero = Duration(milliseconds: 300);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// Icon sizes.
abstract final class IconSizes {
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 26;
}

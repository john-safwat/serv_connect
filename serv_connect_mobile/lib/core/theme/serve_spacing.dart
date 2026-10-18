/// Spacing, radius, and accessibility hit-target tokens (`CLAUDE.md §21`).
abstract final class ServeSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusButton = 14;
  static const double radiusCard = 18;
  static const double radiusPill = 999;

  /// WCAG 2.1 AA minimum interactive touch target (`CLAUDE.md §21`).
  static const double minHitTarget = 48;
}

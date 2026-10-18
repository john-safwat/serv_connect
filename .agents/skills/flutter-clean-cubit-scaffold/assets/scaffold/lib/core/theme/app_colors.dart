import 'package:flutter/material.dart';

/// The single source of truth for colour. Never hard-code a `Color` in a
/// widget — add it here and reference `AppColors.x`. Keep contrast at WCAG AA.
abstract final class AppColors {
  static const Color primary = Color(0xFF1E6F5C);
  static const Color primaryDark = Color(0xFF14513F);
  static const Color accent = Color(0xFFF2A03D);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6F767E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE6E8EC);
  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED8B00);
}

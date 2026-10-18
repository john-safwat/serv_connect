import 'package:flutter/material.dart';
import 'package:__PKG__/core/theme/app_colors.dart';

/// Typography scale. Never hard-code a `fontSize` in a widget — reference
/// `Theme.of(context).textTheme.*`. Swap [_fontFamily] for a bundled font
/// (declare it in `pubspec.yaml` first); `null` uses the platform default.
abstract final class AppTypography {
  static const String? _fontFamily = null;

  static TextTheme textTheme() => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textOnPrimary,
    ),
  );
}

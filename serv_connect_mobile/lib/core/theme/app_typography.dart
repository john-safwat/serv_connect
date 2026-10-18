import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';

/// Locale-aware editorial typography (`designs/main.main.svg`, Decision 1).
///
/// Uses `Fraunces` (serif display) + `Inter` (UI sans) for English (`en`), and
/// `Amiri` (serif display) + `Cairo` (UI sans) for Arabic (`ar`).
abstract final class AppTypography {
  static const String enDisplayFamily = 'Fraunces';
  static const String enSansFamily = 'Inter';
  static const String arDisplayFamily = 'Amiri';
  static const String arSansFamily = 'Cairo';

  static String displayFamilyFor(String languageCode) =>
      languageCode == 'ar' ? arDisplayFamily : enDisplayFamily;

  static String sansFamilyFor(String languageCode) =>
      languageCode == 'ar' ? arSansFamily : enSansFamily;

  static TextTheme textTheme({String languageCode = 'en'}) {
    final display = displayFamilyFor(languageCode);
    final sans = sansFamilyFor(languageCode);
    return TextTheme(
      displayLarge: _style(display, 32, FontWeight.w700, AppColors.ink, 1.2),
      displayMedium: _style(display, 26, FontWeight.w700, AppColors.ink, 1.25),
      displaySmall: _style(display, 22, FontWeight.w600, AppColors.ink, 1.3),
      headlineMedium: _style(display, 20, FontWeight.w600, AppColors.ink, 1.3),
      headlineSmall: _style(display, 18, FontWeight.w600, AppColors.ink, 1.35),
      titleLarge: _style(sans, 17, FontWeight.w600, AppColors.ink, 1.35),
      titleMedium: _style(sans, 15, FontWeight.w600, AppColors.ink, 1.4),
      titleSmall: _style(sans, 13, FontWeight.w600, AppColors.ink2, 1.4),
      bodyLarge: _style(sans, 15, FontWeight.w400, AppColors.ink, 1.5),
      bodyMedium: _style(sans, 14, FontWeight.w400, AppColors.ink2, 1.45),
      bodySmall: _style(sans, 12, FontWeight.w400, AppColors.muted, 1.4),
      labelLarge: _style(sans, 14, FontWeight.w600, AppColors.ink, 1.2),
      labelMedium: _style(sans, 12, FontWeight.w600, AppColors.ink2, 1.2),
      labelSmall: _style(sans, 11, FontWeight.w500, AppColors.muted, 1.2),
    );
  }

  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    Color color,
    double height,
  ) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}

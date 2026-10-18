import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/app_typography.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Builds the warm editorial [ThemeData] for ServeConnect (`designs/main.main.svg`).
abstract final class AppTheme {
  static ThemeData light({String languageCode = 'en'}) {
    final textTheme = AppTypography.textTheme(languageCode: languageCode);
    final colorScheme = _buildColorScheme();
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.cream,
      dividerColor: AppColors.line,
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(textTheme),
      cardTheme: _buildCardTheme(),
    );
  }

  static ColorScheme _buildColorScheme() {
    return const ColorScheme.light(
      primary: AppColors.red,
      primaryContainer: AppColors.redSoft,
      onPrimaryContainer: AppColors.oxblood,
      secondary: AppColors.gold,
      onSecondary: AppColors.ivory,
      secondaryContainer: AppColors.goldSoft,
      onSecondaryContainer: AppColors.goldDark,
      onSurface: AppColors.ink,
      error: AppColors.red,
      outline: AppColors.line2,
      outlineVariant: AppColors.line,
    );
  }

  static AppBarTheme _buildAppBarTheme(TextTheme textTheme) {
    return AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: AppColors.ivory,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ServeSpacing.radiusCard),
        side: const BorderSide(color: AppColors.line),
      ),
    );
  }
}

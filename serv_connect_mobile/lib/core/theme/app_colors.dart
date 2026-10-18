import 'package:flutter/material.dart';

/// Warm editorial design-system color tokens from `designs/main.main.svg`
/// (`CLAUDE.md §21`, Decision 1).
///
/// Never hard-code `Color(0xFF...)` in feature widgets — always reference
/// [AppColors].
abstract final class AppColors {
  // Typography & Ink tones
  static const Color ink = Color(0xFF1E1913);
  static const Color ink2 = Color(0xFF4A4139);
  static const Color muted = Color(0xFF8C8173);

  // Warm Surfaces & Backgrounds
  static const Color cream = Color(0xFFF4EDE0);
  static const Color paper = Color(0xFFFBF6EC);
  static const Color ivory = Color(0xFFFFFFFF);

  // Hairlines & Borders
  static const Color line = Color(0xFFE7DDC9);
  static const Color line2 = Color(0xFFDBCFB5);
  static const Color segmentedTrack = Color(0xFFEAE1CF);

  // Primary Coptic / Liturgical Crimson & Oxblood
  static const Color red = Color(0xFFC0182A);
  static const Color oxblood = Color(0xFF8C1420);
  static const Color redSoft = Color(0xFFF6E5E1);

  // Warm Gold Accents
  static const Color gold = Color(0xFFB0862F);
  static const Color gold2 = Color(0xFFC6A15B);
  static const Color goldDark = Color(0xFF9C7C34);
  static const Color goldSoft = Color(0xFFEFE2C4);

  // Semantic Status Tokens
  static const Color green = Color(0xFF3B7A54);
  static const Color greenSoft = Color(0xFFE6F0E7);

  static const Color amber = Color(0xFFB07C13);
  static const Color amberSoft = Color(0xFFF5E9CD);

  static const Color blue = Color(0xFF34568C);
  static const Color blueSoft = Color(0xFFE6EBF4);

  // Shimmer Skeleton Tokens (`designs/main.main.svg`)
  static const Color shimmerBase = Color(0xFFECE4D3);
  static const Color shimmerHighlight = Color(0xFFF6F1E6);
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';

/// Base avatar primitive rendering either a cached network image or
/// deterministic warm-tinted serif initials (`designs/main.main.svg`).
///
/// For member records, always use `ServeMemberAvatar` which enforces the
/// `photoConsent == true` safeguarding gate (`FR-13.5`).
class ServeAvatar extends StatelessWidget {
  const ServeAvatar({
    required this.displayName,
    this.imageUrl,
    this.cacheKey,
    this.radius = 22,
    super.key,
  });

  final String displayName;
  final String? imageUrl;
  final String? cacheKey;
  final double radius;

  static const List<(Color, Color)> _palettes = <(Color, Color)>[
    (AppColors.goldSoft, AppColors.goldDark),
    (AppColors.redSoft, AppColors.oxblood),
    (AppColors.greenSoft, AppColors.green),
    (AppColors.blueSoft, AppColors.blue),
  ];

  bool get _hasValidUrl => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(displayName);
    final initials = computeInitials(displayName);
    if (!_hasValidUrl) {
      return _buildInitialsCircle(context, initials, palette);
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!.trim(),
        cacheKey: cacheKey,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, _) =>
            _buildInitialsCircle(context, initials, palette),
        errorWidget: (context, _, _) =>
            _buildInitialsCircle(context, initials, palette),
      ),
    );
  }

  Widget _buildInitialsCircle(
    BuildContext context,
    String initials,
    (Color, Color) palette,
  ) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: palette.$2,
      fontWeight: FontWeight.w700,
    );
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        color: palette.$1,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: Text(initials, style: textStyle),
    );
  }

  (Color, Color) _paletteFor(String seed) {
    final hash = seed.codeUnits.fold<int>(0, (acc, unit) => acc + unit);
    return _palettes[hash % _palettes.length];
  }

  static String computeInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    final first = parts.first.characters.first.toUpperCase();
    final last = parts.last.characters.first.toUpperCase();
    return '$first$last';
  }
}

import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Semantic pill badge tones matching `designs/main.main.svg`.
enum ServeBadgeTone { red, gold, green, amber, blue, gray, line }

/// Pill status badge with optional leading status dot (`CLAUDE.md §1.4`).
class ServeBadge extends StatelessWidget {
  const ServeBadge({
    required this.label,
    this.tone = ServeBadgeTone.gold,
    this.showDot = true,
    super.key,
  });

  final String label;
  final ServeBadgeTone tone;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: _foregroundColor);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: ServeSpacing.sm,
          vertical: ServeSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadiusDirectional.circular(
            ServeSpacing.radiusPill,
          ),
          border: tone == ServeBadgeTone.line
              ? Border.all(color: AppColors.line2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showDot) ...<Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _foregroundColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor {
    return switch (tone) {
      ServeBadgeTone.red => AppColors.redSoft,
      ServeBadgeTone.gold => AppColors.goldSoft,
      ServeBadgeTone.green => AppColors.greenSoft,
      ServeBadgeTone.amber => AppColors.amberSoft,
      ServeBadgeTone.blue => AppColors.blueSoft,
      ServeBadgeTone.gray => AppColors.cream,
      ServeBadgeTone.line => AppColors.ivory,
    };
  }

  Color get _foregroundColor {
    return switch (tone) {
      ServeBadgeTone.red => AppColors.oxblood,
      ServeBadgeTone.gold => AppColors.goldDark,
      ServeBadgeTone.green => AppColors.green,
      ServeBadgeTone.amber => AppColors.amber,
      ServeBadgeTone.blue => AppColors.blue,
      ServeBadgeTone.gray || ServeBadgeTone.line => AppColors.ink2,
    };
  }
}

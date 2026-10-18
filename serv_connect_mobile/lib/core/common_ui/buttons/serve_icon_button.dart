import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Accessible icon button enforcing a 48×48dp hit target and required
/// localized [tooltip] (`CLAUDE.md §21`).
class ServeIconButton extends StatelessWidget {
  const ServeIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.ink,
    this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        color: color,
        constraints: const BoxConstraints(
          minWidth: ServeSpacing.minHitTarget,
          minHeight: ServeSpacing.minHitTarget,
        ),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ServeSpacing.radiusMd),
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

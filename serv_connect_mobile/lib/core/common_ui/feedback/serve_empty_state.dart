import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/buttons/serve_button.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Editorial empty state widget (`CLAUDE.md §1.4`).
class ServeEmptyState extends StatelessWidget {
  const ServeEmptyState({
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(ServeSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _EmptyIconCircle(icon: icon),
            const SizedBox(height: ServeSpacing.md),
            Text(
              title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: ServeSpacing.xs),
              Text(
                subtitle!,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onActionPressed != null) ...<Widget>[
              const SizedBox(height: ServeSpacing.lg),
              ServeButton(label: actionLabel!, onPressed: onActionPressed),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyIconCircle extends StatelessWidget {
  const _EmptyIconCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.goldDark, size: 26),
    );
  }
}

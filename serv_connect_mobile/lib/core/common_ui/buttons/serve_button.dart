import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Button visual variants matching `designs/main.main.svg`.
enum ServeButtonVariant { primaryRed, ink, gold, outline, soft }

/// Shared editorial button enforcing a 48dp minimum touch target and built-in
/// loading spinner (`CLAUDE.md §1.4 & §21`).
class ServeButton extends StatelessWidget {
  const ServeButton({
    required this.label,
    required this.onPressed,
    this.variant = ServeButtonVariant.primaryRed,
    this.isLoading = false,
    this.isEnabled = true,
    this.isExpanded = false,
    this.leadingIcon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ServeButtonVariant variant;
  final bool isLoading;
  final bool isEnabled;
  final bool isExpanded;
  final IconData? leadingIcon;

  bool get _canTap => isEnabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: _canTap ? onPressed : null,
      style: _buildStyle(),
      child: _ServeButtonContent(
        label: label,
        isLoading: isLoading,
        leadingIcon: leadingIcon,
        foregroundColor: _foregroundColor,
      ),
    );
    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  ButtonStyle _buildStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _backgroundColor,
      foregroundColor: _foregroundColor,
      disabledBackgroundColor: AppColors.line,
      disabledForegroundColor: AppColors.muted,
      elevation: 0,
      minimumSize: const Size(
        ServeSpacing.minHitTarget,
        ServeSpacing.minHitTarget,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: ServeSpacing.lg,
        vertical: ServeSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ServeSpacing.radiusButton),
        side: _borderSide,
      ),
    );
  }

  Color get _backgroundColor {
    return switch (variant) {
      ServeButtonVariant.primaryRed => AppColors.red,
      ServeButtonVariant.ink => AppColors.ink,
      ServeButtonVariant.gold => AppColors.gold,
      ServeButtonVariant.outline => AppColors.ivory,
      ServeButtonVariant.soft => AppColors.redSoft,
    };
  }

  Color get _foregroundColor {
    return switch (variant) {
      ServeButtonVariant.primaryRed ||
      ServeButtonVariant.ink ||
      ServeButtonVariant.gold => AppColors.ivory,
      ServeButtonVariant.outline => AppColors.ink,
      ServeButtonVariant.soft => AppColors.oxblood,
    };
  }

  BorderSide get _borderSide {
    if (variant == ServeButtonVariant.outline) {
      return const BorderSide(color: AppColors.line2);
    }
    return BorderSide.none;
  }
}

class _ServeButtonContent extends StatelessWidget {
  const _ServeButtonContent({
    required this.label,
    required this.isLoading,
    required this.foregroundColor,
    this.leadingIcon,
  });

  final String label;
  final bool isLoading;
  final Color foregroundColor;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (leadingIcon != null) ...<Widget>[
          Icon(leadingIcon, size: 18),
          const SizedBox(width: ServeSpacing.xs),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

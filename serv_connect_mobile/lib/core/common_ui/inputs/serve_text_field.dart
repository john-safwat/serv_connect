import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Shared editorial text input field (`designs/main.main.svg`, `CLAUDE.md §1.4`).
class ServeTextField extends StatelessWidget {
  const ServeTextField({
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: textTheme.labelLarge),
          const SizedBox(height: ServeSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          style: textTheme.bodyLarge,
          decoration: _buildDecoration(textTheme),
        ),
      ],
    );
  }

  InputDecoration _buildDecoration(TextTheme textTheme) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      errorText: errorText,
      filled: true,
      fillColor: enabled ? AppColors.ivory : AppColors.cream,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: ServeSpacing.md,
        vertical: ServeSpacing.sm,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: AppColors.muted, size: 20),
      suffixIcon: suffixIcon,
      border: _border(AppColors.line2),
      enabledBorder: _border(AppColors.line2),
      focusedBorder: _border(AppColors.gold, width: 1.5),
      errorBorder: _border(AppColors.red),
      focusedErrorBorder: _border(AppColors.red, width: 1.5),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(ServeSpacing.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/buttons/serve_button.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';
import 'package:serv_connect_mobile/network/errors.dart';

/// Standard error fallback view when an initial load fails with no cached data
/// (`CLAUDE.md §7, §13 & §16.1`).
///
/// Renders dedicated messaging for [ForbiddenScopeError] (`403`) and
/// [FeatureDisabledError] (`403`).
class DefaultErrorView extends StatelessWidget {
  const DefaultErrorView({
    this.error,
    this.customMessage,
    this.onRetry,
    super.key,
  });

  final Errors? error;
  final String? customMessage;
  final VoidCallback? onRetry;

  bool get _canRetry =>
      onRetry != null &&
      error is! ForbiddenScopeError &&
      error is! FeatureDisabledError;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = _resolveMessage(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(ServeSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(_resolveIcon(), color: AppColors.oxblood, size: 36),
            const SizedBox(height: ServeSpacing.md),
            Text(
              message,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (_canRetry) ...<Widget>[
              const SizedBox(height: ServeSpacing.lg),
              ServeButton(
                label: LocaleKeys.common_retry.tr(context: context),
                variant: ServeButtonVariant.outline,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resolveMessage(BuildContext context) {
    if (customMessage != null && customMessage!.trim().isNotEmpty) {
      return customMessage!;
    }
    final explicit = error?.message;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit;
    }
    return switch (error) {
      ForbiddenScopeError() => LocaleKeys.errors_forbidden_scope.tr(
        context: context,
      ),
      FeatureDisabledError() => LocaleKeys.errors_feature_disabled.tr(
        context: context,
      ),
      NetworkError() => LocaleKeys.errors_network.tr(context: context),
      TimeoutError() => LocaleKeys.errors_timeout.tr(context: context),
      _ => LocaleKeys.errors_generic.tr(context: context),
    };
  }

  IconData _resolveIcon() {
    return switch (error) {
      ForbiddenScopeError() => Icons.lock_outline,
      FeatureDisabledError() => Icons.block_outlined,
      NetworkError() => Icons.wifi_off_outlined,
      _ => Icons.error_outline,
    };
  }
}

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Global toast feedback service (`CLAUDE.md §16.1 & §19`).
///
/// Feature pages never call `ScaffoldMessenger.of(context)` directly — they
/// emit a navigation effect handled via `getIt<Toaster>()`.
@lazySingleton
class Toaster {
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void showSuccess(String message) =>
      _show(message, backgroundColor: AppColors.green);

  void showWarning(String message) =>
      _show(message, backgroundColor: AppColors.amber);

  void showError(String message) =>
      _show(message, backgroundColor: AppColors.oxblood);

  void _show(String message, {required Color backgroundColor}) {
    final state = messengerKey.currentState;
    if (state == null) return;
    state
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: AppColors.ivory),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ServeSpacing.radiusMd),
          ),
        ),
      );
  }
}

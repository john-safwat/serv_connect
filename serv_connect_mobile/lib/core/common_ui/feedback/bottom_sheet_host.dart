import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Centralised host for editorial modal bottom sheets (`CLAUDE.md §16.1 & §19`).
@lazySingleton
class BottomSheetHost {
  Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ServeSpacing.radiusCard),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(ServeSpacing.md),
          child: builder(sheetContext),
        ),
      ),
    );
  }
}

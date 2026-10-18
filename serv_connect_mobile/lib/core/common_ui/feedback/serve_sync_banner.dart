import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';

enum ServeSyncBannerMode { synced, syncing, offline, graceExpired }

/// Non-blocking top banner indicating offline connectivity, active background
/// sync, or expired offline grace window (`FR-1.3`, `CLAUDE.md §1.4 & §13`).
class ServeSyncBanner extends StatelessWidget {
  const ServeSyncBanner({
    required this.mode,
    this.pendingCount = 0,
    this.onTap,
    super.key,
  });

  final ServeSyncBannerMode mode;
  final int pendingCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (mode == ServeSyncBannerMode.synced && pendingCount == 0) {
      return const SizedBox.shrink();
    }
    return Material(
      color: _backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: ServeSpacing.md,
            vertical: ServeSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Icon(_icon, size: 16, color: _foregroundColor),
              const SizedBox(width: ServeSpacing.xs),
              Expanded(
                child: Text(
                  _label(context),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: _foregroundColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context) {
    return switch (mode) {
      ServeSyncBannerMode.graceExpired =>
        LocaleKeys.common_offline_mutations_disabled.tr(context: context),
      ServeSyncBannerMode.offline => LocaleKeys.common_offline_banner.tr(
        context: context,
      ),
      ServeSyncBannerMode.syncing => LocaleKeys.common_syncing.tr(
        context: context,
      ),
      ServeSyncBannerMode.synced => LocaleKeys.common_pending_changes.tr(
        context: context,
      ),
    };
  }

  Color get _backgroundColor {
    return switch (mode) {
      ServeSyncBannerMode.graceExpired => AppColors.redSoft,
      ServeSyncBannerMode.offline => AppColors.amberSoft,
      ServeSyncBannerMode.syncing ||
      ServeSyncBannerMode.synced => AppColors.goldSoft,
    };
  }

  Color get _foregroundColor {
    return switch (mode) {
      ServeSyncBannerMode.graceExpired => AppColors.oxblood,
      ServeSyncBannerMode.offline => AppColors.amber,
      ServeSyncBannerMode.syncing ||
      ServeSyncBannerMode.synced => AppColors.goldDark,
    };
  }

  IconData get _icon {
    return switch (mode) {
      ServeSyncBannerMode.graceExpired => Icons.lock_clock_outlined,
      ServeSyncBannerMode.offline => Icons.cloud_off_outlined,
      ServeSyncBannerMode.syncing => Icons.sync,
      ServeSyncBannerMode.synced => Icons.cloud_upload_outlined,
    };
  }
}

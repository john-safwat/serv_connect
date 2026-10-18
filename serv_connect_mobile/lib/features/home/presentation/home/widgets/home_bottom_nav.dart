import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_states.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';

/// 5-tab editorial bottom navigation bar (`Home`, `Schedule`, `Attend`, `Word`,
/// `More`) matching `designs/main.main.svg`.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    required this.activeTab,
    required this.onTabSelected,
    super.key,
  });

  final HomeTab activeTab;
  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: ServeSpacing.xs,
            vertical: ServeSpacing.xxs,
          ),
          child: Row(
            children: HomeTab.values
                .map(
                  (tab) => Expanded(
                    child: _NavTabButton(
                      tab: tab,
                      isActive: tab == activeTab,
                      onTap: () => onTabSelected(tab),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final HomeTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.red : AppColors.muted;
    final label = _labelFor(context, tab);
    return InkWell(
      borderRadius: BorderRadius.circular(ServeSpacing.radiusMd),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ServeSpacing.minHitTarget,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(_iconFor(tab), size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(BuildContext context, HomeTab item) {
    return switch (item) {
      HomeTab.home => LocaleKeys.nav_home.tr(context: context),
      HomeTab.schedule => LocaleKeys.nav_schedule.tr(context: context),
      HomeTab.attend => LocaleKeys.nav_attend.tr(context: context),
      HomeTab.word => LocaleKeys.nav_word.tr(context: context),
      HomeTab.more => LocaleKeys.nav_more.tr(context: context),
    };
  }

  IconData _iconFor(HomeTab item) {
    return switch (item) {
      HomeTab.home => Icons.home_outlined,
      HomeTab.schedule => Icons.calendar_today_outlined,
      HomeTab.attend => Icons.fact_check_outlined,
      HomeTab.word => Icons.menu_book_outlined,
      HomeTab.more => Icons.grid_view_outlined,
    };
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/serve_empty_state.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_states.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';

/// Renders localized editorial placeholder content for non-Home shell tabs
/// until their domain feature plans (`M4`–`M6`) land.
class HomePlaceholderTab extends StatelessWidget {
  const HomePlaceholderTab({required this.tab, super.key});

  final HomeTab tab;

  @override
  Widget build(BuildContext context) {
    return ServeEmptyState(
      icon: _iconFor(tab),
      title: _titleFor(context, tab),
      subtitle: _subtitleFor(context, tab),
    );
  }

  String _titleFor(BuildContext context, HomeTab current) {
    return switch (current) {
      HomeTab.home => LocaleKeys.nav_home.tr(context: context),
      HomeTab.schedule => LocaleKeys.nav_schedule.tr(context: context),
      HomeTab.attend => LocaleKeys.nav_attend.tr(context: context),
      HomeTab.word => LocaleKeys.nav_word.tr(context: context),
      HomeTab.more => LocaleKeys.nav_more.tr(context: context),
    };
  }

  String _subtitleFor(BuildContext context, HomeTab current) {
    return switch (current) {
      HomeTab.home => LocaleKeys.home_welcome_subtitle.tr(context: context),
      HomeTab.schedule => LocaleKeys.home_schedule_placeholder.tr(
        context: context,
      ),
      HomeTab.attend => LocaleKeys.home_attend_placeholder.tr(context: context),
      HomeTab.word => LocaleKeys.home_word_placeholder.tr(context: context),
      HomeTab.more => LocaleKeys.home_more_placeholder.tr(context: context),
    };
  }

  IconData _iconFor(HomeTab current) {
    return switch (current) {
      HomeTab.home => Icons.home_outlined,
      HomeTab.schedule => Icons.calendar_today_outlined,
      HomeTab.attend => Icons.fact_check_outlined,
      HomeTab.word => Icons.menu_book_outlined,
      HomeTab.more => Icons.grid_view_outlined,
    };
  }
}

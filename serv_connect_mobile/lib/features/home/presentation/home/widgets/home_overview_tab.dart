import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/avatars/serve_member_avatar.dart';
import 'package:serv_connect_mobile/core/common_ui/badges/serve_badge.dart';
import 'package:serv_connect_mobile/core/common_ui/cards/serve_card.dart';
import 'package:serv_connect_mobile/core/l10n/org_label_resolver.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';

/// Editorial overview tab showcasing the ServeConnect design system cards,
/// badges, and safeguarding-aware avatar primitives (`designs/main.main.svg`).
class HomeOverviewTab extends StatelessWidget {
  const HomeOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(ServeSpacing.md),
      children: const <Widget>[
        _WelcomeHeroCard(),
        SizedBox(height: ServeSpacing.md),
        _DailyLoopSummaryCard(),
      ],
    );
  }
}

class _WelcomeHeroCard extends StatelessWidget {
  const _WelcomeHeroCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ServeCard(
      variant: ServeCardVariant.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ServeBadge(
            label: LocaleKeys.common_synced.tr(context: context),
            tone: ServeBadgeTone.green,
          ),
          const SizedBox(height: ServeSpacing.sm),
          Text(
            LocaleKeys.home_welcome_title.tr(context: context),
            style: textTheme.displaySmall,
          ),
          const SizedBox(height: ServeSpacing.xs),
          Text(
            LocaleKeys.home_welcome_subtitle.tr(context: context),
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DailyLoopSummaryCard extends StatelessWidget {
  const _DailyLoopSummaryCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groupLabel = OrgLabelResolver.of(context).groupLabel;
    return ServeCard(
      child: Row(
        children: <Widget>[
          const ServeMemberAvatar(
            memberId: 'sample-group-avatar',
            displayName: 'St Mark Youth',
            photoConsent: false,
          ),
          const SizedBox(width: ServeSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKeys.home_quick_actions.tr(context: context),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: ServeSpacing.xxs),
                Text(
                  LocaleKeys.home_upcoming_meetings.tr(context: context),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ServeBadge(label: groupLabel, tone: ServeBadgeTone.red),
        ],
      ),
    );
  }
}

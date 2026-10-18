import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/badges/serve_badge.dart';
import 'package:serv_connect_mobile/core/common_ui/buttons/serve_button.dart';
import 'package:serv_connect_mobile/core/l10n/org_label_resolver.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';

/// Editorial header bar with brand title, configurable role badge, and
/// EN/AR language switcher (`CLAUDE.md §5`).
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    required this.onToggleLanguage,
    super.key,
  });

  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final servantLabel = OrgLabelResolver.of(context).servantLabel;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: ServeSpacing.md,
        vertical: ServeSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKeys.common_app_name.tr(context: context),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: ServeSpacing.xxs),
                ServeBadge(label: servantLabel),
              ],
            ),
          ),
          ServeButton(
            label: isArabic ? 'English' : 'العربية',
            variant: ServeButtonVariant.outline,
            leadingIcon: Icons.language_outlined,
            onPressed: onToggleLanguage,
          ),
        ],
      ),
    );
  }
}

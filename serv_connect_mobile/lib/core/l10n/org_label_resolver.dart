import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';

/// Configurable church terminology overrides (`BRD §16`, `CLAUDE.md §5`).
class OrgLabelOverrides {
  const OrgLabelOverrides({
    this.servantLabels = const <String, String>{},
    this.servedMemberLabels = const <String, String>{},
    this.stageLabels = const <String, String>{},
    this.groupLabels = const <String, String>{},
  });

  final Map<String, String> servantLabels;
  final Map<String, String> servedMemberLabels;
  final Map<String, String> stageLabels;
  final Map<String, String> groupLabels;
}

/// Resolved localised terminology for the current [BuildContext].
class ResolvedOrgLabels {
  const ResolvedOrgLabels(this._context, this._overrides);

  final BuildContext _context;
  final OrgLabelOverrides _overrides;

  String get servantLabel => _resolve(
    _overrides.servantLabels,
    LocaleKeys.common_role_servant,
  );

  String get servedMemberLabel => _resolve(
    _overrides.servedMemberLabels,
    LocaleKeys.common_role_served_member,
  );

  String get stageLabel =>
      _resolve(_overrides.stageLabels, LocaleKeys.common_stage);

  String get groupLabel =>
      _resolve(_overrides.groupLabels, LocaleKeys.common_group);

  String _resolve(Map<String, String> map, String fallbackKey) {
    final code = Localizations.localeOf(_context).languageCode;
    final custom = map[code]?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return fallbackKey.tr(context: _context);
  }
}

class OrgLabelResolver extends InheritedWidget {
  const OrgLabelResolver({
    required super.child,
    this.overrides = const OrgLabelOverrides(),
    super.key,
  });

  final OrgLabelOverrides overrides;

  static ResolvedOrgLabels of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<OrgLabelResolver>();
    return ResolvedOrgLabels(
      context,
      inherited?.overrides ?? const OrgLabelOverrides(),
    );
  }

  @override
  bool updateShouldNotify(OrgLabelResolver oldWidget) =>
      oldWidget.overrides != overrides;
}

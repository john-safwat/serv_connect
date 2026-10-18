import 'package:injectable/injectable.dart';

/// Feature modules matching BRD §1.2 and FR-16.5.
enum FeatureModule {
  identity('identity'),
  members('members'),
  groups('groups'),
  schedule('schedule'),
  attendance('attendance'),
  tasks('tasks'),
  communication('communication'),
  curriculum('curriculum'),
  content('content'),
  engagement('engagement'),
  trips('trips'),
  notifications('notifications'),
  safeguarding('safeguarding'),
  audit('audit'),
  analytics('analytics'),
  prayer('prayer'),
  admin('admin');

  const FeatureModule(this.key);
  final String key;
}

/// Evaluates whether a [FeatureModule] is enabled for the active organisation.
///
/// Defaults MVP modules to enabled when no override map is cached yet.
@lazySingleton
class FeatureFlagService {
  final Map<String, bool> _flags = <String, bool>{};

  static const Set<FeatureModule> _defaultMvpEnabled = <FeatureModule>{
    FeatureModule.identity,
    FeatureModule.members,
    FeatureModule.groups,
    FeatureModule.schedule,
    FeatureModule.attendance,
    FeatureModule.tasks,
    FeatureModule.communication,
    FeatureModule.content,
    FeatureModule.notifications,
    FeatureModule.safeguarding,
    FeatureModule.admin,
  };

  void updateFlags(Map<String, bool> flags) {
    _flags
      ..clear()
      ..addAll(flags);
  }

  bool isEnabled(FeatureModule module) {
    final explicit = _flags[module.key];
    if (explicit != null) {
      return explicit;
    }
    return _defaultMvpEnabled.contains(module);
  }
}

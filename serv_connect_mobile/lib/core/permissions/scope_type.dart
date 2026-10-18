/// Hierarchical authorization scopes matching BRD §6 and Backend §11.
enum ScopeType {
  org('ORG'),
  stage('STAGE'),
  group('GROUP'),
  self('SELF'),
  children('CHILDREN');

  const ScopeType(this.wireValue);
  final String wireValue;

  static ScopeType fromWire(String raw) {
    final normalized = raw.trim().toUpperCase();
    for (final value in ScopeType.values) {
      if (value.wireValue == normalized) {
        return value;
      }
    }
    return ScopeType.self;
  }
}

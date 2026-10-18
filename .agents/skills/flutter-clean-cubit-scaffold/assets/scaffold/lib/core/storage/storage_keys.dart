/// Keys for [SecureStorage] (sensitive) and [Preferences] (non-sensitive).
/// The `sensitive` flag routes each key to the right facade — the facades
/// throw if a key is used with the wrong store.
enum StorageKey {
  // Sensitive — SecureStorage.
  accessToken('access_token', sensitive: true),
  refreshToken('refresh_token', sensitive: true),
  user('user_json', sensitive: true),

  // Non-sensitive — Preferences.
  deviceToken('device_token', sensitive: false),
  appLanguage('app_language', sensitive: false),
  firstTimePermission('first_time_permission', sensitive: false);

  const StorageKey(this.value, {required this.sensitive});

  final String value;
  final bool sensitive;
}

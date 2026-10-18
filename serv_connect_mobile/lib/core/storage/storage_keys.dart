/// Keys for `SecureStorage` (`sensitive: true`) and `Preferences` (`sensitive: false`).
///
/// The facades enforce the [sensitive] flag at runtime and throw [ArgumentError]
/// if a key is passed to the wrong storage backend.
enum StorageKey {
  // Sensitive — SecureStorage only (`CLAUDE.md §7`).
  accessToken('access_token', sensitive: true),
  refreshToken('refresh_token', sensitive: true),
  hiveEncryptionKey('hive_aes_key', sensitive: true),
  userSessionJson('user_session_json', sensitive: true),
  lastServerAuthAt('last_server_auth_at', sensitive: true),

  // Non-sensitive — Preferences (`SharedPreferences`).
  appLanguage('app_language', sensitive: false),
  lastChangeSeq('last_change_seq', sensitive: false),
  wifiOnlyMediaDownload('wifi_only_media_download', sensitive: false),
  firstRunCompleted('first_run_completed', sensitive: false);

  const StorageKey(this.value, {required this.sensitive});

  final String value;
  final bool sensitive;
}

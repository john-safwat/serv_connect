import 'package:serv_connect_mobile/core/config/flavor_config.dart';

/// Typed environment configuration loaded from `.env.<flavor>` at startup.
///
/// Registered as a singleton in `get_it` during bootstrap. Never read
/// `dotenv.env` outside `AppEnvironmentLoader`.
class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.apiBaseUrl,
    required this.envName,
    required this.defaultOfflineGraceDays,
    required this.mediaCacheMaxMb,
    required this.syncBatchSize,
    this.sentryDsn = '',
  });

  final Flavor flavor;
  final String apiBaseUrl;
  final String envName;
  final int defaultOfflineGraceDays;
  final int mediaCacheMaxMb;
  final int syncBatchSize;
  final String sentryDsn;

  bool get isProduction => flavor == Flavor.prod;
  bool get isStaging => flavor == Flavor.staging;
  bool get isDev => flavor == Flavor.dev;

  /// Validates that all required configuration keys are present and valid.
  /// Throws [StateError] immediately on boot if any key is missing or invalid.
  void assertConfigured() {
    final missing = _collectMissingKeys();
    if (missing.isNotEmpty) {
      throw StateError(
        'AppEnvironment (${flavor.envName}) missing or invalid keys: '
        '${missing.join(', ')}',
      );
    }
  }

  List<String> _collectMissingKeys() {
    return <String>[
      if (!_isValidApiBaseUrl(apiBaseUrl)) 'API_BASE_URL',
      if (!_isValidString(envName)) 'ENV_NAME',
      if (defaultOfflineGraceDays <= 0) 'DEFAULT_OFFLINE_GRACE_DAYS',
      if (mediaCacheMaxMb <= 0) 'MEDIA_CACHE_MAX_MB',
      if (syncBatchSize <= 0) 'SYNC_BATCH_SIZE',
    ];
  }

  bool _isValidApiBaseUrl(String value) {
    if (!_isValidString(value)) return false;
    if (isStaging || isProduction) {
      return value.trim().startsWith('https://');
    }
    return true;
  }

  bool _isValidString(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && !trimmed.startsWith('__');
  }
}

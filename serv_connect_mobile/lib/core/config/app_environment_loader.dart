import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:serv_connect_mobile/core/config/app_environment.dart';
import 'package:serv_connect_mobile/core/config/flavor_config.dart';

/// Loads `.env.<flavor>` via `flutter_dotenv` and constructs [AppEnvironment].
class AppEnvironmentLoader {
  const AppEnvironmentLoader();

  Future<AppEnvironment> load(Flavor flavor) async {
    final config = FlavorConfig(flavor: flavor);
    await dotenv.load(fileName: config.envFileName);
    return fromMap(flavor: flavor, envMap: dotenv.env);
  }

  /// Parses raw key-value map into [AppEnvironment] and asserts completeness.
  AppEnvironment fromMap({
    required Flavor flavor,
    required Map<String, String> envMap,
  }) {
    final env = AppEnvironment(
      flavor: flavor,
      apiBaseUrl: _readString(envMap, 'API_BASE_URL'),
      envName: _readString(envMap, 'ENV_NAME'),
      defaultOfflineGraceDays: _readInt(envMap, 'DEFAULT_OFFLINE_GRACE_DAYS'),
      mediaCacheMaxMb: _readInt(envMap, 'MEDIA_CACHE_MAX_MB'),
      syncBatchSize: _readInt(envMap, 'SYNC_BATCH_SIZE'),
      sentryDsn: _readString(envMap, 'SENTRY_DSN'),
    )..assertConfigured();
    return env;
  }

  String _readString(Map<String, String> map, String key) {
    final raw = map[key]?.trim() ?? '';
    if (raw.isEmpty || raw.startsWith('__')) {
      return '';
    }
    return raw;
  }

  int _readInt(Map<String, String> map, String key) {
    final raw = _readString(map, key);
    return int.tryParse(raw) ?? 0;
  }
}

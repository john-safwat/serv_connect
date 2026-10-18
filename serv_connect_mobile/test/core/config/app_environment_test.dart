import 'package:flutter_test/flutter_test.dart';
import 'package:serv_connect_mobile/core/config/app_environment.dart';
import 'package:serv_connect_mobile/core/config/app_environment_loader.dart';
import 'package:serv_connect_mobile/core/config/feature_flag_service.dart';
import 'package:serv_connect_mobile/core/config/flavor_config.dart';

void main() {
  group('AppEnvironment & AppEnvironmentLoader', () {
    test('assertConfigured_validValues_succeeds', () {
      const env = AppEnvironment(
        flavor: Flavor.dev,
        apiBaseUrl: 'https://api.dev.serveconnect.org',
        envName: 'dev',
        defaultOfflineGraceDays: 14,
        mediaCacheMaxMb: 250,
        syncBatchSize: 50,
      );
      expect(env.assertConfigured, returnsNormally);
      expect(env.isDev, isTrue);
      expect(env.isStaging, isFalse);
      expect(env.isProduction, isFalse);
    });

    test('assertConfigured_missingOrPlaceholderValues_throwsStateError', () {
      const env = AppEnvironment(
        flavor: Flavor.prod,
        apiBaseUrl: '__PLACEHOLDER__',
        envName: '',
        defaultOfflineGraceDays: 0,
        mediaCacheMaxMb: -1,
        syncBatchSize: 0,
      );
      expect(env.assertConfigured, throwsStateError);
    });

    test('fromMap_validMap_parsesTypedEnvironment', () {
      const loader = AppEnvironmentLoader();
      final env = loader.fromMap(
        flavor: Flavor.staging,
        envMap: <String, String>{
          'API_BASE_URL': 'https://api.staging.serveconnect.org',
          'ENV_NAME': 'staging',
          'DEFAULT_OFFLINE_GRACE_DAYS': '21',
          'MEDIA_CACHE_MAX_MB': '300',
          'SYNC_BATCH_SIZE': '40',
          'SENTRY_DSN': 'https://sentry.example/1',
        },
      );
      expect(env.isStaging, isTrue);
      expect(env.defaultOfflineGraceDays, 21);
      expect(env.mediaCacheMaxMb, 300);
      expect(env.syncBatchSize, 40);
    });
  });

  group('FlavorConfig & FeatureFlagService', () {
    test('flavorConfig_returnsExpectedEnvFileName', () {
      const config = FlavorConfig(flavor: Flavor.prod);
      expect(config.envFileName, '.env.prod');
      expect(config.isProd, isTrue);
      expect(config.isDev, isFalse);
    });

    test('featureFlagService_defaultsAndOverrides_resolvedCorrectly', () {
      final service = FeatureFlagService();
      expect(service.isEnabled(FeatureModule.attendance), isTrue);
      expect(service.isEnabled(FeatureModule.trips), isFalse);

      service.updateFlags(<String, bool>{
        'attendance': false,
        'trips': true,
      });
      expect(service.isEnabled(FeatureModule.attendance), isFalse);
      expect(service.isEnabled(FeatureModule.trips), isTrue);
    });
  });
}

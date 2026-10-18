import { describe, expect, it } from 'vitest';
import { AppEnvironment, parseAppEnvironment } from './app_environment';
import { FeatureFlagService, FeatureModule } from './feature_flag_service';

describe('AppEnvironment & FeatureFlagService', () => {
  it('parseAppEnvironment_validDevConfig_returnsNormalizedConfig', () => {
    const config = parseAppEnvironment({
      VITE_API_BASE_URL: 'http://localhost:8080/',
      VITE_ENV_NAME: 'dev',
      VITE_DEFAULT_LOCALE: 'ar',
      VITE_IDLE_TIMEOUT_MINUTES: '20',
    });
    expect(config.apiBaseUrl).toBe('http://localhost:8080');
    expect(config.envName).toBe('dev');
    expect(config.defaultLocale).toBe('ar');
    expect(config.idleTimeoutMinutes).toBe(20);
  });

  it('parseAppEnvironment_placeholderValue_throwsError', () => {
    expect(() =>
      parseAppEnvironment({
        VITE_API_BASE_URL: '__VITE_API_BASE_URL__',
        VITE_ENV_NAME: 'dev',
        VITE_DEFAULT_LOCALE: 'en',
        VITE_IDLE_TIMEOUT_MINUTES: '15',
      }),
    ).toThrow(/VITE_API_BASE_URL/);
  });

  it('parseAppEnvironment_nonHttpsInProd_throwsError', () => {
    expect(() =>
      parseAppEnvironment({
        VITE_API_BASE_URL: 'http://api.serveconnect.org',
        VITE_ENV_NAME: 'prod',
        VITE_DEFAULT_LOCALE: 'en',
        VITE_IDLE_TIMEOUT_MINUTES: '15',
      }),
    ).toThrow(/https:\/\//);
  });

  it('parseAppEnvironment_invalidEnvOrLocaleOrTimeout_throwsError', () => {
    expect(() =>
      parseAppEnvironment({
        VITE_API_BASE_URL: 'https://api.serveconnect.org',
        VITE_ENV_NAME: 'invalid',
        VITE_DEFAULT_LOCALE: 'en',
        VITE_IDLE_TIMEOUT_MINUTES: '15',
      }),
    ).toThrow(/VITE_ENV_NAME/);

    expect(() =>
      parseAppEnvironment({
        VITE_API_BASE_URL: 'https://api.serveconnect.org',
        VITE_ENV_NAME: 'staging',
        VITE_DEFAULT_LOCALE: 'fr',
        VITE_IDLE_TIMEOUT_MINUTES: '15',
      }),
    ).toThrow(/VITE_DEFAULT_LOCALE/);

    expect(() =>
      parseAppEnvironment({
        VITE_API_BASE_URL: 'https://api.serveconnect.org',
        VITE_ENV_NAME: 'staging',
        VITE_DEFAULT_LOCALE: 'en',
        VITE_IDLE_TIMEOUT_MINUTES: '0',
      }),
    ).toThrow(/VITE_IDLE_TIMEOUT_MINUTES/);
  });

  it('assertConfigured_cachesSingletonConfig_andSupportsFeatureFlags', () => {
    const cfg = AppEnvironment.assertConfigured({
      VITE_API_BASE_URL: 'https://staging.serveconnect.org',
      VITE_ENV_NAME: 'staging',
      VITE_DEFAULT_LOCALE: 'en',
      VITE_IDLE_TIMEOUT_MINUTES: '10',
    });
    expect(AppEnvironment.config).toEqual(cfg);
    expect(FeatureFlagService.isEnabled(FeatureModule.members)).toBe(true);
    expect(FeatureFlagService.isEnabled(FeatureModule.curriculum)).toBe(false);
    FeatureFlagService.setFlags({ [FeatureModule.curriculum]: true });
    expect(FeatureFlagService.isEnabled(FeatureModule.curriculum)).toBe(true);
  });
});

import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterAll, afterEach, beforeAll } from 'vitest';
import { AppEnvironment } from '../core/config/app_environment';
import { FeatureFlagService } from '../core/config/feature_flag_service';
import { AppEventBus } from '../core/event_bus/app_event_bus';
import { AuthEventBus } from '../core/event_bus/auth_event_bus';
import { LocaleController } from '../core/i18n/locale_controller';
import { OrgLabelResolver } from '../core/i18n/org_label_resolver';
import { AuthSession } from '../core/session/auth_session';
import { ConnectivityWatcher } from '../core/session/connectivity_watcher';
import { Toaster } from '../components/feedback/toaster_store';
import { mswServer } from './msw_server';

beforeAll(() => {
  AppEnvironment.assertConfigured({
    VITE_API_BASE_URL: 'https://api.serveconnect.test',
    VITE_ENV_NAME: 'dev',
    VITE_DEFAULT_LOCALE: 'en',
    VITE_IDLE_TIMEOUT_MINUTES: '15',
  });
  LocaleController.initialize('en');
  mswServer.listen();
});

afterEach(() => {
  cleanup();
  mswServer.resetHandlers();
  AuthSession.clear();
  FeatureFlagService.resetToDefaults();
  OrgLabelResolver.clearOverrides();
  ConnectivityWatcher.setOnlineForTesting(true);
  Toaster.clearAll();
  AppEventBus.clearForTesting();
  AuthEventBus.clearForTesting();
  LocaleController.setLocale('en');
});

afterAll(() => {
  mswServer.close();
});

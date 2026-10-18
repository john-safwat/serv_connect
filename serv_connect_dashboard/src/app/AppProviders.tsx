import { type QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type React from 'react';
import { useEffect, useState } from 'react';
import { I18nextProvider } from 'react-i18next';
import { ToasterHost } from '../components/feedback/Toaster';
import { Toaster } from '../components/feedback/toaster_store';
import { AppEnvironment } from '../core/config/app_environment';
import { AppEventBus } from '../core/event_bus/app_event_bus';
import { AuthEventBus } from '../core/event_bus/auth_event_bus';
import { i18n } from '../core/i18n/i18n';
import { LocaleController } from '../core/i18n/locale_controller';
import { IdleLockWatcher } from '../core/session/idle_lock_watcher';
import { LocaleKeys } from '../generated/locale_keys.g';
import { createDashboardQueryClient } from './query_client';

export interface AppProvidersProps {
  readonly queryClient?: QueryClient;
  readonly children: React.ReactNode;
}

export function AppProviders({
  queryClient: externalClient,
  children,
}: AppProvidersProps): React.JSX.Element {
  const [queryClient] = useState<QueryClient>(() => externalClient ?? createDashboardQueryClient());

  useEffect(() => {
    const config = AppEnvironment.config;
    LocaleController.initialize(config.defaultLocale);
    const watcher = new IdleLockWatcher({
      timeoutMinutes: config.idleTimeoutMinutes,
      onLock: () => queryClient.clear(),
    });
    watcher.start();
    const unsubApp = AppEventBus.subscribe((evt) => {
      if (evt.type === 'SCOPE_REVOKED') {
        queryClient.clear();
        Toaster.showWarning(i18n.t(LocaleKeys.errors_scope_revoked));
      }
    });
    const unsubAuth = AuthEventBus.subscribe((evt) => {
      if (evt.type === 'LOGIN_REQUIRED' || evt.type === 'IDLE_LOCK') {
        queryClient.clear();
      }
    });
    return () => {
      watcher.stop();
      unsubApp();
      unsubAuth();
    };
  }, [queryClient]);

  return (
    <I18nextProvider i18n={i18n}>
      <QueryClientProvider client={queryClient}>
        {children}
        <ToasterHost />
      </QueryClientProvider>
    </I18nextProvider>
  );
}

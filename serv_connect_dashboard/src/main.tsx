import React from 'react';
import { createRoot } from 'react-dom/client';
import { AppProviders } from './app/AppProviders';
import { AppRouter } from './app/AppRouter';
import { AppEnvironment } from './core/config/app_environment';
import './styles/global.css';

export function bootstrap(rootElement: HTMLElement): void {
  const root = createRoot(rootElement);
  try {
    AppEnvironment.assertConfigured();
    root.render(
      <React.StrictMode>
        <AppProviders>
          <AppRouter />
        </AppProviders>
      </React.StrictMode>,
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Invalid environment configuration.';
    root.render(
      <div role="alert">
        <h1>ServeConnect Configuration Error</h1>
        <p>{message}</p>
      </div>,
    );
  }
}

const container = document.getElementById('root');
if (container) {
  bootstrap(container);
}

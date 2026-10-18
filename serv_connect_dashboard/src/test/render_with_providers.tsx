import { render, type RenderResult } from '@testing-library/react';
import type React from 'react';
import { MemoryRouter } from 'react-router';
import { AppProviders } from '../app/AppProviders';
import { createDashboardQueryClient } from '../app/query_client';

export interface RenderWithProvidersOptions {
  readonly initialEntries?: readonly string[];
}

export function renderWithProviders(
  ui: React.ReactElement,
  options: RenderWithProvidersOptions = {},
): RenderResult {
  const queryClient = createDashboardQueryClient();
  const entries = options.initialEntries ? [...options.initialEntries] : ['/'];

  return render(
    <AppProviders queryClient={queryClient}>
      <MemoryRouter initialEntries={entries}>{ui}</MemoryRouter>
    </AppProviders>,
  );
}

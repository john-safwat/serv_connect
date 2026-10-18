import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Route, Routes } from 'react-router';
import { describe, expect, it } from 'vitest';
import { OverviewShellPage } from '../features/analytics';
import { renderWithProviders } from '../test/render_with_providers';
import { AppShell } from './AppShell';

describe('AppShell & OverviewShellPage (LTR en + RTL ar + Zero PII in URL/Storage)', () => {
  it('appShell_switchesBetweenEnglishLtrAndArabicRtl_andTogglesSidebar', async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<OverviewShellPage />} />
        </Route>
      </Routes>,
    );

    expect(screen.getByText('ServeConnect Administration Console')).toBeInTheDocument();
    expect(document.documentElement.dir).toBe('ltr');
    expect(document.documentElement.lang).toBe('en');

    const langButton = screen.getByRole('button', { name: /Switch language/i });
    expect(langButton).toHaveTextContent('العربية');
    await user.click(langButton);

    expect(document.documentElement.dir).toBe('rtl');
    expect(document.documentElement.lang).toBe('ar');
    expect(screen.getByText('وحدة تحكّم إدارة ServeConnect')).toBeInTheDocument();

    const sidebarToggle = screen.getByRole('button', { name: /تبديل القائمة الجانبية/i });
    await user.click(sidebarToggle);
  });

  it('overviewShellController_handlesSearchStatesModalAndDrawer_withoutWritingPiiToUrlOrStorage', async () => {
    const user = userEvent.setup();
    renderWithProviders(
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<OverviewShellPage />} />
        </Route>
      </Routes>,
    );

    const searchInput = screen.getByLabelText('Search');
    await user.type(searchInput, 'Member #101');
    expect(window.location.search).toBe('');
    expect(window.sessionStorage.length).toBe(0);
    expect(screen.getByText('Member #101')).toBeInTheDocument();
    expect(screen.queryByText('Member #102')).not.toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: '403' }));
    expect(screen.getByText('Access Restricted')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Loading…' }));
    expect(screen.getByLabelText('Loading…')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Retry' }));
    expect(screen.getByText('Member #101')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Open confirmation modal' }));
    expect(screen.getByText('Audited Administrative Action')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Close' }));

    await user.click(screen.getByRole('button', { name: 'Open detail drawer' }));
    expect(screen.getByText('Stage & Scope Inspector')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Close' }));

    await user.click(screen.getByRole('button', { name: 'Show status toast' }));
    expect(screen.getAllByText('Synced').length).toBeGreaterThan(0);
  });
});

import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { ConnectivityWatcher } from '../core/session/connectivity_watcher';
import { AppErrorFactory } from '../network/errors';
import { renderWithProviders } from '../test/render_with_providers';
import {
  DefaultErrorView,
  ServeBadge,
  ServeButton,
  ServeCardShimmer,
  ServeDrawer,
  ServeEmptyState,
  ServeListShimmer,
  ServeMemberAvatar,
  ServeModal,
  ServeOfflineBanner,
  ServeSelect,
  ServeTable,
  ServeTabs,
  ServeTextField,
  Toaster,
} from './index';

describe('Serve* Shared UI Component Catalogue', () => {
  it('serveMemberAvatar_whenPhotoConsentFalse_neverRendersImgTagAndShowsInitials', () => {
    const { container } = renderWithProviders(
      <div>
        <ServeMemberAvatar
          displayName="Member One"
          photoUrl="https://example.org/private-photo.jpg"
          photoConsent={false}
        />
        <ServeMemberAvatar
          displayName="Member Two"
          photoUrl="https://example.org/consented-photo.jpg"
          photoConsent={true}
        />
      </div>,
    );

    const images = container.querySelectorAll('img');
    expect(images).toHaveLength(1);
    expect(images[0]?.getAttribute('src')).toBe('https://example.org/consented-photo.jpg');
    expect(screen.getByText('MO')).toBeInTheDocument();
  });

  it('serveButtonInputsSelectTabsAndTable_handleUserInteractionsAndAccessibility', async () => {
    const user = userEvent.setup();
    const onRowClick = vi.fn();
    const onTabChange = vi.fn();

    renderWithProviders(
      <div>
        <ServeButton isLoading>Saving</ServeButton>
        <ServeTextField label="Group Title" errorText="Title is required" />
        <ServeSelect
          label="Stage"
          options={[
            { value: 's1', label: 'Primary' },
            { value: 's2', label: 'Secondary' },
          ]}
        />
        <ServeTabs
          tabs={[
            { key: 'a', label: 'Tab A' },
            { key: 'b', label: 'Tab B' },
          ]}
          activeKey="a"
          onChange={onTabChange}
        />
        <ServeTable
          columns={[{ key: 'name', header: 'Name', renderCell: (r: { id: string; label: string }) => r.label }]}
          rows={[{ id: '1', label: 'Row 1' }]}
          getRowKey={(r) => r.id}
          onRowClick={onRowClick}
        />
        <ServeBadge tone="gold">Featured</ServeBadge>
      </div>,
    );

    expect(screen.getByRole('button', { name: 'Saving' })).toBeDisabled();
    expect(screen.getByRole('alert')).toHaveTextContent('Title is required');

    await user.click(screen.getByRole('tab', { name: 'Tab B' }));
    expect(onTabChange).toHaveBeenCalledWith('b');

    await user.click(screen.getByText('Row 1'));
    expect(onRowClick).toHaveBeenCalledWith({ id: '1', label: 'Row 1' });
  });

  it('serveModalDrawerFeedbackAndShimmers_renderAndCloseOnEscape', async () => {
    const user = userEvent.setup();
    const onCloseModal = vi.fn();
    const onCloseDrawer = vi.fn();
    ConnectivityWatcher.setOnlineForTesting(false);

    renderWithProviders(
      <div>
        <ServeOfflineBanner />
        <ServeCardShimmer />
        <ServeListShimmer rows={2} />
        <ServeEmptyState title="Empty List" actionLabel="Create" onAction={() => Toaster.showSuccess('Created')} />
        <DefaultErrorView error={AppErrorFactory.forbiddenScope('No scope access')} />
        <ServeModal isOpen={true} title="Confirm Action" onClose={onCloseModal}>
          <p>Modal body</p>
        </ServeModal>
        <ServeDrawer isOpen={true} title="Details Drawer" onClose={onCloseDrawer}>
          <p>Drawer body</p>
        </ServeDrawer>
      </div>,
    );

    expect(screen.getByText(/You are offline/i)).toBeInTheDocument();
    expect(screen.getByText('Access Restricted')).toBeInTheDocument();
    expect(screen.getByText('Confirm Action')).toBeInTheDocument();
    expect(screen.getByText('Details Drawer')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Create' }));
    expect(screen.getByText('Created')).toBeInTheDocument();

    await user.keyboard('{Escape}');
    expect(onCloseModal).toHaveBeenCalled();
    expect(onCloseDrawer).toHaveBeenCalled();
  });
});

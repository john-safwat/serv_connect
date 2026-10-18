import type React from 'react';
import { Outlet } from 'react-router';
import { ServeOfflineBanner } from '../components/feedback/ServeOfflineBanner';
import styles from './AppShell.module.css';
import { AppSidebar } from './AppSidebar';
import { AppTopbar } from './AppTopbar';
import { useAppShellStore } from './useAppShellStore';

export function AppShell(): React.JSX.Element {
  const isSidebarCollapsed = useAppShellStore((s) => s.isSidebarCollapsed);
  const toggleSidebar = useAppShellStore((s) => s.toggleSidebar);

  return (
    <div className={styles.shell}>
      <AppSidebar isCollapsed={isSidebarCollapsed} />
      <div className={styles.mainArea}>
        <ServeOfflineBanner />
        <AppTopbar onToggleSidebar={toggleSidebar} />
        <main className={styles.workspace}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}

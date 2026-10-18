import type React from 'react';
import { useTranslation } from 'react-i18next';
import { NavLink } from 'react-router';
import { ServeAvatar } from '../components/primitives/ServeAvatar';
import { FeatureFlagService } from '../core/config/feature_flag_service';
import { useOrgLabels } from '../core/i18n/org_label_resolver';
import { usePermissions } from '../core/permissions/use_permissions';
import { AuthSession } from '../core/session/auth_session';
import { LocaleKeys } from '../generated/locale_keys.g';
import styles from './AppShell.module.css';
import { type NavGroupConfig, type NavItemConfig, SIDEBAR_NAV_GROUPS } from './nav_config';

export interface AppSidebarProps {
  readonly isCollapsed: boolean;
}

function isNavItemVisible(
  item: NavItemConfig,
  hasAnyScope: (perm: string) => boolean,
  isAuthenticated: boolean,
): boolean {
  if (item.featureModule && !FeatureFlagService.isEnabled(item.featureModule)) {
    return false;
  }
  if (!item.permissionKey || !isAuthenticated) return true;
  return hasAnyScope(item.permissionKey);
}

interface SidebarNavGroupViewProps {
  readonly group: NavGroupConfig;
  readonly isCollapsed: boolean;
  readonly hasAnyScope: (perm: string) => boolean;
  readonly isAuthenticated: boolean;
}

function SidebarNavGroupView({
  group,
  isCollapsed,
  hasAnyScope,
  isAuthenticated,
}: SidebarNavGroupViewProps): React.JSX.Element | null {
  const { t } = useTranslation();
  const visibleItems = group.items.filter((item) =>
    isNavItemVisible(item, hasAnyScope, isAuthenticated),
  );
  if (visibleItems.length === 0) return null;

  return (
    <div>
      {!isCollapsed ? <div className={styles.navGroupLabel}>{t(group.titleKey)}</div> : null}
      {visibleItems.map((item) => (
        <NavLink
          key={item.key}
          to={item.path}
          end={item.path === '/'}
          className={({ isActive }) =>
            `${styles.navItem ?? ''} ${isActive ? (styles.navItemActive ?? '') : ''}`.trim()
          }
        >
          <span>{t(item.labelKey)}</span>
          {!isCollapsed && item.badgeCount ? (
            <span className={styles.navCount}>{item.badgeCount}</span>
          ) : null}
        </NavLink>
      ))}
    </div>
  );
}

export function AppSidebar({ isCollapsed }: AppSidebarProps): React.JSX.Element {
  const { t } = useTranslation();
  const checker = usePermissions();
  const orgLabels = useOrgLabels();
  const isAuthenticated = AuthSession.isAuthenticated();
  const sideClass = `${styles.sidebar ?? ''} ${isCollapsed ? (styles.sidebarCollapsed ?? '') : ''}`.trim();

  return (
    <aside className={sideClass} aria-label={t(LocaleKeys.common_app_name)}>
      <div className={styles.brand}>
        <div className={styles.logoBox} aria-hidden="true">SC</div>
        {!isCollapsed ? (
          <div>
            <span className={styles.brandTitle}>
              Serve<span className={styles.brandAccent}>Connect</span>
            </span>
            <span className={styles.brandSub}>{t(LocaleKeys.common_app_subtitle)}</span>
          </div>
        ) : null}
      </div>
      <nav>
        {SIDEBAR_NAV_GROUPS.map((group) => (
          <SidebarNavGroupView
            key={group.groupKey}
            group={group}
            isCollapsed={isCollapsed}
            hasAnyScope={(p) => checker.hasAnyScope(p)}
            isAuthenticated={isAuthenticated}
          />
        ))}
      </nav>
      <div className={styles.sidebarFooter}>
        <ServeAvatar initials="SC" tone="gold" size="md" />
        {!isCollapsed ? <span className={styles.brandSub}>{orgLabels.servant}</span> : null}
      </div>
    </aside>
  );
}

import type React from 'react';
import { useTranslation } from 'react-i18next';
import { ServeBadge } from '../components/primitives/ServeBadge';
import { ServeButton } from '../components/primitives/ServeButton';
import { ServeIconButton } from '../components/primitives/ServeIconButton';
import { LocaleController } from '../core/i18n/locale_controller';
import { useOnlineStatus } from '../core/session/use_online_status';
import { LocaleKeys } from '../generated/locale_keys.g';
import styles from './AppShell.module.css';

export interface AppTopbarProps {
  readonly onToggleSidebar: () => void;
}

export function AppTopbar({ onToggleSidebar }: AppTopbarProps): React.JSX.Element {
  const { t, i18n } = useTranslation();
  const isOnline = useOnlineStatus();
  const currentLang = i18n.language === 'ar' ? 'ar' : 'en';
  const switchLabel = currentLang === 'en' ? 'العربية' : 'English';

  return (
    <header className={styles.topbar}>
      <div className={styles.topbarStart}>
        <ServeIconButton
          ariaLabel={t(LocaleKeys.common_toggle_sidebar)}
          onClick={onToggleSidebar}
        >
          ☰
        </ServeIconButton>
        <ServeBadge tone={isOnline ? 'green' : 'amber'}>
          {isOnline ? t(LocaleKeys.common_online_status) : t(LocaleKeys.common_offline_status)}
        </ServeBadge>
      </div>
      <div className={styles.topbarEnd}>
        <ServeButton
          variant="ghost"
          size="sm"
          aria-label={t(LocaleKeys.common_switch_language)}
          onClick={() => LocaleController.toggleLocale()}
        >
          {switchLabel}
        </ServeButton>
        <ServeIconButton
          ariaLabel={t(LocaleKeys.common_notifications)}
          hasNotificationDot
        >
          🔔
        </ServeIconButton>
      </div>
    </header>
  );
}

import type React from 'react';
import { useTranslation } from 'react-i18next';
import { useOnlineStatus } from '../../core/session/use_online_status';
import { LocaleKeys } from '../../generated/locale_keys.g';
import styles from './ServeFeedback.module.css';

export interface ServeOfflineBannerProps {
  readonly forceVisible?: boolean;
}

export function ServeOfflineBanner({
  forceVisible = false,
}: ServeOfflineBannerProps): React.JSX.Element | null {
  const { t } = useTranslation();
  const isOnline = useOnlineStatus();

  if (isOnline && !forceVisible) return null;

  return (
    <output className={styles.banner} aria-live="polite">
      <span aria-hidden="true">⚠</span>
      <span>{t(LocaleKeys.common_offline_banner)}</span>
    </output>
  );
}

import type React from 'react';
import { useTranslation } from 'react-i18next';
import { LocaleKeys } from '../../generated/locale_keys.g';
import { ServeButton } from '../primitives/ServeButton';
import styles from './ServeFeedback.module.css';

export interface ServeEmptyStateProps {
  readonly title?: string;
  readonly subtitle?: string;
  readonly actionLabel?: string;
  readonly onAction?: () => void;
}

export function ServeEmptyState({
  title,
  subtitle,
  actionLabel,
  onAction,
}: ServeEmptyStateProps): React.JSX.Element {
  const { t } = useTranslation();

  return (
    <div className={styles.stateBox}>
      <h3 className={styles.stateTitle}>{title ?? t(LocaleKeys.common_empty_title)}</h3>
      <p className={styles.stateBody}>{subtitle ?? t(LocaleKeys.common_empty_subtitle)}</p>
      {actionLabel && onAction ? (
        <ServeButton variant="primary" size="sm" onClick={onAction}>
          {actionLabel}
        </ServeButton>
      ) : null}
    </div>
  );
}

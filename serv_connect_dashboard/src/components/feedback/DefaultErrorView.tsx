import type React from 'react';
import { useTranslation } from 'react-i18next';
import { LocaleKeys } from '../../generated/locale_keys.g';
import type { AppError } from '../../network/errors';
import { ServeButton } from '../primitives/ServeButton';
import styles from './ServeFeedback.module.css';

export interface DefaultErrorViewProps {
  readonly error?: AppError;
  readonly onRetry?: () => void;
}

export function DefaultErrorView({ error, onRetry }: DefaultErrorViewProps): React.JSX.Element {
  const { t } = useTranslation();
  const isForbidden =
    error?.kind === 'ForbiddenScopeError' || error?.kind === 'FeatureDisabledError';
  const isNotFound = error?.kind === 'NotFoundError';

  const title = isForbidden
    ? t(LocaleKeys.errors_forbidden_title)
    : isNotFound
      ? t(LocaleKeys.errors_not_found_title)
      : t(LocaleKeys.errors_generic);
  const body = error?.message ?? t(LocaleKeys.errors_generic);

  return (
    <div className={styles.stateBox} role="alert">
      <div className={styles.iconCircle} aria-hidden="true">
        {isForbidden ? '403' : isNotFound ? '404' : '!'}
      </div>
      <h3 className={styles.stateTitle}>{title}</h3>
      <p className={styles.stateBody}>{body}</p>
      {onRetry && !isForbidden ? (
        <ServeButton variant="ghost" size="sm" onClick={onRetry}>
          {t(LocaleKeys.common_retry)}
        </ServeButton>
      ) : null}
    </div>
  );
}

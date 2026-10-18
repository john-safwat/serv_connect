import type React from 'react';
import { useTranslation } from 'react-i18next';
import { LocaleKeys } from '../../generated/locale_keys.g';
import styles from './ServeShimmer.module.css';

export function ServeCardShimmer(): React.JSX.Element {
  const { t } = useTranslation();

  return (
    <output className={styles.cardSkeleton} aria-label={t(LocaleKeys.common_loading)}>
      <div className={`${styles.shimmerBlock ?? ''} ${styles.lineSecondary ?? ''}`} />
      <div className={`${styles.shimmerBlock ?? ''} ${styles.linePrimary ?? ''}`} />
      <div className={`${styles.shimmerBlock ?? ''} ${styles.pill ?? ''}`} />
    </output>
  );
}

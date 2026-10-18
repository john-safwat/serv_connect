import type React from 'react';
import { useTranslation } from 'react-i18next';
import { LocaleKeys } from '../../generated/locale_keys.g';
import { ServeRowShimmer } from './ServeRowShimmer';
import styles from './ServeShimmer.module.css';

export interface ServeTableShimmerProps {
  readonly rows?: number;
}

export function ServeTableShimmer({ rows = 5 }: ServeTableShimmerProps): React.JSX.Element {
  const { t } = useTranslation();
  const indices = Array.from({ length: rows }, (_, idx) => idx);

  return (
    <output className={styles.tableSkeleton} aria-label={t(LocaleKeys.common_loading)}>
      {indices.map((idx) => (
        <ServeRowShimmer key={idx} />
      ))}
    </output>
  );
}

import type React from 'react';
import { useTranslation } from 'react-i18next';
import { LocaleKeys } from '../../generated/locale_keys.g';
import { ServeRowShimmer } from './ServeRowShimmer';
import styles from './ServeShimmer.module.css';

export interface ServeListShimmerProps {
  readonly rows?: number;
}

export function ServeListShimmer({ rows = 4 }: ServeListShimmerProps): React.JSX.Element {
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

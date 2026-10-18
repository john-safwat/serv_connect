import type React from 'react';
import styles from './ServeShimmer.module.css';

export interface ServeRowShimmerProps {
  readonly showAvatar?: boolean;
}

export function ServeRowShimmer({
  showAvatar = true,
}: ServeRowShimmerProps): React.JSX.Element {
  return (
    <div className={styles.row} aria-hidden="true">
      {showAvatar ? <div className={`${styles.shimmerBlock ?? ''} ${styles.circle ?? ''}`} /> : null}
      <div className={styles.lines}>
        <div className={`${styles.shimmerBlock ?? ''} ${styles.linePrimary ?? ''}`} />
        <div className={`${styles.shimmerBlock ?? ''} ${styles.lineSecondary ?? ''}`} />
      </div>
      <div className={`${styles.shimmerBlock ?? ''} ${styles.pill ?? ''}`} />
    </div>
  );
}

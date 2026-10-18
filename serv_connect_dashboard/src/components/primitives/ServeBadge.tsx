import type React from 'react';
import styles from './ServeBadge.module.css';

export type ServeBadgeTone = 'red' | 'gold' | 'green' | 'amber' | 'blue' | 'gray';

export interface ServeBadgeProps {
  readonly tone?: ServeBadgeTone;
  readonly showDot?: boolean;
  readonly children: React.ReactNode;
}

export function ServeBadge({
  tone = 'gray',
  showDot = true,
  children,
}: ServeBadgeProps): React.JSX.Element {
  return (
    <span className={`${styles.badge ?? ''} ${styles[tone] ?? ''}`.trim()}>
      {showDot ? <span className={styles.dot} aria-hidden="true" /> : null}
      <span>{children}</span>
    </span>
  );
}

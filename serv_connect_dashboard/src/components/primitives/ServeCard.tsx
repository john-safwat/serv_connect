import type React from 'react';
import styles from './ServeCard.module.css';

export interface ServeCardProps {
  readonly padded?: boolean;
  readonly surface?: 'ivory' | 'paper';
  readonly goldAccent?: boolean;
  readonly className?: string;
  readonly children: React.ReactNode;
}

export function ServeCard({
  padded = true,
  surface = 'ivory',
  goldAccent = false,
  className,
  children,
}: ServeCardProps): React.JSX.Element {
  const classes = [
    styles.card,
    surface === 'paper' ? styles.paper : '',
    padded ? styles.padded : '',
    goldAccent ? styles.goldAccent : '',
    className ?? '',
  ]
    .filter(Boolean)
    .join(' ');

  return <section className={classes}>{children}</section>;
}

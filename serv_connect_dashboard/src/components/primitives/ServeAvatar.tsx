import type React from 'react';
import styles from './ServeAvatar.module.css';

export type ServeAvatarTone = 'gold' | 'red' | 'green' | 'blue';
export type ServeAvatarSize = 'sm' | 'md' | 'lg';

export interface ServeAvatarProps {
  readonly initials: string;
  readonly imageUrl?: string;
  readonly alt?: string;
  readonly tone?: ServeAvatarTone;
  readonly size?: ServeAvatarSize;
}

export function ServeAvatar({
  initials,
  imageUrl,
  alt = '',
  tone = 'gold',
  size = 'md',
}: ServeAvatarProps): React.JSX.Element {
  const classes = `${styles.avatar ?? ''} ${styles[tone] ?? ''} ${styles[size] ?? ''}`.trim();

  return (
    <span className={classes} aria-label={alt || initials}>
      {imageUrl ? (
        <img src={imageUrl} alt={alt} loading="lazy" className={styles.img} />
      ) : (
        <span>{initials}</span>
      )}
    </span>
  );
}

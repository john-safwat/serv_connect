import type React from 'react';
import styles from './ServeIconButton.module.css';

export interface ServeIconButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  readonly ariaLabel: string;
  readonly hasNotificationDot?: boolean;
  readonly children: React.ReactNode;
}

export function ServeIconButton({
  ariaLabel,
  hasNotificationDot = false,
  className,
  type = 'button',
  children,
  ...rest
}: ServeIconButtonProps): React.JSX.Element {
  return (
    <button
      type={type}
      aria-label={ariaLabel}
      title={ariaLabel}
      className={`${styles.iconButton ?? ''} ${className ?? ''}`.trim()}
      {...rest}
    >
      {children}
      {hasNotificationDot ? <span className={styles.badgeDot} aria-hidden="true" /> : null}
    </button>
  );
}

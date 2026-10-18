import type React from 'react';
import styles from './ServeButton.module.css';

export type ServeButtonVariant = 'primary' | 'dark' | 'gold' | 'ghost' | 'soft';
export type ServeButtonSize = 'sm' | 'md' | 'lg';

export interface ServeButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  readonly variant?: ServeButtonVariant;
  readonly size?: ServeButtonSize;
  readonly isLoading?: boolean;
  readonly fullWidth?: boolean;
  readonly leadingIcon?: React.ReactNode;
}

export function ServeButton({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  fullWidth = false,
  leadingIcon,
  disabled,
  className,
  children,
  type = 'button',
  ...rest
}: ServeButtonProps): React.JSX.Element {
  const classes = [
    styles.button,
    styles[variant],
    styles[size],
    fullWidth ? styles.fullWidth : '',
    className ?? '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <button
      type={type}
      className={classes}
      disabled={disabled || isLoading}
      aria-busy={isLoading}
      {...rest}
    >
      {isLoading ? <span className={styles.spinner} aria-hidden="true" /> : leadingIcon}
      <span>{children}</span>
    </button>
  );
}

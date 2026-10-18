import type React from 'react';
import { useEffect, useId } from 'react';
import { useTranslation } from 'react-i18next';
import { LocaleKeys } from '../../generated/locale_keys.g';
import styles from './ServeDrawer.module.css';
import { ServeIconButton } from './ServeIconButton';

export interface ServeDrawerProps {
  readonly isOpen: boolean;
  readonly title: string;
  readonly onClose: () => void;
  readonly children: React.ReactNode;
}

export function ServeDrawer({
  isOpen,
  title,
  onClose,
  children,
}: ServeDrawerProps): React.JSX.Element | null {
  const { t } = useTranslation();
  const titleId = useId();

  useEffect(() => {
    if (!isOpen) return undefined;
    const handleKey = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className={styles.backdrop}
      role="presentation"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <dialog open aria-modal="true" aria-labelledby={titleId} className={styles.panel}>
        <div className={styles.header}>
          <h2 id={titleId} className={styles.title}>
            {title}
          </h2>
          <ServeIconButton ariaLabel={t(LocaleKeys.common_close)} onClick={onClose}>
            ✕
          </ServeIconButton>
        </div>
        <div className={styles.body}>{children}</div>
      </dialog>
    </div>
  );
}

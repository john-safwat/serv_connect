import type React from 'react';
import { useSyncExternalStore } from 'react';
import styles from './ServeFeedback.module.css';
import { Toaster, getToastSnapshot, subscribeToasts } from './toaster_store';

export function ToasterHost(): React.JSX.Element | null {
  const toasts = useSyncExternalStore(subscribeToasts, getToastSnapshot);
  if (toasts.length === 0) return null;

  return (
    <div className={styles.toastViewport} aria-live="polite">
      {toasts.map((item) => {
        const toneClass =
          item.tone === 'success'
            ? styles.toastSuccess
            : item.tone === 'error'
              ? styles.toastError
              : styles.toastWarning;
        return (
          <div key={item.id} className={`${styles.toastItem ?? ''} ${toneClass ?? ''}`.trim()}>
            <span>{item.message}</span>
            <button type="button" onClick={() => Toaster.dismiss(item.id)}>
              ✕
            </button>
          </div>
        );
      })}
    </div>
  );
}

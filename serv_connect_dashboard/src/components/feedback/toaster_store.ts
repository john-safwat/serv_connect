import { IdGenerator } from '../../core/validation/validation';

export type ToastTone = 'success' | 'error' | 'warning';

export interface ToastMessage {
  readonly id: string;
  readonly tone: ToastTone;
  readonly message: string;
}

let activeToasts: readonly ToastMessage[] = [];
const listeners = new Set<() => void>();

function notify(): void {
  for (const listener of listeners) {
    listener();
  }
}

export function subscribeToasts(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getToastSnapshot(): readonly ToastMessage[] {
  return activeToasts;
}

function pushToast(tone: ToastTone, message: string): string {
  const id = IdGenerator.newUuid();
  activeToasts = [...activeToasts, { id, tone, message }];
  notify();
  return id;
}

export const Toaster = {
  showSuccess(message: string): string {
    return pushToast('success', message);
  },
  showError(message: string): string {
    return pushToast('error', message);
  },
  showWarning(message: string): string {
    return pushToast('warning', message);
  },
  dismiss(id: string): void {
    activeToasts = activeToasts.filter((t) => t.id !== id);
    notify();
  },
  clearAll(): void {
    activeToasts = [];
    notify();
  },
};

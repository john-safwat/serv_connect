import { AppEventBus } from '../event_bus/app_event_bus';

class ConnectivityWatcherImpl {
  private online = typeof navigator !== 'undefined' ? navigator.onLine : true;
  private started = false;
  private readonly handleOnline = (): void => this.updateStatus(true);
  private readonly handleOffline = (): void => this.updateStatus(false);

  public start(): void {
    if (this.started || typeof window === 'undefined') return;
    this.started = true;
    this.online = navigator.onLine;
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('offline', this.handleOffline);
  }

  public stop(): void {
    if (!this.started || typeof window === 'undefined') return;
    this.started = false;
    window.removeEventListener('online', this.handleOnline);
    window.removeEventListener('offline', this.handleOffline);
  }

  public isOnline(): boolean {
    return this.online;
  }

  public setOnlineForTesting(isOnline: boolean): void {
    this.updateStatus(isOnline);
  }

  private updateStatus(nextOnline: boolean): void {
    if (this.online === nextOnline) return;
    this.online = nextOnline;
    AppEventBus.emit({ type: 'CONNECTIVITY_CHANGED', isOnline: nextOnline });
  }
}

export const ConnectivityWatcher = new ConnectivityWatcherImpl();

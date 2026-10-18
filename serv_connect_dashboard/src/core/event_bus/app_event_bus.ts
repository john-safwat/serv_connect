export interface ScopeRevokedEvent {
  readonly type: 'SCOPE_REVOKED';
  readonly scopeType?: string;
  readonly targetId?: string;
}

export interface ConnectivityChangedEvent {
  readonly type: 'CONNECTIVITY_CHANGED';
  readonly isOnline: boolean;
}

export type AppEvent = ScopeRevokedEvent | ConnectivityChangedEvent;
export type AppEventListener = (event: AppEvent) => void;

class AppEventBusImpl {
  private readonly listeners = new Set<AppEventListener>();

  public subscribe(listener: AppEventListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  public emit(event: AppEvent): void {
    for (const listener of this.listeners) {
      listener(event);
    }
  }

  public clearForTesting(): void {
    this.listeners.clear();
  }
}

export const AppEventBus = new AppEventBusImpl();

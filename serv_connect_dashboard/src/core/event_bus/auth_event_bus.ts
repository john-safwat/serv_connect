export interface LoginRequiredEvent {
  readonly type: 'LOGIN_REQUIRED';
  readonly reason: 'UNAUTHORIZED' | 'REFRESH_FAILED' | 'LOGOUT';
}

export interface IdleLockEvent {
  readonly type: 'IDLE_LOCK';
  readonly idleMinutes: number;
}

export type AuthEvent = LoginRequiredEvent | IdleLockEvent;
export type AuthEventListener = (event: AuthEvent) => void;

class AuthEventBusImpl {
  private readonly listeners = new Set<AuthEventListener>();

  public subscribe(listener: AuthEventListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  public emit(event: AuthEvent): void {
    for (const listener of this.listeners) {
      listener(event);
    }
  }

  public clearForTesting(): void {
    this.listeners.clear();
  }
}

export const AuthEventBus = new AuthEventBusImpl();

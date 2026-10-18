import { AuthEventBus } from '../event_bus/auth_event_bus';
import { AuthSession } from './auth_session';

export interface IdleLockOptions {
  readonly timeoutMinutes: number;
  readonly onLock?: () => void;
  readonly nowProvider?: () => number;
  readonly checkIntervalMs?: number;
}

const ACTIVITY_EVENTS: readonly (keyof WindowEventMap)[] = [
  'pointerdown',
  'keydown',
  'scroll',
];

export class IdleLockWatcher {
  private readonly timeoutMs: number;
  private readonly onLock?: () => void;
  private readonly now: () => number;
  private readonly checkIntervalMs: number;
  private targetTimestampMs: number;
  private intervalId: ReturnType<typeof setInterval> | null = null;
  private readonly boundRecordActivity: () => void;

  public constructor(options: IdleLockOptions) {
    this.timeoutMs = Math.max(1, options.timeoutMinutes) * 60 * 1000;
    this.onLock = options.onLock;
    this.now = options.nowProvider ?? (() => Date.now());
    this.checkIntervalMs = options.checkIntervalMs ?? 1000;
    this.targetTimestampMs = this.now() + this.timeoutMs;
    this.boundRecordActivity = () => this.recordActivity();
  }

  public start(): void {
    this.stop();
    this.targetTimestampMs = this.now() + this.timeoutMs;
    if (typeof window !== 'undefined') {
      for (const evt of ACTIVITY_EVENTS) {
        window.addEventListener(evt, this.boundRecordActivity, { passive: true });
      }
    }
    this.intervalId = setInterval(() => this.evaluateTick(), this.checkIntervalMs);
  }

  public stop(): void {
    if (this.intervalId !== null) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    if (typeof window !== 'undefined') {
      for (const evt of ACTIVITY_EVENTS) {
        window.removeEventListener(evt, this.boundRecordActivity);
      }
    }
  }

  public recordActivity(): void {
    this.targetTimestampMs = this.now() + this.timeoutMs;
  }

  public getRemainingMs(): number {
    return Math.max(0, this.targetTimestampMs - this.now());
  }

  public evaluateTick(): boolean {
    if (this.getRemainingMs() > 0) return false;
    this.stop();
    AuthSession.lockSession();
    this.onLock?.();
    AuthEventBus.emit({
      type: 'IDLE_LOCK',
      idleMinutes: Math.round(this.timeoutMs / 60000),
    });
    return true;
  }
}

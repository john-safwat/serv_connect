import { AppEventBus } from '../core/event_bus/app_event_bus';
import { AuthEventBus } from '../core/event_bus/auth_event_bus';
import { LocaleController } from '../core/i18n/locale_controller';
import { AppLogger } from '../core/logger/app_logger';
import { AuthSession } from '../core/session/auth_session';
import type { BaseApiResponse } from './base_api_response';

const PUBLIC_AUTH_PATHS: ReadonlySet<string> = new Set([
  '/api/v1/auth/login',
  '/api/v1/auth/otp/verify',
  '/api/v1/auth/otp/resend',
  '/api/v1/auth/refresh',
  '/api/v1/auth/invitations/accept',
]);

const NO_REFRESH_PATHS: ReadonlySet<string> = new Set([
  '/api/v1/auth/login',
  '/api/v1/auth/refresh',
  '/api/v1/auth/logout',
]);

export interface HttpRequestOptions {
  readonly method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  readonly path: string;
  readonly body?: unknown;
  readonly headers?: Readonly<Record<string, string>>;
  readonly idempotencyKey?: string;
}

export interface RefreshTokenPayload {
  readonly accessToken: string;
}

export function applyInterceptors(path: string, customHeaders?: Readonly<Record<string, string>>, idempotencyKey?: string): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: 'application/json',
    'Accept-Language': LocaleController.getLocale(),
    ...customHeaders,
  };
  const token = AuthSession.getAccessToken();
  if (token && !PUBLIC_AUTH_PATHS.has(path)) {
    headers.Authorization = `Bearer ${token}`;
  }
  if (idempotencyKey) {
    headers['Idempotency-Key'] = idempotencyKey;
  }
  return headers;
}

export class RefreshMutexInterceptor {
  private inFlightRefresh: Promise<boolean> | null = null;
  private readonly baseUrlProvider: () => string;
  private readonly onUnrecoverableAuthFailure?: () => void;

  public constructor(baseUrlProvider: () => string, onUnrecoverableAuthFailure?: () => void) {
    this.baseUrlProvider = baseUrlProvider;
    this.onUnrecoverableAuthFailure = onUnrecoverableAuthFailure;
  }

  public canAttemptRefresh(path: string): boolean {
    return !NO_REFRESH_PATHS.has(path);
  }

  public async refreshOrFail(): Promise<boolean> {
    if (!this.inFlightRefresh) {
      this.inFlightRefresh = this.executeRefresh().finally(() => {
        this.inFlightRefresh = null;
      });
    }
    return this.inFlightRefresh;
  }

  private async executeRefresh(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrlProvider()}/api/v1/auth/refresh`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          Accept: 'application/json',
          'Accept-Language': LocaleController.getLocale(),
        },
      });
      if (!response.ok) {
        this.handleRefreshFailure();
        return false;
      }
      const envelope = (await response.json()) as BaseApiResponse<RefreshTokenPayload>;
      if (!envelope.data?.accessToken) {
        this.handleRefreshFailure();
        return false;
      }
      AuthSession.updateAccessToken(envelope.data.accessToken);
      return true;
    } catch {
      this.handleRefreshFailure();
      return false;
    }
  }

  private handleRefreshFailure(): void {
    AuthSession.clear();
    this.onUnrecoverableAuthFailure?.();
    AuthEventBus.emit({ type: 'LOGIN_REQUIRED', reason: 'REFRESH_FAILED' });
  }
}

export function notifyScopeRevokedIfNeeded(statusCode: number, code?: string): void {
  if (statusCode === 403 && code === 'ERR_FORBIDDEN_SCOPE') {
    AppEventBus.emit({ type: 'SCOPE_REVOKED' });
  }
}

export function logSafeHttpStatus(method: string, path: string, status: number): void {
  const sanitizedPath = path.split('?')[0] ?? path;
  AppLogger.d('HttpClient', `${method} ${sanitizedPath} -> ${status}`);
}

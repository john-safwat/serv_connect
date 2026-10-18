import { AppEnvironment } from '../core/config/app_environment';
import { IdGenerator } from '../core/validation/validation';
import type { BaseApiResponse } from './base_api_response';
import { ErrorParser } from './error_parser';
import {
  type HttpRequestOptions,
  RefreshMutexInterceptor,
  applyInterceptors,
  logSafeHttpStatus,
  notifyScopeRevokedIfNeeded,
} from './interceptors';

export interface HttpClientConfig {
  readonly baseUrlProvider?: () => string;
  readonly onUnrecoverableAuthFailure?: () => void;
}

async function parseJsonSafely<T>(response: Response): Promise<BaseApiResponse<T> | undefined> {
  try {
    return (await response.json()) as BaseApiResponse<T>;
  } catch {
    return undefined;
  }
}

export class HttpClient {
  private readonly baseUrlProvider: () => string;
  private readonly refreshMutex: RefreshMutexInterceptor;

  public constructor(config: HttpClientConfig = {}) {
    this.baseUrlProvider = config.baseUrlProvider ?? (() => AppEnvironment.config.apiBaseUrl);
    this.refreshMutex = new RefreshMutexInterceptor(
      this.baseUrlProvider,
      config.onUnrecoverableAuthFailure,
    );
  }

  public async request<T>(options: HttpRequestOptions): Promise<T> {
    return this.executeWithRetry<T>(options, false);
  }

  public async get<T>(path: string): Promise<T> {
    return this.request<T>({ method: 'GET', path });
  }

  public async post<T>(path: string, body?: unknown, idempotencyKey?: string): Promise<T> {
    return this.request<T>({
      method: 'POST',
      path,
      body,
      idempotencyKey: idempotencyKey ?? IdGenerator.newUuid(),
    });
  }

  public async put<T>(path: string, body?: unknown, idempotencyKey?: string): Promise<T> {
    return this.request<T>({
      method: 'PUT',
      path,
      body,
      idempotencyKey: idempotencyKey ?? IdGenerator.newUuid(),
    });
  }

  public async delete<T>(path: string): Promise<T> {
    return this.request<T>({ method: 'DELETE', path });
  }

  private async executeWithRetry<T>(options: HttpRequestOptions, isRetry: boolean): Promise<T> {
    const method = options.method ?? 'GET';
    const headers = applyInterceptors(options.path, options.headers, options.idempotencyKey);
    if (options.body !== undefined) {
      headers['Content-Type'] = 'application/json';
    }
    const response = await fetch(`${this.baseUrlProvider()}${options.path}`, {
      method,
      headers,
      credentials: 'include',
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });
    logSafeHttpStatus(method, options.path, response.status);
    if (response.status === 401 && !isRetry && this.refreshMutex.canAttemptRefresh(options.path)) {
      const refreshed = await this.refreshMutex.refreshOrFail();
      if (refreshed) {
        return this.executeWithRetry<T>(options, true);
      }
    }
    const envelope = await parseJsonSafely<T>(response);
    if (!response.ok) {
      notifyScopeRevokedIfNeeded(response.status, envelope?.code);
      throw ErrorParser.parseHttpStatus(response.status, envelope);
    }
    if (envelope && 'data' in envelope && envelope.data !== undefined) {
      return envelope.data;
    }
    return envelope as T;
  }
}

export const sharedHttpClient = new HttpClient();

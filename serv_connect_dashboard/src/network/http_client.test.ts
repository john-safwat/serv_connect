import { HttpResponse, http } from 'msw';
import { describe, expect, it, vi } from 'vitest';
import { AppEventBus } from '../core/event_bus/app_event_bus';
import { AuthEventBus } from '../core/event_bus/auth_event_bus';
import { LocaleController } from '../core/i18n/locale_controller';
import { AuthSession } from '../core/session/auth_session';
import { mswServer } from '../test/msw_server';
import { ErrorParser } from './error_parser';
import { HttpClient } from './http_client';
import { Resources } from './resources';
import { safeCall } from './safe_call';

const BASE_URL = 'https://api.serveconnect.test';

describe('HttpClient, Interceptors, ErrorParser, safeCall & Resources', () => {
  it('acceptLanguageAndAuthInterceptors_attachLocaleAndBearerToken', async () => {
    LocaleController.setLocale('ar');
    AuthSession.setSession({
      accessToken: 'initial-access-token',
      userId: 'u-1',
      orgId: 'o-1',
      roleAssignments: [],
    });

    let capturedLang = '';
    let capturedAuth = '';
    mswServer.use(
      http.get(`${BASE_URL}/api/v1/groups`, ({ request }) => {
        capturedLang = request.headers.get('Accept-Language') ?? '';
        capturedAuth = request.headers.get('Authorization') ?? '';
        return HttpResponse.json({
          data: [{ id: 'g-1' }],
          message: 'OK',
          code: 'SUCCESS',
        });
      }),
    );

    const client = new HttpClient({ baseUrlProvider: () => BASE_URL });
    const result = await safeCall(() => client.get<readonly { id: string }[]>('/api/v1/groups'));
    expect(result.kind).toBe('success');
    expect(capturedLang).toBe('ar');
    expect(capturedAuth).toBe('Bearer initial-access-token');
  });

  it('refreshMutexInterceptor_concurrent401Responses_triggersSingleRefreshCall', async () => {
    AuthSession.setSession({
      accessToken: 'expired-token',
      userId: 'u-1',
      orgId: 'o-1',
      roleAssignments: [],
    });

    let refreshCallCount = 0;
    mswServer.use(
      http.post(`${BASE_URL}/api/v1/auth/refresh`, async () => {
        refreshCallCount += 1;
        return HttpResponse.json({
          data: { accessToken: 'fresh-access-token' },
          message: 'Refreshed',
          code: 'SUCCESS',
        });
      }),
      http.get(`${BASE_URL}/api/v1/tasks`, ({ request }) => {
        const auth = request.headers.get('Authorization');
        if (auth !== 'Bearer fresh-access-token') {
          return HttpResponse.json({ message: 'Expired', code: 'ERR_UNAUTHORIZED' }, { status: 401 });
        }
        return HttpResponse.json({ data: { ok: true }, message: 'OK', code: 'SUCCESS' });
      }),
    );

    const client = new HttpClient({ baseUrlProvider: () => BASE_URL });
    const [r1, r2, r3] = await Promise.all([
      client.get<{ ok: boolean }>('/api/v1/tasks'),
      client.get<{ ok: boolean }>('/api/v1/tasks'),
      client.get<{ ok: boolean }>('/api/v1/tasks'),
    ]);

    expect(refreshCallCount).toBe(1);
    expect(r1.ok).toBe(true);
    expect(r2.ok).toBe(true);
    expect(r3.ok).toBe(true);
    expect(AuthSession.getAccessToken()).toBe('fresh-access-token');
  });

  it('refreshMutexInterceptor_401OnRefresh_clearsSessionAndEmitsLoginRequired', async () => {
    const onClearCache = vi.fn();
    const authEvents: string[] = [];
    AuthEventBus.subscribe((e) => authEvents.push(e.type));
    AuthSession.setSession({
      accessToken: 'expired-token',
      userId: 'u-1',
      orgId: 'o-1',
      roleAssignments: [],
    });

    mswServer.use(
      http.post(`${BASE_URL}/api/v1/auth/refresh`, () =>
        HttpResponse.json({ message: 'Revoked', code: 'ERR_REFRESH_EXPIRED' }, { status: 401 }),
      ),
      http.get(`${BASE_URL}/api/v1/members`, () =>
        HttpResponse.json({ message: 'Unauthorized', code: 'ERR_UNAUTHORIZED' }, { status: 401 }),
      ),
    );

    const client = new HttpClient({
      baseUrlProvider: () => BASE_URL,
      onUnrecoverableAuthFailure: onClearCache,
    });
    const res = await safeCall(() => client.get('/api/v1/members'));
    expect(res.kind).toBe('failure');
    if (res.kind === 'failure') {
      expect(res.error.kind).toBe('LoginRequired');
    }
    expect(AuthSession.getAccessToken()).toBeNull();
    expect(onClearCache).toHaveBeenCalledTimes(1);
    expect(authEvents).toContain('LOGIN_REQUIRED');
  });

  it('errorParserAndResources_handles403ScopeRevoked400FieldErrorsAndPreservesCachedData', async () => {
    const appEvents: string[] = [];
    AppEventBus.subscribe((e) => appEvents.push(e.type));

    mswServer.use(
      http.post(`${BASE_URL}/api/v1/stages`, () =>
        HttpResponse.json(
          { message: 'Forbidden scope', code: 'ERR_FORBIDDEN_SCOPE' },
          { status: 403 },
        ),
      ),
    );

    const client = new HttpClient({ baseUrlProvider: () => BASE_URL });
    const res = await safeCall(() => client.post('/api/v1/stages', { name: 'Primary' }));
    expect(res.kind).toBe('failure');
    if (res.kind === 'failure') {
      expect(res.error.kind).toBe('ForbiddenScopeError');
    }
    expect(appEvents).toContain('SCOPE_REVOKED');

    const err400 = ErrorParser.parseHttpStatus(400, {
      message: 'Validation failed',
      code: 'ERR_VALIDATION',
      fieldErrors: { email: 'Invalid email' },
    });
    expect(err400.kind).toBe('ServerError');

    const loadingWithData = Resources.loading(['cached-row']);
    expect(loadingWithData.isLoading).toBe(true);
    expect(loadingWithData.data).toEqual(['cached-row']);

    const failureWithData = Resources.failure(err400, undefined, ['cached-row']);
    expect(failureWithData.isError).toBe(true);
    expect(failureWithData.data).toEqual(['cached-row']);
  });
});

import { describe, expect, it } from 'vitest';
import { AppEnvironment } from '../config/app_environment';
import { AppFormatters, asLocalDateString, asLocalTimeString } from '../format/app_formatters';
import { LocaleController } from '../i18n/locale_controller';
import { OrgLabelResolver, useOrgLabels } from '../i18n/org_label_resolver';
import { assertNever } from '../validation/assert_never';
import { IdGenerator, Validation } from '../validation/validation';
import { AppLogger, type LogEntry, redactMetadata } from './app_logger';
import { renderHook } from '@testing-library/react';

describe('AppLogger, AppFormatters, Validation & i18n helpers', () => {
  it('redactMetadata_sensitiveKeys_redactsRecursively', () => {
    const clean = redactMetadata({
      memberId: '00000000-0000-4000-8000-000000000001',
      phone: '+201000000000',
      nested: { pastoralNote: 'private', count: 3 },
    });
    expect(clean?.memberId).toBe('00000000-0000-4000-8000-000000000001');
    expect(clean?.phone).toBe('[REDACTED]');
    const nested = (clean?.nested ?? {}) as Record<string, unknown>;
    expect(nested.pastoralNote).toBe('[REDACTED]');
    expect(nested.count).toBe(3);
  });

  it('appLogger_inDev_emitsRedactedEntries_andIsNoopInProd', () => {
    const entries: LogEntry[] = [];
    AppLogger.setSinkForTesting((e) => entries.push(e));
    AppLogger.d('Test', 'debug msg', { token: 'secret' });
    AppLogger.i('Test', 'info msg');
    AppLogger.w('Test', 'warn msg');
    AppLogger.e('Test', 'error msg');
    expect(entries).toHaveLength(4);
    expect(entries[0]?.metadata?.token).toBe('[REDACTED]');

    AppEnvironment.assertConfigured({
      VITE_API_BASE_URL: 'https://prod.serveconnect.org',
      VITE_ENV_NAME: 'prod',
      VITE_DEFAULT_LOCALE: 'en',
      VITE_IDLE_TIMEOUT_MINUTES: '15',
    });
    AppLogger.e('Test', 'should not log in prod');
    expect(entries).toHaveLength(4);
    AppLogger.setSinkForTesting(null);
  });

  it('appFormatters_formatsUtcInstantsLocalDatesAndNumbers_inEnAndAr', () => {
    const localDate = asLocalDateString('2026-10-18');
    const localTime = asLocalTimeString('18:30');
    expect(localTime).toBe('18:30');
    expect(AppFormatters.formatLocalDate(localDate, 'en')).toContain('2026');
    expect(AppFormatters.formatInstantDate('2026-10-18T15:00:00Z', 'en')).toContain('2026');
    expect(AppFormatters.formatInstantDateTime('2026-10-18T15:00:00Z', 'ar')).toBeTruthy();
    expect(AppFormatters.formatNumber(1250, 'en')).toBe('1,250');
    expect(AppFormatters.formatPercent(92, 'en')).toBe('92%');
    expect(AppFormatters.formatRelativeMinutes(-5, 'en')).toContain('5');
    expect(AppFormatters.formatRelativeDays(-2, 'en')).toContain('2');
    expect(() => asLocalDateString('18-10-2026')).toThrow();
    expect(() => asLocalTimeString('9:00')).toThrow();
    expect(() => AppFormatters.formatInstantDate('invalid', 'en')).toThrow();
  });

  it('validationSchemas_enforceEmailPhonePasswordOtpAndUuid', () => {
    expect(Validation.requiredTextSchema.safeParse('  ').success).toBe(false);
    expect(Validation.emailSchema.safeParse('servant@church.org').success).toBe(true);
    expect(Validation.emailSchema.safeParse('bad-email').success).toBe(false);
    expect(Validation.phoneSchema.safeParse('+201234567890').success).toBe(true);
    expect(Validation.phoneSchema.safeParse('abc').success).toBe(false);
    expect(Validation.passwordSchema.safeParse('short').success).toBe(false);
    expect(Validation.passwordSchema.safeParse('long-enough-pass').success).toBe(true);
    expect(Validation.otpSchema.safeParse('123456').success).toBe(true);
    expect(Validation.uuidSchema.safeParse(IdGenerator.newUuid()).success).toBe(true);
    expect(() => assertNever('unexpected' as never)).toThrow();
  });

  it('localeControllerAndOrgLabelResolver_switchRtlAndOverrideTerms', () => {
    LocaleController.setLocale('ar');
    expect(LocaleController.getLocale()).toBe('ar');
    expect(LocaleController.getDirection()).toBe('rtl');
    expect(document.documentElement.dir).toBe('rtl');
    expect(document.documentElement.lang).toBe('ar');

    LocaleController.toggleLocale();
    expect(LocaleController.getLocale()).toBe('en');
    expect(document.documentElement.dir).toBe('ltr');

    OrgLabelResolver.setOverrides({ servant: 'Mentor', stage: 'Grade Level' });
    const { result } = renderHook(() => useOrgLabels());
    expect(result.current.servant).toBe('Mentor');
    expect(result.current.stage).toBe('Grade Level');
  });
});

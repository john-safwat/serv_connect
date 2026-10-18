import type { SupportedLocale } from '../config/app_environment';

export type LocalDateString = string & { readonly __brand: 'LocalDateString' };
export type LocalTimeString = string & { readonly __brand: 'LocalTimeString' };

const LOCAL_DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;
const LOCAL_TIME_REGEX = /^\d{2}:\d{2}$/;

export function asLocalDateString(value: string): LocalDateString {
  if (!LOCAL_DATE_REGEX.test(value)) {
    throw new Error(`Invalid LocalDateString format: "${value}". Expected YYYY-MM-DD.`);
  }
  return value as LocalDateString;
}

export function asLocalTimeString(value: string): LocalTimeString {
  if (!LOCAL_TIME_REGEX.test(value)) {
    throw new Error(`Invalid LocalTimeString format: "${value}". Expected HH:mm.`);
  }
  return value as LocalTimeString;
}

function parseInstant(isoUtc: string): Date {
  const date = new Date(isoUtc);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid ISO-8601 instant: "${isoUtc}"`);
  }
  return date;
}

export const AppFormatters = {
  formatInstantDate(isoUtc: string, locale: SupportedLocale, orgTimeZone = 'Africa/Cairo'): string {
    const date = parseInstant(isoUtc);
    return new Intl.DateTimeFormat(locale, {
      timeZone: orgTimeZone,
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    }).format(date);
  },

  formatInstantDateTime(isoUtc: string, locale: SupportedLocale, orgTimeZone = 'Africa/Cairo'): string {
    const date = parseInstant(isoUtc);
    return new Intl.DateTimeFormat(locale, {
      timeZone: orgTimeZone,
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  },

  formatLocalDate(localDate: LocalDateString, locale: SupportedLocale): string {
    const parts = localDate.split('-').map(Number);
    const year = parts[0] ?? 2000;
    const month = (parts[1] ?? 1) - 1;
    const day = parts[2] ?? 1;
    const utcMidday = new Date(Date.UTC(year, month, day, 12, 0, 0));
    return new Intl.DateTimeFormat(locale, {
      timeZone: 'UTC',
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    }).format(utcMidday);
  },

  formatNumber(value: number, locale: SupportedLocale): string {
    return new Intl.NumberFormat(locale).format(value);
  },

  formatPercent(ratioZeroToOneHundred: number, locale: SupportedLocale): string {
    return new Intl.NumberFormat(locale, {
      style: 'percent',
      maximumFractionDigits: 1,
    }).format(ratioZeroToOneHundred / 100);
  },

  formatRelativeMinutes(minutesDiff: number, locale: SupportedLocale): string {
    return new Intl.RelativeTimeFormat(locale, { numeric: 'auto' }).format(minutesDiff, 'minute');
  },

  formatRelativeDays(daysDiff: number, locale: SupportedLocale): string {
    return new Intl.RelativeTimeFormat(locale, { numeric: 'auto' }).format(daysDiff, 'day');
  },
};

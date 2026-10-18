import type { SupportedLocale } from '../config/app_environment';
import { i18n, initI18n } from './i18n';

const LOCALE_STORAGE_KEY = 'serve_locale';
export type LayoutDirection = 'ltr' | 'rtl';

function readStoredLocale(): SupportedLocale | null {
  try {
    const raw = window.localStorage.getItem(LOCALE_STORAGE_KEY);
    if (raw === 'en' || raw === 'ar') return raw;
    return null;
  } catch {
    return null;
  }
}

function writeStoredLocale(locale: SupportedLocale): void {
  try {
    window.localStorage.setItem(LOCALE_STORAGE_KEY, locale);
  } catch {
    // Ignore storage quota/privacy mode errors
  }
}

export function applyDocumentLocale(locale: SupportedLocale): LayoutDirection {
  const dir: LayoutDirection = locale === 'ar' ? 'rtl' : 'ltr';
  if (typeof document !== 'undefined') {
    document.documentElement.lang = locale;
    document.documentElement.dir = dir;
  }
  return dir;
}

let activeLocale: SupportedLocale = 'en';

export const LocaleController = {
  initialize(defaultLocale: SupportedLocale = 'en'): SupportedLocale {
    const resolved = readStoredLocale() ?? defaultLocale;
    activeLocale = resolved;
    initI18n(resolved);
    void i18n.changeLanguage(resolved);
    applyDocumentLocale(resolved);
    return resolved;
  },

  getLocale(): SupportedLocale {
    return activeLocale;
  },

  getDirection(): LayoutDirection {
    return activeLocale === 'ar' ? 'rtl' : 'ltr';
  },

  setLocale(nextLocale: SupportedLocale): void {
    activeLocale = nextLocale;
    writeStoredLocale(nextLocale);
    initI18n(nextLocale);
    void i18n.changeLanguage(nextLocale);
    applyDocumentLocale(nextLocale);
  },

  toggleLocale(): SupportedLocale {
    const next: SupportedLocale = activeLocale === 'en' ? 'ar' : 'en';
    this.setLocale(next);
    return next;
  },
};

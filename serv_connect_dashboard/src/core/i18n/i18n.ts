import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import arCommon from '../../locales/ar/common.json';
import arErrors from '../../locales/ar/errors.json';
import arNav from '../../locales/ar/nav.json';
import arValidation from '../../locales/ar/validation.json';
import enCommon from '../../locales/en/common.json';
import enErrors from '../../locales/en/errors.json';
import enNav from '../../locales/en/nav.json';
import enValidation from '../../locales/en/validation.json';
import type { SupportedLocale } from '../config/app_environment';

export const resources = {
  en: {
    common: enCommon,
    nav: enNav,
    errors: enErrors,
    validation: enValidation,
  },
  ar: {
    common: arCommon,
    nav: arNav,
    errors: arErrors,
    validation: arValidation,
  },
} as const;

let initialized = false;

export function initI18n(defaultLocale: SupportedLocale = 'en'): typeof i18n {
  if (initialized) return i18n;
  void i18n.use(initReactI18next).init({
    resources,
    lng: defaultLocale,
    fallbackLng: 'en',
    defaultNS: 'common',
    ns: ['common', 'nav', 'errors', 'validation'],
    interpolation: {
      escapeValue: false,
    },
  });
  initialized = true;
  return i18n;
}

export { i18n };

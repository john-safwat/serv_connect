export type EnvName = 'dev' | 'staging' | 'prod';
export type SupportedLocale = 'en' | 'ar';

export interface AppEnvironmentConfig {
  readonly apiBaseUrl: string;
  readonly envName: EnvName;
  readonly defaultLocale: SupportedLocale;
  readonly idleTimeoutMinutes: number;
}

export interface RawEnvMap {
  readonly VITE_API_BASE_URL?: string;
  readonly VITE_ENV_NAME?: string;
  readonly VITE_DEFAULT_LOCALE?: string;
  readonly VITE_IDLE_TIMEOUT_MINUTES?: string;
}

function isMissingOrPlaceholder(val: string | undefined): boolean {
  if (!val) return true;
  const trimmed = val.trim();
  return trimmed.length === 0 || trimmed.startsWith('__');
}

function parseEnvName(raw: string | undefined): EnvName {
  if (raw === 'dev' || raw === 'staging' || raw === 'prod') return raw;
  throw new Error(`Invalid VITE_ENV_NAME: "${raw ?? ''}". Expected dev, staging, or prod.`);
}

function parseDefaultLocale(raw: string | undefined): SupportedLocale {
  if (raw === 'en' || raw === 'ar') return raw;
  throw new Error(`Invalid VITE_DEFAULT_LOCALE: "${raw ?? ''}". Expected en or ar.`);
}

function parseIdleTimeout(raw: string | undefined): number {
  const num = Number(raw);
  if (!Number.isFinite(num) || num <= 0) {
    throw new Error(`Invalid VITE_IDLE_TIMEOUT_MINUTES: "${raw ?? ''}". Expected positive number.`);
  }
  return num;
}

function validateApiBaseUrl(raw: string | undefined, envName: EnvName): string {
  if (isMissingOrPlaceholder(raw)) {
    throw new Error('Missing or placeholder VITE_API_BASE_URL.');
  }
  const url = (raw ?? '').trim().replace(/\/+$/, '');
  if ((envName === 'staging' || envName === 'prod') && !url.startsWith('https://')) {
    throw new Error(`VITE_API_BASE_URL must use https:// in ${envName}.`);
  }
  return url;
}

export function parseAppEnvironment(raw: RawEnvMap): AppEnvironmentConfig {
  if (isMissingOrPlaceholder(raw.VITE_ENV_NAME)) {
    throw new Error('Missing or placeholder VITE_ENV_NAME.');
  }
  if (isMissingOrPlaceholder(raw.VITE_DEFAULT_LOCALE)) {
    throw new Error('Missing or placeholder VITE_DEFAULT_LOCALE.');
  }
  if (isMissingOrPlaceholder(raw.VITE_IDLE_TIMEOUT_MINUTES)) {
    throw new Error('Missing or placeholder VITE_IDLE_TIMEOUT_MINUTES.');
  }
  const envName = parseEnvName(raw.VITE_ENV_NAME?.trim());
  return {
    apiBaseUrl: validateApiBaseUrl(raw.VITE_API_BASE_URL, envName),
    envName,
    defaultLocale: parseDefaultLocale(raw.VITE_DEFAULT_LOCALE?.trim()),
    idleTimeoutMinutes: parseIdleTimeout(raw.VITE_IDLE_TIMEOUT_MINUTES?.trim()),
  };
}

let cachedConfig: AppEnvironmentConfig | null = null;

function readViteImportMetaEnv(): RawEnvMap {
  return {
    VITE_API_BASE_URL: import.meta.env.VITE_API_BASE_URL as string | undefined,
    VITE_ENV_NAME: import.meta.env.VITE_ENV_NAME as string | undefined,
    VITE_DEFAULT_LOCALE: import.meta.env.VITE_DEFAULT_LOCALE as string | undefined,
    VITE_IDLE_TIMEOUT_MINUTES: import.meta.env.VITE_IDLE_TIMEOUT_MINUTES as string | undefined,
  };
}

export const AppEnvironment = {
  assertConfigured(overrideEnv?: RawEnvMap): AppEnvironmentConfig {
    const config = parseAppEnvironment(overrideEnv ?? readViteImportMetaEnv());
    cachedConfig = config;
    return config;
  },
  get config(): AppEnvironmentConfig {
    if (!cachedConfig) {
      cachedConfig = parseAppEnvironment(readViteImportMetaEnv());
    }
    return cachedConfig;
  },
  resetForTesting(): void {
    cachedConfig = null;
  },
};

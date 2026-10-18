export type AppError =
  | { readonly kind: 'NetworkError'; readonly message: string }
  | { readonly kind: 'TimeoutError'; readonly message: string }
  | { readonly kind: 'ParseError'; readonly message: string; readonly cause?: unknown }
  | {
      readonly kind: 'ServerError';
      readonly statusCode: number;
      readonly code?: string;
      readonly fieldErrors: Readonly<Record<string, string>>;
      readonly message: string;
    }
  | { readonly kind: 'ForbiddenScopeError'; readonly message: string }
  | { readonly kind: 'FeatureDisabledError'; readonly featureKey?: string; readonly message: string }
  | { readonly kind: 'ConflictError'; readonly serverCopy?: Record<string, unknown>; readonly message: string }
  | { readonly kind: 'NotFoundError'; readonly message: string }
  | { readonly kind: 'LoginRequired'; readonly forceLogout: boolean; readonly message: string }
  | { readonly kind: 'UnknownError'; readonly message: string; readonly cause?: unknown };

export const AppErrorFactory = {
  network: (message: string): AppError => ({ kind: 'NetworkError', message }),
  timeout: (message: string): AppError => ({ kind: 'TimeoutError', message }),
  parse: (message: string, cause?: unknown): AppError => ({ kind: 'ParseError', message, cause }),
  server: (
    statusCode: number,
    message: string,
    code?: string,
    fieldErrors: Readonly<Record<string, string>> = {},
  ): AppError => ({
    kind: 'ServerError',
    statusCode,
    code,
    fieldErrors,
    message,
  }),
  forbiddenScope: (message: string): AppError => ({ kind: 'ForbiddenScopeError', message }),
  featureDisabled: (message: string, featureKey?: string): AppError => ({
    kind: 'FeatureDisabledError',
    featureKey,
    message,
  }),
  conflict: (message: string, serverCopy?: Record<string, unknown>): AppError => ({
    kind: 'ConflictError',
    serverCopy,
    message,
  }),
  notFound: (message: string): AppError => ({ kind: 'NotFoundError', message }),
  loginRequired: (message: string, forceLogout = true): AppError => ({
    kind: 'LoginRequired',
    forceLogout,
    message,
  }),
  unknown: (message: string, cause?: unknown): AppError => ({ kind: 'UnknownError', message, cause }),
} as const;

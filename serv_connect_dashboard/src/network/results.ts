import type { AppError } from './errors';

export type ApiResult<T> =
  | { readonly kind: 'success'; readonly data: T }
  | { readonly kind: 'failure'; readonly error: AppError; readonly message: string };

export const ApiResult = {
  success: <T>(data: T): ApiResult<T> => ({ kind: 'success', data }),
  failure: <T = never>(error: AppError, message?: string): ApiResult<T> => ({
    kind: 'failure',
    error,
    message: message ?? error.message,
  }),
} as const;

import type { AppError } from './errors';

export type ResourceStatus = 'initial' | 'loading' | 'success' | 'error';

export interface Resources<T> {
  readonly status: ResourceStatus;
  readonly data?: T;
  readonly error?: AppError;
  readonly message?: string;
  readonly isInitial: boolean;
  readonly isLoading: boolean;
  readonly isSuccess: boolean;
  readonly isError: boolean;
}

export const Resources = {
  initial: <T>(): Resources<T> => ({
    status: 'initial',
    isInitial: true,
    isLoading: false,
    isSuccess: false,
    isError: false,
  }),

  loading: <T>(currentData?: T): Resources<T> => ({
    status: 'loading',
    data: currentData,
    isInitial: false,
    isLoading: true,
    isSuccess: false,
    isError: false,
  }),

  success: <T>(data: T): Resources<T> => ({
    status: 'success',
    data,
    isInitial: false,
    isLoading: false,
    isSuccess: true,
    isError: false,
  }),

  failure: <T>(error: AppError, message?: string, currentData?: T): Resources<T> => ({
    status: 'error',
    data: currentData,
    error,
    message: message ?? error.message,
    isInitial: false,
    isLoading: false,
    isSuccess: false,
    isError: true,
  }),
} as const;

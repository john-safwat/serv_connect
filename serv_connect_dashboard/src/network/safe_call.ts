import { ErrorParser } from './error_parser';
import { ApiResult } from './results';

export async function safeCall<T>(operation: () => Promise<T>): Promise<ApiResult<T>> {
  try {
    const data = await operation();
    return ApiResult.success(data);
  } catch (err: unknown) {
    const appError = ErrorParser.parseException(err);
    return ApiResult.failure(appError, appError.message);
  }
}

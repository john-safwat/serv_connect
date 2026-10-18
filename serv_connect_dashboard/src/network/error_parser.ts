import { i18n } from '../core/i18n/i18n';
import { LocaleKeys } from '../generated/locale_keys.g';
import type { BaseApiResponse } from './base_api_response';
import { type AppError, AppErrorFactory } from './errors';

function resolveMessage(envelopeMsg: string | undefined, fallbackKey: string): string {
  if (envelopeMsg && envelopeMsg.trim().length > 0) {
    return envelopeMsg.trim();
  }
  return i18n.isInitialized ? i18n.t(fallbackKey) : fallbackKey;
}

function parseForbidden(body?: BaseApiResponse<unknown>): AppError {
  if (body?.code === 'ERR_FEATURE_DISABLED') {
    const msg = resolveMessage(body.message, LocaleKeys.errors_feature_disabled);
    return AppErrorFactory.featureDisabled(msg);
  }
  const msg = resolveMessage(body?.message, LocaleKeys.errors_forbidden_scope);
  return AppErrorFactory.forbiddenScope(msg);
}

export const ErrorParser = {
  parseHttpStatus(statusCode: number, body?: BaseApiResponse<unknown>): AppError {
    if (statusCode === 401) {
      const msg = resolveMessage(body?.message, LocaleKeys.errors_unauthorized);
      return AppErrorFactory.loginRequired(msg, true);
    }
    if (statusCode === 403) {
      return parseForbidden(body);
    }
    if (statusCode === 404) {
      return AppErrorFactory.notFound(resolveMessage(body?.message, LocaleKeys.errors_not_found));
    }
    if (statusCode === 409) {
      return AppErrorFactory.conflict(resolveMessage(body?.message, LocaleKeys.errors_conflict));
    }
    const msg = resolveMessage(body?.message, LocaleKeys.errors_generic);
    return AppErrorFactory.server(statusCode, msg, body?.code, body?.fieldErrors ?? {});
  },

  parseException(err: unknown): AppError {
    if (err !== null && typeof err === 'object' && 'kind' in err) {
      return err as AppError;
    }
    if (err instanceof DOMException && err.name === 'AbortError') {
      return AppErrorFactory.timeout(resolveMessage(undefined, LocaleKeys.errors_timeout));
    }
    if (err instanceof TypeError) {
      return AppErrorFactory.network(resolveMessage(undefined, LocaleKeys.errors_network));
    }
    return AppErrorFactory.unknown(resolveMessage(undefined, LocaleKeys.errors_generic), err);
  },
};

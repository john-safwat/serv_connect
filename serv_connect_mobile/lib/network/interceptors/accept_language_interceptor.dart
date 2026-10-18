import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart';

/// Attaches `Accept-Language: <ar|en>` to every outgoing HTTP request so the
/// Spring Boot backend returns localized validation and error messages
/// (`CLAUDE.md §5 & §15`).
@lazySingleton
class AcceptLanguageInterceptor extends Interceptor {
  AcceptLanguageInterceptor(this._localeCubit);

  final LocaleCubit _localeCubit;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _localeCubit.languageCode;
    handler.next(options);
  }
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';
import 'package:serv_connect_mobile/network/base_api_response.dart';
import 'package:serv_connect_mobile/network/error_parser.dart';
import 'package:serv_connect_mobile/network/errors.dart';
import 'package:serv_connect_mobile/network/interceptors/accept_language_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/auth_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/refresh_interceptor.dart';
import 'package:serv_connect_mobile/network/resources.dart';
import 'package:serv_connect_mobile/network/results.dart';
import 'package:serv_connect_mobile/network/safe_call.dart';

class _MockLocaleCubit extends Mock implements LocaleCubit {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  const parser = ErrorParser();

  group('ErrorParser, safeCall & Resources', () {
    test('parse_mapsHttpStatusCodesToTypedSealedErrors', () {
      final req = RequestOptions(path: '/api/v1/members');
      final err401 = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(requestOptions: req, statusCode: 401),
      );
      expect(parser.parse(err401), isA<LoginRequired>());

      final err403Scope = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: req,
          statusCode: 403,
          data: <String, dynamic>{'code': 'ERR_FORBIDDEN_SCOPE'},
        ),
      );
      expect(parser.parse(err403Scope), isA<ForbiddenScopeError>());

      final err403Feature = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: req,
          statusCode: 403,
          data: <String, dynamic>{
            'code': 'ERR_FEATURE_DISABLED',
            'featureKey': 'trips',
          },
        ),
      );
      expect(parser.parse(err403Feature), isA<FeatureDisabledError>());

      final err409 = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: req,
          statusCode: 409,
          data: <String, dynamic>{
            'code': 'ERR_SYNC_CONFLICT',
            'data': <String, dynamic>{'version': 3},
          },
        ),
      );
      expect(parser.parse(err409), isA<SyncConflictError>());
    });

    test('safeCall_wrapsSuccessAndFailureCleanly', () async {
      final ok = await safeCall<int>(() async => 42);
      expect(ok, isA<Success<int>>());
      expect((ok as Success<int>).data, 42);

      final fail = await safeCall<int>(
        () async => throw TimeoutException('slow'),
      );
      expect(fail, isA<Failure<int>>());
      expect((fail as Failure<int>).exception, isA<TimeoutError>());
    });

    test('resources_preservesCachedDataAcrossLoadingAndFailure', () {
      const loadingWithCache = Resources<String>.loading(data: 'cached');
      expect(loadingWithCache.isLoading, isTrue);
      expect(loadingWithCache.data, 'cached');

      const failureWithCache = Resources<String>.failure(
        exception: NetworkError(),
        message: 'offline',
        data: 'cached',
      );
      expect(failureWithCache.isError, isTrue);
      expect(failureWithCache.data, 'cached');
    });

    test('baseApiResponseAndPagedContent_serializeAndDeserialize', () {
      final page = PagedContent<String>.fromJson(
        <String, dynamic>{
          'content': <String>['a', 'b'],
          'page': 0,
          'size': 2,
          'totalElements': 2,
          'totalPages': 1,
        },
        (raw) => raw.toString(),
      );
      expect(page.content.length, 2);
      final envelope = BaseApiResponse<int>.fromJson(
        <String, dynamic>{'data': 7, 'message': 'ok'},
        (raw) => raw! as int,
      );
      expect(envelope.data, 7);
    });
  });

  group('Interceptors', () {
    test('acceptLanguageAndAuthInterceptors_attachExpectedHeaders', () async {
      final localeCubit = _MockLocaleCubit();
      when(() => localeCubit.languageCode).thenReturn('ar');
      when(() => localeCubit.state).thenReturn(const Locale('ar'));
      final langInterceptor = AcceptLanguageInterceptor(localeCubit);

      final req = RequestOptions(path: '/api/v1/groups');
      langInterceptor.onRequest(req, RequestInterceptorHandler());
      expect(req.headers['Accept-Language'], 'ar');

      final secure = _MockSecureStorage();
      when(
        () => secure.read(StorageKey.accessToken),
      ).thenAnswer((_) async => 'jwt-token');
      final authInterceptor = AuthInterceptor(secure);
      await authInterceptor.onRequest(req, RequestInterceptorHandler());
      expect(req.headers['Authorization'], 'Bearer jwt-token');
    });

    test(
      'refreshInterceptor_whenOfflineOnRefresh_invokesGraceWindowHandler',
      () async {
        final secure = _MockSecureStorage();
        final authSession = _MockAuthSession();
        when(
          () => secure.read(StorageKey.accessToken),
        ).thenAnswer((_) async => 'stale-token');
        when(
          () => secure.read(StorageKey.refreshToken),
        ).thenAnswer((_) async => 'refresh-token');
        when(
          authSession.handleOfflineRefreshFailure,
        ).thenAnswer((_) async => AuthSessionStatus.authenticatedOffline);

        final interceptor = RefreshInterceptor(
          bareClient: Dio(),
          secureStorage: secure,
          authSession: authSession,
          refreshCall: (dio, token) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
              type: DioExceptionType.connectionError,
            );
          },
        );

        final req = RequestOptions(
          path: '/api/v1/schedule',
          headers: <String, dynamic>{'Authorization': 'Bearer stale-token'},
        );
        final err401 = DioException(
          requestOptions: req,
          response: Response<dynamic>(requestOptions: req, statusCode: 401),
        );

        await interceptor.onError(err401, _NoOpErrorHandler());
        verify(authSession.handleOfflineRefreshFailure).called(1);
      },
    );
  });
}

class _NoOpErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}

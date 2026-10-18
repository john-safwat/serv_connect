// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:serv_connect_mobile/core/common_ui/feedback/bottom_sheet_host.dart'
    as _i289;
import 'package:serv_connect_mobile/core/common_ui/feedback/toaster.dart'
    as _i181;
import 'package:serv_connect_mobile/core/config/app_environment.dart' as _i235;
import 'package:serv_connect_mobile/core/config/feature_flag_service.dart'
    as _i67;
import 'package:serv_connect_mobile/core/event_bus/app_event_bus.dart' as _i50;
import 'package:serv_connect_mobile/core/event_bus/auth_event_bus.dart'
    as _i155;
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart' as _i548;
import 'package:serv_connect_mobile/core/logger/app_logger.dart' as _i721;
import 'package:serv_connect_mobile/core/permissions/permission_checker.dart'
    as _i478;
import 'package:serv_connect_mobile/core/platform/serve_platform.dart' as _i903;
import 'package:serv_connect_mobile/core/platform/serve_platform_method_channel.dart'
    as _i49;
import 'package:serv_connect_mobile/core/services/auth_session.dart' as _i203;
import 'package:serv_connect_mobile/core/services/connectivity_service.dart'
    as _i629;
import 'package:serv_connect_mobile/core/storage/hive_storage.dart' as _i642;
import 'package:serv_connect_mobile/core/storage/preferences.dart' as _i833;
import 'package:serv_connect_mobile/core/storage/secure_storage.dart' as _i101;
import 'package:serv_connect_mobile/di/network_module.dart' as _i627;
import 'package:serv_connect_mobile/di/storage_module.dart' as _i801;
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_cubit.dart'
    as _i572;
import 'package:serv_connect_mobile/features/splash/presentation/splash/view/splash_cubit.dart'
    as _i102;
import 'package:serv_connect_mobile/network/dio_module.dart' as _i139;
import 'package:serv_connect_mobile/network/interceptors/accept_language_interceptor.dart'
    as _i96;
import 'package:serv_connect_mobile/network/interceptors/auth_interceptor.dart'
    as _i992;
import 'package:serv_connect_mobile/network/interceptors/logging_interceptor.dart'
    as _i73;
import 'package:serv_connect_mobile/network/interceptors/refresh_interceptor.dart'
    as _i253;
import 'package:serv_connect_mobile/routing/app_router.dart' as _i493;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final storageModule = _$StorageModule();
  final networkModule = _$NetworkModule();
  gh.singleton<_i721.AppLogger>(() => _i721.AppLogger());
  gh.lazySingleton<_i289.BottomSheetHost>(() => _i289.BottomSheetHost());
  gh.lazySingleton<_i181.Toaster>(() => _i181.Toaster());
  gh.lazySingleton<_i67.FeatureFlagService>(() => _i67.FeatureFlagService());
  gh.lazySingleton<_i50.AppEventBus>(() => _i50.AppEventBus());
  gh.lazySingleton<_i155.AuthEventBus>(() => _i155.AuthEventBus());
  gh.lazySingleton<_i629.ConnectivityService>(
    () => _i629.ConnectivityService(),
  );
  gh.lazySingleton<_i101.SecureStorage>(() => _i101.SecureStorage());
  await gh.lazySingletonAsync<_i460.SharedPreferences>(
    () => storageModule.sharedPreferences(),
    preResolve: true,
  );
  gh.lazySingleton<_i493.AppRouter>(() => _i493.AppRouter());
  gh.lazySingleton<_i992.AuthInterceptor>(
    () => _i992.AuthInterceptor(gh<_i101.SecureStorage>()),
  );
  gh.singleton<_i642.HiveStorage>(
    () => _i642.HiveStorage(gh<_i101.SecureStorage>()),
  );
  gh.lazySingleton<_i203.AuthSession>(
    () => _i203.AuthSession(
      gh<_i101.SecureStorage>(),
      gh<_i642.HiveStorage>(),
      gh<_i155.AuthEventBus>(),
      gh<_i235.AppEnvironment>(),
    ),
  );
  gh.lazySingleton<_i73.LoggingInterceptor>(
    () => _i73.LoggingInterceptor(gh<_i721.AppLogger>()),
  );
  gh.factory<_i102.SplashCubit>(
    () => _i102.SplashCubit(gh<_i203.AuthSession>()),
  );
  gh.lazySingleton<_i478.PermissionChecker>(
    () => _i478.PermissionChecker(gh<_i203.AuthSession>()),
  );
  gh.lazySingleton<_i903.ServePlatform>(
    () => _i49.ServePlatformMethodChannel(),
  );
  gh.lazySingleton<_i139.DioModule>(
    () => _i139.DioModule(gh<_i235.AppEnvironment>()),
  );
  gh.lazySingleton<_i833.Preferences>(
    () => storageModule.preferences(gh<_i460.SharedPreferences>()),
  );
  gh.lazySingleton<_i548.LocaleCubit>(
    () => _i548.LocaleCubit(gh<_i833.Preferences>(), gh<_i50.AppEventBus>()),
  );
  gh.factory<_i572.HomeCubit>(
    () => _i572.HomeCubit(
      gh<_i629.ConnectivityService>(),
      gh<_i203.AuthSession>(),
      gh<_i548.LocaleCubit>(),
    ),
  );
  gh.lazySingleton<_i96.AcceptLanguageInterceptor>(
    () => _i96.AcceptLanguageInterceptor(gh<_i548.LocaleCubit>()),
  );
  gh.lazySingleton<_i361.Dio>(
    () => networkModule.refreshDio(
      gh<_i139.DioModule>(),
      gh<_i96.AcceptLanguageInterceptor>(),
    ),
    instanceName: 'refresh',
  );
  gh.lazySingleton<_i253.RefreshInterceptor>(
    () => networkModule.refreshInterceptor(
      gh<_i361.Dio>(instanceName: 'refresh'),
      gh<_i101.SecureStorage>(),
      gh<_i203.AuthSession>(),
    ),
  );
  gh.lazySingleton<_i361.Dio>(
    () => networkModule.mainDio(
      gh<_i139.DioModule>(),
      gh<_i96.AcceptLanguageInterceptor>(),
      gh<_i992.AuthInterceptor>(),
      gh<_i253.RefreshInterceptor>(),
      gh<_i73.LoggingInterceptor>(),
    ),
    instanceName: 'main',
  );
  return getIt;
}

class _$StorageModule extends _i801.StorageModule {}

class _$NetworkModule extends _i627.NetworkModule {}

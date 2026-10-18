import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:__PKG__/app.dart';
import 'package:__PKG__/core/config/app_environment.dart';
import 'package:__PKG__/core/config/app_environment_loader.dart';
import 'package:__PKG__/core/services/auth_session.dart';
import 'package:__PKG__/core/services/locale_cubit.dart';
import 'package:__PKG__/core/storage/hive_storage.dart';
import 'package:__PKG__/di/di.dart';

/// Boots the app for a specific flavor. Called from `main_dev.dart`,
/// `main_staging.dart`, `main_prod.dart`.
///
/// Ordering matters:
/// 1. Bindings + localization + date symbols must be ready before any View.
/// 2. Env is loaded and registered before [configureDependencies] so
///    generated factories can resolve [AppEnvironment].
/// 3. Storage-backed singletons ([HiveStorage], [AuthSession]) hydrate before
///    `runApp`, so the first frame already knows the auth state.
Future<void> bootstrap({required Flavor flavor}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('ar');

  final env = await const AppEnvironmentLoader().load(flavor);

  await configureDependencies(env: env);
  await getIt<HiveStorage>().init();
  await getIt<AuthSession>().hydrate();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          getIt<LocaleCubit>().hydrate(context.locale);
          return const App();
        },
      ),
    ),
  );
}

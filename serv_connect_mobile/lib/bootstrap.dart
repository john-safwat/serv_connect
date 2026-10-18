import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:serv_connect_mobile/app.dart';
import 'package:serv_connect_mobile/core/config/app_environment_loader.dart';
import 'package:serv_connect_mobile/core/config/flavor_config.dart';
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/storage/hive_storage.dart';
import 'package:serv_connect_mobile/di/injection.dart';

/// Boots ServeConnect for a specific [Flavor] (`CLAUDE.md §27`).
///
/// 1. Initializes Flutter bindings, `EasyLocalization`, and `intl` locales.
/// 2. Loads `.env.<flavor>` and validates via `AppEnvironment.assertConfigured()`.
/// 3. Configures `get_it` dependencies, encrypted `HiveStorage`, and `AuthSession`.
/// 4. Mounts `EasyLocalization` + [ServeConnectApp].
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
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          getIt<LocaleCubit>().hydrate(fallback: context.locale);
          return const ServeConnectApp();
        },
      ),
    ),
  );
}

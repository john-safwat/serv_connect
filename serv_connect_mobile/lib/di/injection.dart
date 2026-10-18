import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/config/app_environment.dart';
import 'package:serv_connect_mobile/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Configures the `get_it` dependency graph (`CLAUDE.md §19 & §26`).
///
/// [AppEnvironment] is registered manually before `$initGetIt` runs because it
/// is constructed from the active flavor's `.env.<flavor>` file in `bootstrap`.
@InjectableInit(
  initializerName: r'$initGetIt',
  asExtension: false,
)
Future<void> configureDependencies({required AppEnvironment env}) async {
  if (getIt.isRegistered<AppEnvironment>()) {
    await getIt.reset();
  }
  getIt.registerSingleton<AppEnvironment>(env);
  await $initGetIt(getIt, environment: env.flavor.envName);
}

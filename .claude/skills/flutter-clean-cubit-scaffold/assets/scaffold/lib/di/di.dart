import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/config/app_environment.dart';
import 'package:__PKG__/di/di.config.dart';

final GetIt getIt = GetIt.instance;

/// Wires the dependency graph. Called by `bootstrap.dart` once the
/// `.env.<flavor>` is loaded and [AppEnvironment] is built.
///
/// [AppEnvironment] is registered manually before `$initGetIt` runs because
/// it is flavor-dependent. Generated factories resolve it via `getIt<...>()`.
///
/// Hot restart preserves the static `getIt`, so we reset before re-wiring to
/// avoid "already registered" errors.
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies({required AppEnvironment env}) async {
  if (getIt.isRegistered<AppEnvironment>()) {
    await getIt.reset();
  }
  getIt.registerSingleton<AppEnvironment>(env);
  await $initGetIt(getIt, environment: env.flavor.envName);
}

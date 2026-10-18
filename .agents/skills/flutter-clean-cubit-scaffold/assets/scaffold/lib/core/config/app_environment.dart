/// Build flavors. Add / remove entries here and keep the `main_<flavor>.dart`
/// entry points, `.env.<flavor>` files, and `flavorizr.yaml` in sync.
enum Flavor {
  dev('dev'),
  staging('staging'),
  prod('prod');

  const Flavor(this.envName);
  final String envName;
}

/// Typed facade over the loaded `.env.<flavor>` file. Register once in
/// `bootstrap.dart` before `configureDependencies`; read it via `getIt` at
/// call sites — never `dotenv.env['KEY']` directly.
class AppEnvironment {
  AppEnvironment({
    required this.flavor,
    required this.baseUrl,
    this.imgUrl = '',
  });

  final Flavor flavor;
  final String baseUrl;
  final String imgUrl;

  bool get isProduction => flavor == Flavor.prod;
  bool get isDev => flavor == Flavor.dev;
  bool get isStaging => flavor == Flavor.staging;

  /// Throws when a required config value is missing. Called by
  /// `AppEnvironmentLoader.load` before the env is returned, so the app
  /// refuses to boot with a broken config instead of failing silently later.
  void assertConfigured() {
    final missing = <String>[if (baseUrl.isEmpty) 'BASE_URL'];
    if (missing.isNotEmpty) {
      throw StateError(
        'AppEnvironment for ${flavor.envName} is missing: '
        '${missing.join(', ')}',
      );
    }
  }
}

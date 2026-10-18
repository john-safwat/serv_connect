/// Build flavors supported by ServeConnect mobile (`dev`, `staging`, `prod`).
enum Flavor {
  dev('dev', 'ServeConnect Dev'),
  staging('staging', 'ServeConnect Staging'),
  prod('prod', 'ServeConnect');

  const Flavor(this.envName, this.appTitle);

  final String envName;
  final String appTitle;
}

/// Static flavor metadata helper.
class FlavorConfig {
  const FlavorConfig({required this.flavor});

  final Flavor flavor;

  String get envFileName => '.env.${flavor.envName}';
  bool get isDev => flavor == Flavor.dev;
  bool get isStaging => flavor == Flavor.staging;
  bool get isProd => flavor == Flavor.prod;
}

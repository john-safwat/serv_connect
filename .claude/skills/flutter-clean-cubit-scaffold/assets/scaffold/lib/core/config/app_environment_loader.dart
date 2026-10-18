import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:__PKG__/core/config/app_environment.dart';

/// Loads the per-flavor `.env.<flavor>` file via `flutter_dotenv` and produces
/// an [AppEnvironment]. Called once per `main_<flavor>.dart` entry point.
class AppEnvironmentLoader {
  const AppEnvironmentLoader();

  static String _filename(Flavor flavor) => '.env.${flavor.envName}';

  Future<AppEnvironment> load(Flavor flavor) async {
    await dotenv.load(fileName: _filename(flavor));

    final env = AppEnvironment(
      flavor: flavor,
      baseUrl: _required('BASE_URL'),
      imgUrl: _optional('IMG_URL'),
    );
    return env..assertConfigured();
  }

  String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty || value.startsWith('__')) {
      return '';
    }
    return value;
  }

  String _optional(String key) => dotenv.env[key] ?? '';
}

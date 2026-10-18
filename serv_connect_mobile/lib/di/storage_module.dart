import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DI module for asynchronous / factory-constructed storage primitives.
@module
abstract class StorageModule {
  @preResolve
  @lazySingleton
  Future<SharedPreferences> sharedPreferences() =>
      SharedPreferences.getInstance();

  @lazySingleton
  Preferences preferences(SharedPreferences prefs) => Preferences(prefs);
}

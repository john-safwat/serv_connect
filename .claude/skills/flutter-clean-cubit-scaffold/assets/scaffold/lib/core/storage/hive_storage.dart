import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

/// Facade over Hive for non-sensitive cached domain data. Open every box
/// through here (never `Hive.openBox` from feature code) so lifecycle and the
/// user-scope wipe on logout stay centralised.
@lazySingleton
class HiveStorage {
  bool _initialised = false;

  /// Called once during bootstrap before `runApp`. Register adapters and open
  /// long-lived boxes here.
  Future<void> init() async {
    if (_initialised) return;
    await Hive.initFlutter();
    // Register type adapters and open boxes here, e.g.:
    //   Hive.registerAdapter(MyModelAdapter());
    //   await Hive.openBox<MyModel>('my_box');
    _initialised = true;
  }

  Box<T> box<T>(String name) => Hive.box<T>(name);

  /// Wipe all user-scoped cached data on logout / account deletion.
  Future<void> clearUserScope() async {
    // await Hive.box<MyModel>('my_box').clear();
  }
}

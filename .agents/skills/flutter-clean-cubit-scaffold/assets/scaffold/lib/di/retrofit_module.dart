import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// Exposes the main authenticated `Dio` instance under its bare type so
/// Retrofit-generated data sources (which take a `Dio` positional arg) resolve
/// it without needing the `@Named('main')` qualifier at every call site.
@module
abstract class RetrofitModule {
  @lazySingleton
  Dio dio(@Named('main') Dio main) => main;
}

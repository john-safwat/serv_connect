import 'package:injectable/injectable.dart';

/// DI module for `@RestApi()` Retrofit remote data sources.
///
/// Feature remote data sources (`<Feature>RemoteDataSource(dio)`) are bound
/// here as each feature module (`M1`–`M7`) lands.
@module
abstract class RetrofitModule {}

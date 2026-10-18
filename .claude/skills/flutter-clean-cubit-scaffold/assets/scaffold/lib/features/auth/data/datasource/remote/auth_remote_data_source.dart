import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:__PKG__/features/auth/data/model/authentication_response.dart';
import 'package:__PKG__/features/auth/data/model/login_request.dart';

part 'auth_remote_data_source.g.dart';

/// Retrofit client. The `Dio` it receives is the main authenticated instance
/// (see `RetrofitModule`). Add one method per endpoint; regenerate with
/// `dart run build_runner build`.
@RestApi()
@lazySingleton
abstract class AuthRemoteDataSource {
  @factoryMethod
  factory AuthRemoteDataSource(Dio dio) = _AuthRemoteDataSource;

  @POST('/auth/login')
  Future<AuthenticationResponse> login(@Body() LoginRequest body);
}

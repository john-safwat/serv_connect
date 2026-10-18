import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

/// Request DTO. `@JsonSerializable(fieldRename: FieldRename.snake)` maps Dart
/// `deviceToken` → JSON `device_token`. No freezed — hand-written factory
/// wrappers around the generated functions.
@JsonSerializable(fieldRename: FieldRename.snake)
class LoginRequest {
  const LoginRequest({this.email, this.password, this.deviceToken});

  final String? email;
  final String? password;
  final String? deviceToken;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

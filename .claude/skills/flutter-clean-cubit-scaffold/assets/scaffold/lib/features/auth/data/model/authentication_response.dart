import 'package:json_annotation/json_annotation.dart';

part 'authentication_response.g.dart';

/// Response DTO. Adjust the field names / nesting to match your API's login
/// envelope; the mapper converts this into the [UserData] entity.
@JsonSerializable(fieldRename: FieldRename.snake)
class AuthenticationResponse {
  const AuthenticationResponse({
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.userName,
  });

  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? userName;

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthenticationResponseToJson(this);
}

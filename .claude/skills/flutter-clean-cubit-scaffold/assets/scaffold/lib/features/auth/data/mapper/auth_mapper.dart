import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:__PKG__/features/auth/data/model/authentication_response.dart';
import 'package:__PKG__/features/auth/domain/entities/user_data.dart';

/// DTO ↔ entity conversion only. No side effects, no storage reads (beyond an
/// injected locale for bilingual field selection, if your API needs it).
@lazySingleton
class AuthMapper {
  const AuthMapper();

  UserData toUserData(AuthenticationResponse response) =>
      UserData(id: response.userId ?? '', name: response.userName ?? '');

  /// Serialises the entity for `SecureStorage` (via `AuthSession`).
  String toUserJson(UserData user) =>
      jsonEncode(<String, dynamic>{'id': user.id, 'name': user.name});
}

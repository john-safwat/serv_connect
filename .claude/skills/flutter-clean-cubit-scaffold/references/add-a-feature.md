# Recipe: add a feature slice

Follow this to add a feature to an already-scaffolded project. Do **not**
re-run the scaffold. The generated `lib/features/auth` slice is the reference —
mirror its layout. This example adds a read-only `profile` feature backed by
`GET /profile`.

Replace `profile` / `Profile` with your feature name throughout, and swap
`your_app` for the project's package name.

## 1. Domain

`lib/features/profile/domain/entities/profile.dart`
```dart
class Profile {
  const Profile({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;
}
```

`lib/features/profile/domain/repository/profile_repository.dart`
```dart
import 'package:your_app/features/profile/domain/entities/profile.dart';
import 'package:your_app/network/results.dart';

abstract class ProfileRepository {
  Future<ApiResult<Profile>> getProfile();
}
```

`lib/features/profile/domain/use_case/get_profile_use_case.dart`
```dart
import 'package:injectable/injectable.dart';
import 'package:your_app/features/profile/domain/entities/profile.dart';
import 'package:your_app/features/profile/domain/repository/profile_repository.dart';
import 'package:your_app/network/results.dart';

@injectable
class GetProfileUseCase {
  const GetProfileUseCase(this._repository);
  final ProfileRepository _repository;
  Future<ApiResult<Profile>> call() => _repository.getProfile();
}
```

## 2. Data

`lib/features/profile/data/model/profile_response.dart`
```dart
import 'package:json_annotation/json_annotation.dart';
part 'profile_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileResponse {
  const ProfileResponse({this.id, this.name, this.email});
  final String? id;
  final String? name;
  final String? email;
  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}
```

`lib/features/profile/data/mapper/profile_mapper.dart`
```dart
import 'package:injectable/injectable.dart';
import 'package:your_app/features/profile/data/model/profile_response.dart';
import 'package:your_app/features/profile/domain/entities/profile.dart';

@lazySingleton
class ProfileMapper {
  const ProfileMapper();
  Profile toEntity(ProfileResponse r) =>
      Profile(id: r.id ?? '', name: r.name ?? '', email: r.email ?? '');
}
```

`lib/features/profile/data/datasource/remote/profile_remote_data_source.dart`
```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:your_app/features/profile/data/model/profile_response.dart';
part 'profile_remote_data_source.g.dart';

@RestApi()
@lazySingleton
abstract class ProfileRemoteDataSource {
  @factoryMethod
  factory ProfileRemoteDataSource(Dio dio) = _ProfileRemoteDataSource;

  @GET('/profile')
  Future<ProfileResponse> getProfile();
}
```

`lib/features/profile/data/repository/profile_repository_impl.dart`
```dart
import 'package:injectable/injectable.dart';
import 'package:your_app/features/profile/data/datasource/remote/profile_remote_data_source.dart';
import 'package:your_app/features/profile/data/mapper/profile_mapper.dart';
import 'package:your_app/features/profile/domain/entities/profile.dart';
import 'package:your_app/features/profile/domain/repository/profile_repository.dart';
import 'package:your_app/network/results.dart';
import 'package:your_app/network/safe_call.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._mapper);
  final ProfileRemoteDataSource _remote;
  final ProfileMapper _mapper;

  @override
  Future<ApiResult<Profile>> getProfile() =>
      safeCall(() async => _mapper.toEntity(await _remote.getProfile()));
}
```

## 3. Presentation

`.../presentation/view/profile_states.dart`
```dart
import 'package:your_app/features/profile/domain/entities/profile.dart';
import 'package:your_app/network/resources.dart';

class ProfileStates {
  ProfileStates({this.profile = const Resources.initial()});
  final Resources<Profile> profile;
  ProfileStates copyWith({Resources<Profile>? profile}) =>
      ProfileStates(profile: profile ?? this.profile);
}

sealed class ProfileAction {}
class LoadProfileAction extends ProfileAction {}

sealed class ProfileNavigationAction {}
class ShowProfileError extends ProfileNavigationAction {
  ShowProfileError(this.message);
  final String message;
}
```

`.../presentation/view/profile_cubit.dart`
```dart
import 'package:injectable/injectable.dart';
import 'package:your_app/core/base/base_cubit.dart';
import 'package:your_app/features/profile/domain/entities/profile.dart';
import 'package:your_app/features/profile/domain/use_case/get_profile_use_case.dart';
import 'package:your_app/features/profile/presentation/view/profile_states.dart';
import 'package:your_app/network/resources.dart';
import 'package:your_app/network/results.dart';

@injectable
class ProfileCubit
    extends BaseCubit<ProfileStates, ProfileAction, ProfileNavigationAction> {
  ProfileCubit(this._getProfile) : super(ProfileStates());
  final GetProfileUseCase _getProfile;

  @override
  Future<void> doAction(ProfileAction action) async {
    switch (action) {
      case LoadProfileAction():
        await _load();
    }
  }

  Future<void> _load() async {
    emit(state.copyWith(profile: const Resources.loading()));
    final result = await _getProfile();
    switch (result) {
      case Success<Profile>():
        emit(state.copyWith(profile: Resources.success(data: result.data)));
      case Failure<Profile>():
        emit(state.copyWith(profile: Resources.failure(
          exception: result.exception, message: result.message)));
        emitNavigation(ShowProfileError(result.message));
    }
  }
}
```

`.../presentation/view/profile_page.dart` — a `@RoutePage()` `StatefulWidget`
that resolves `getIt<ProfileCubit>()`, subscribes to `cubit.navigation` in
`initState`, dispatches `LoadProfileAction()`, wraps its body in
`BlocProvider.value` + `BlocBuilder`, and renders shimmer while
`state.profile.isLoading`. Copy `features/auth/.../login_page.dart` and adapt.

## 4. Wire it up

1. Add the route to `lib/routing/app_router.dart`:
   ```dart
   AutoRoute(page: ProfileRoute.page, path: '/profile',
       guards: [AuthGuard(_session)]),
   ```
2. Add any new translation keys to **both** `assets/translations/en.json` and
   `ar.json`.
3. Regenerate:
   ```bash
   dart run easy_localization:generate -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys
   dart run build_runner build --delete-conflicting-outputs
   ```
   This produces `*.g.dart` (json/retrofit), `di.config.dart` (the new
   `@injectable` bindings), and `app_router.gr.dart` (the new route).
4. Add a `bloc_test` for `ProfileCubit` under
   `test/features/profile/...` mirroring `test/features/auth/login_cubit_test.dart`.
5. `dart format . && flutter analyze && flutter test`.

## Checklist

- [ ] domain: entity, repository interface, use case
- [ ] data: DTO(s), mapper, Retrofit data source, repository impl (`@LazySingleton(as: …)`)
- [ ] presentation: states (+ sealed actions), cubit (`@injectable`), page (`@RoutePage`)
- [ ] route registered, translation keys in en + ar
- [ ] codegen re-run and committed
- [ ] test added, analyze + tests green

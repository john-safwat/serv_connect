import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:__PKG__/features/auth/domain/entities/user_data.dart';
import 'package:__PKG__/features/auth/domain/use_case/login_use_case.dart';
import 'package:__PKG__/features/auth/presentation/login/view/login_cubit.dart';
import 'package:__PKG__/features/auth/presentation/login/view/login_states.dart';
import 'package:__PKG__/network/results.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late _MockLoginUseCase loginUseCase;

  setUp(() {
    loginUseCase = _MockLoginUseCase();
  });

  blocTest<LoginCubit, LoginStates>(
    'emits loading then success and navigates home on valid credentials',
    build: () {
      when(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Success(UserData(id: '1', name: 'Test')));
      return LoginCubit(loginUseCase);
    },
    act: (cubit) =>
        cubit.doAction(SubmitLoginAction(email: 'a@b.com', password: 'secret')),
    expect: () => [
      isA<LoginStates>().having(
        (s) => s.loginResource.isLoading,
        'isLoading',
        true,
      ),
      isA<LoginStates>().having(
        (s) => s.loginResource.isSuccess,
        'isSuccess',
        true,
      ),
    ],
    verify: (_) {
      verify(
        () => loginUseCase(email: 'a@b.com', password: 'secret'),
      ).called(1);
    },
  );

  blocTest<LoginCubit, LoginStates>(
    'emits loading then error on failed login',
    build: () {
      when(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Failure(message: 'Bad credentials'));
      return LoginCubit(loginUseCase);
    },
    act: (cubit) =>
        cubit.doAction(SubmitLoginAction(email: 'a@b.com', password: 'nope')),
    expect: () => [
      isA<LoginStates>().having(
        (s) => s.loginResource.isLoading,
        'isLoading',
        true,
      ),
      isA<LoginStates>().having(
        (s) => s.loginResource.isError,
        'isError',
        true,
      ),
    ],
  );
}

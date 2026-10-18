import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/base/base_cubit.dart';
import 'package:__PKG__/features/auth/domain/use_case/logout_use_case.dart';
import 'package:__PKG__/features/home/presentation/view/home_states.dart';

@injectable
class HomeCubit
    extends BaseCubit<HomeStates, HomeAction, HomeNavigationAction> {
  HomeCubit(this._logoutUseCase) : super(const HomeStates());

  final LogoutUseCase _logoutUseCase;

  @override
  Future<void> doAction(HomeAction action) async {
    switch (action) {
      case LogoutAction():
        await _logout();
    }
  }

  Future<void> _logout() async {
    await _logoutUseCase();
    emitNavigation(NavigateToLoginAfterLogout());
  }
}

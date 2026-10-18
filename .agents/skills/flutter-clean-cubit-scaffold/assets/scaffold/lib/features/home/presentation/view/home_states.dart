class HomeStates {
  const HomeStates();
}

sealed class HomeAction {}

class LogoutAction extends HomeAction {}

sealed class HomeNavigationAction {}

class NavigateToLoginAfterLogout extends HomeNavigationAction {}

/// Splash has no rendered state beyond a spinner — it only decides where to go.
class SplashStates {
  const SplashStates();
}

sealed class SplashAction {}

class CheckSessionAction extends SplashAction {}

sealed class SplashNavigationAction {}

class GoToLogin extends SplashNavigationAction {}

class GoToHome extends SplashNavigationAction {}

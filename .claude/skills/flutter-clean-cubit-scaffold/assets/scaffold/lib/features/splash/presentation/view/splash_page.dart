import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:__PKG__/core/theme/app_colors.dart';
import 'package:__PKG__/di/di.dart';
import 'package:__PKG__/features/splash/presentation/view/splash_cubit.dart';
import 'package:__PKG__/features/splash/presentation/view/splash_states.dart';
import 'package:__PKG__/routing/app_router.gr.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SplashCubit cubit = getIt();
  StreamSubscription<SplashNavigationAction>? _navSub;

  @override
  void initState() {
    super.initState();
    _navSub = cubit.navigation.listen(_handleNavigation);
    cubit.doAction(CheckSessionAction());
  }

  void _handleNavigation(SplashNavigationAction event) {
    switch (event) {
      case GoToLogin():
        context.router.replaceAll([const LoginRoute()]);
      case GoToHome():
        context.router.replaceAll([const HomeRoute()]);
    }
  }

  @override
  void dispose() {
    unawaited(_navSub?.cancel());
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.textOnPrimary),
      ),
    );
  }
}

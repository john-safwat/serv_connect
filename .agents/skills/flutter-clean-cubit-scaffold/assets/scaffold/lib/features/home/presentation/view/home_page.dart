import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:__PKG__/di/di.dart';
import 'package:__PKG__/features/home/presentation/view/home_cubit.dart';
import 'package:__PKG__/features/home/presentation/view/home_states.dart';
import 'package:__PKG__/generated/locale_keys.g.dart';
import 'package:__PKG__/routing/app_router.gr.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeCubit cubit = getIt();
  StreamSubscription<HomeNavigationAction>? _navSub;

  @override
  void initState() {
    super.initState();
    _navSub = cubit.navigation.listen(_handleNavigation);
  }

  void _handleNavigation(HomeNavigationAction event) {
    switch (event) {
      case NavigateToLoginAfterLogout():
        context.router.replaceAll([const LoginRoute()]);
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
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.home_title.tr(context: context))),
      body: Center(
        child: ElevatedButton(
          onPressed: () => cubit.doAction(LogoutAction()),
          child: Text(LocaleKeys.home_logout.tr(context: context)),
        ),
      ),
    );
  }
}

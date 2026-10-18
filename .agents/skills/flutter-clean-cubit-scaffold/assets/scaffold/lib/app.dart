import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:__PKG__/core/services/app_event_bus.dart';
import 'package:__PKG__/core/services/locale_cubit.dart';
import 'package:__PKG__/core/theme/app_theme.dart';
import 'package:__PKG__/di/di.dart';
import 'package:__PKG__/routing/app_router.dart';
import 'package:__PKG__/routing/app_router.gr.dart';

/// Root widget. `EasyLocalization` (wired in `bootstrap.dart`) wraps this so
/// the locale resolves before the router builds. A [ForceLogout] on the global
/// bus bounces the stack to the login route (see [RefreshInterceptor]).
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _router;
  late final StreamSubscription<ForceLogout> _forceLogoutSub;

  @override
  void initState() {
    super.initState();
    _router = getIt<AppRouter>();
    _forceLogoutSub = getIt<AppEventBus>().on<ForceLogout>().listen(
      (_) => _router.replaceAll([const LoginRoute()]),
    );
  }

  @override
  void dispose() {
    unawaited(_forceLogoutSub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp.router(
            title: '__APP_TITLE__',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: locale,
            routerConfig: _router.config(),
          );
        },
      ),
    );
  }
}

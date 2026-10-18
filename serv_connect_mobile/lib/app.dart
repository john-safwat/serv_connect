import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/toaster.dart';
import 'package:serv_connect_mobile/core/event_bus/auth_event_bus.dart';
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart';
import 'package:serv_connect_mobile/core/l10n/org_label_resolver.dart';
import 'package:serv_connect_mobile/core/theme/app_theme.dart';
import 'package:serv_connect_mobile/di/injection.dart';
import 'package:serv_connect_mobile/routing/app_router.dart';
import 'package:serv_connect_mobile/routing/app_router.gr.dart';

/// Root ServeConnect widget wiring [LocaleCubit], [OrgLabelResolver],
/// [Toaster], [AppRouter], and [AuthEventBus] (`CLAUDE.md §1.1 & §15`).
class ServeConnectApp extends StatefulWidget {
  const ServeConnectApp({super.key});

  @override
  State<ServeConnectApp> createState() => _ServeConnectAppState();
}

class _ServeConnectAppState extends State<ServeConnectApp> {
  late final AppRouter _router = getIt<AppRouter>();
  StreamSubscription<ForceLogoutEvent>? _forceLogoutSub;

  @override
  void initState() {
    super.initState();
    _forceLogoutSub = getIt<AuthEventBus>().on<ForceLogoutEvent>().listen(
      (_) => unawaited(_router.replaceAll([const SplashRoute()])),
    );
  }

  @override
  void dispose() {
    unawaited(_forceLogoutSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>.value(
      value: getIt<LocaleCubit>(),
      child: OrgLabelResolver(
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp.router(
              title: 'ServeConnect',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: getIt<Toaster>().messengerKey,
              theme: AppTheme.light(languageCode: locale.languageCode),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: locale,
              routerConfig: _router.config(),
            );
          },
        ),
      ),
    );
  }
}

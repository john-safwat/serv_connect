import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';
import 'package:serv_connect_mobile/di/injection.dart';
import 'package:serv_connect_mobile/features/splash/presentation/splash/view/splash_cubit.dart';
import 'package:serv_connect_mobile/features/splash/presentation/splash/view/splash_states.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';
import 'package:serv_connect_mobile/routing/app_router.gr.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final SplashCubit _cubit = getIt<SplashCubit>();
  StreamSubscription<SplashNavigationAction>? _navSub;

  @override
  void initState() {
    super.initState();
    _navSub = _cubit.navigation.listen(_handleNavigation);
    unawaited(_cubit.doAction(const CheckInitialSessionAction()));
  }

  void _handleNavigation(SplashNavigationAction effect) {
    switch (effect) {
      case NavigateToHomeShell():
        unawaited(context.router.replace(const HomeRoute()));
    }
  }

  @override
  void dispose() {
    unawaited(_navSub?.cancel());
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SplashCubit>.value(
      value: _cubit,
      child: const Scaffold(
        backgroundColor: AppColors.paper,
        body: _SplashBrandBody(),
      ),
    );
  }
}

class _SplashBrandBody extends StatelessWidget {
  const _SplashBrandBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
              color: AppColors.oxblood,
              borderRadius: BorderRadiusDirectional.circular(
                ServeSpacing.radiusCard,
              ),
            ),
            child: const Icon(
              Icons.church_outlined,
              color: AppColors.gold2,
              size: 34,
            ),
          ),
          const SizedBox(height: ServeSpacing.md),
          Text(
            LocaleKeys.common_app_name.tr(context: context),
            style: textTheme.displaySmall,
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/serve_sync_banner.dart';
import 'package:serv_connect_mobile/di/injection.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_cubit.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_states.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_bottom_nav.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_overview_tab.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_placeholder_tab.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_top_bar.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeCubit _cubit = getIt<HomeCubit>();
  StreamSubscription<HomeNavigationAction>? _navSub;

  @override
  void initState() {
    super.initState();
    _navSub = _cubit.navigation.listen(_handleNavigation);
    unawaited(_cubit.doAction(const RefreshConnectivityStatusAction()));
  }

  void _handleNavigation(HomeNavigationAction effect) {
    switch (effect) {
      case SyncLanguageWithContext(:final languageCode):
        unawaited(context.setLocale(Locale(languageCode)));
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
    return BlocProvider<HomeCubit>.value(
      value: _cubit,
      child: const _HomeScaffold(),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlocSelector<HomeCubit, HomeStates, ServeSyncBannerMode>(
              selector: (state) => state.syncBannerMode,
              builder: (context, mode) => ServeSyncBanner(mode: mode),
            ),
            HomeTopBar(
              onToggleLanguage: () =>
                  cubit.doAction(const ToggleAppLanguageAction()),
            ),
            const Expanded(child: _ActiveTabBody()),
          ],
        ),
      ),
      bottomNavigationBar: BlocSelector<HomeCubit, HomeStates, HomeTab>(
        selector: (state) => state.activeTab,
        builder: (context, activeTab) => HomeBottomNav(
          activeTab: activeTab,
          onTabSelected: (tab) => cubit.doAction(SelectHomeTabAction(tab)),
        ),
      ),
    );
  }
}

class _ActiveTabBody extends StatelessWidget {
  const _ActiveTabBody();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeStates, HomeTab>(
      selector: (state) => state.activeTab,
      builder: (context, activeTab) {
        if (activeTab == HomeTab.home) {
          return const HomeOverviewTab();
        }
        return HomePlaceholderTab(tab: activeTab);
      },
    );
  }
}

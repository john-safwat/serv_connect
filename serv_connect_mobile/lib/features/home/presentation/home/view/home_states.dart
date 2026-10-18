import 'package:serv_connect_mobile/core/common_ui/feedback/serve_sync_banner.dart';

/// Primary 5-tab navigation shell matching `designs/main.main.svg`.
enum HomeTab { home, schedule, attend, word, more }

class HomeStates {
  const HomeStates({
    this.activeTab = HomeTab.home,
    this.syncBannerMode = ServeSyncBannerMode.synced,
    this.pendingOutboxCount = 0,
  });

  final HomeTab activeTab;
  final ServeSyncBannerMode syncBannerMode;
  final int pendingOutboxCount;

  HomeStates copyWith({
    HomeTab? activeTab,
    ServeSyncBannerMode? syncBannerMode,
    int? pendingOutboxCount,
  }) {
    return HomeStates(
      activeTab: activeTab ?? this.activeTab,
      syncBannerMode: syncBannerMode ?? this.syncBannerMode,
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
    );
  }
}

sealed class HomeAction {
  const HomeAction();
}

class SelectHomeTabAction extends HomeAction {
  const SelectHomeTabAction(this.tab);
  final HomeTab tab;
}

class RefreshConnectivityStatusAction extends HomeAction {
  const RefreshConnectivityStatusAction();
}

class ToggleAppLanguageAction extends HomeAction {
  const ToggleAppLanguageAction();
}

sealed class HomeNavigationAction {
  const HomeNavigationAction();
}

class SyncLanguageWithContext extends HomeNavigationAction {
  const SyncLanguageWithContext(this.languageCode);
  final String languageCode;
}

import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/base/base_cubit.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/serve_sync_banner.dart';
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/services/connectivity_service.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_states.dart';

/// Controller for the 5-tab editorial app shell (`CLAUDE.md §9.2 & §17.1`).
@injectable
class HomeCubit
    extends BaseCubit<HomeStates, HomeAction, HomeNavigationAction> {
  HomeCubit(this._connectivityService, this._authSession, this._localeCubit)
    : super(const HomeStates());

  final ConnectivityService _connectivityService;
  final AuthSession _authSession;
  final LocaleCubit _localeCubit;

  @override
  Future<void> doAction(HomeAction action) async {
    switch (action) {
      case SelectHomeTabAction(:final tab):
        emit(state.copyWith(activeTab: tab));
      case RefreshConnectivityStatusAction():
        await _refreshConnectivity();
      case ToggleAppLanguageAction():
        await _toggleLanguage();
    }
  }

  Future<void> _refreshConnectivity() async {
    if (_authSession.isGraceExpired) {
      emit(state.copyWith(syncBannerMode: ServeSyncBannerMode.graceExpired));
      return;
    }
    final connected = await _connectivityService.isConnected();
    final mode = connected
        ? ServeSyncBannerMode.synced
        : ServeSyncBannerMode.offline;
    emit(state.copyWith(syncBannerMode: mode));
  }

  Future<void> _toggleLanguage() async {
    await _localeCubit.toggleLocale();
    emitNavigation(SyncLanguageWithContext(_localeCubit.languageCode));
  }
}

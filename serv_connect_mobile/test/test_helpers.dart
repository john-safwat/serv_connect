import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/l10n/org_label_resolver.dart';
import 'package:serv_connect_mobile/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory [AssetLoader] for widget tests so `key.tr(context: context)` works
/// deterministically without disk asset I/O.
class TestTranslationLoader extends AssetLoader {
  const TestTranslationLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'common': <String, dynamic>{
        'app_name': 'ServeConnect',
        'role_servant': 'Servant',
        'role_served_member': 'Served Member',
        'stage': 'Stage',
        'group': 'Group',
        'retry': 'Retry',
        'offline_banner': 'Working offline',
        'offline_mutations_disabled': 'Read-only mode',
        'synced': 'Synced',
        'syncing': 'Syncing',
        'pending_changes': 'Pending',
      },
      'nav': <String, dynamic>{
        'home': 'Home',
        'schedule': 'Schedule',
        'attend': 'Attend',
        'word': 'Word',
        'more': 'More',
      },
      'home': <String, dynamic>{
        'welcome_title': 'Peace & Grace',
        'welcome_subtitle': 'Offline-first ministry companion.',
        'quick_actions': 'Daily Ministry Loop',
        'upcoming_meetings': 'Upcoming Meetings',
        'schedule_placeholder': 'Schedule placeholder',
        'attend_placeholder': 'Attend placeholder',
        'word_placeholder': 'Word placeholder',
        'more_placeholder': 'More placeholder',
      },
      'errors': <String, dynamic>{
        'generic': 'Something went wrong.',
        'network': 'No internet connection.',
        'timeout': 'Request timed out.',
        'forbidden_scope': 'Forbidden scope.',
        'feature_disabled': 'Feature disabled.',
      },
    };
  }
}

Future<void> ensureTestLocalizationInitialized() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
}

Widget makeTestableWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  GlobalKey<ScaffoldMessengerState>? messengerKey,
}) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
    path: 'assets/translations',
    assetLoader: const TestTranslationLoader(),
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    child: Builder(
      builder: (context) {
        return MaterialApp(
          scaffoldMessengerKey: messengerKey,
          locale: locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: AppTheme.light(languageCode: locale.languageCode),
          home: OrgLabelResolver(
            overrides: const OrgLabelOverrides(
              servantLabels: <String, String>{'en': 'Mentor', 'ar': 'مرشد'},
            ),
            child: Scaffold(body: child),
          ),
        );
      },
    ),
  );
}

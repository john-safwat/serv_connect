import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_connect_mobile/core/common_ui/avatars/serve_member_avatar.dart';
import 'package:serv_connect_mobile/core/common_ui/badges/serve_badge.dart';
import 'package:serv_connect_mobile/core/common_ui/buttons/serve_button.dart';
import 'package:serv_connect_mobile/core/common_ui/buttons/serve_icon_button.dart';
import 'package:serv_connect_mobile/core/common_ui/cards/serve_card.dart';
import 'package:serv_connect_mobile/core/common_ui/controls/serve_segmented_control.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/default_error_view.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/serve_empty_state.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/serve_sync_banner.dart';
import 'package:serv_connect_mobile/core/common_ui/inputs/serve_text_field.dart';
import 'package:serv_connect_mobile/core/common_ui/shimmer/serve_card_shimmer.dart';
import 'package:serv_connect_mobile/core/common_ui/shimmer/serve_list_shimmer.dart';
import 'package:serv_connect_mobile/network/errors.dart';

import '../../test_helpers.dart';

void main() {
  setUpAll(() async {
    await ensureTestLocalizationInitialized();
  });

  group('ServeMemberAvatar photoConsent Safeguarding Gate (FR-13.5)', () {
    testWidgets('photoConsentFalse_neverMountsCachedNetworkImage', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const ServeMemberAvatar(
            memberId: 'minor-uuid-1',
            displayName: 'Mina Adel',
            photoConsent: false,
            photoUrl: 'https://cdn.example.org/photo.jpg',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('MA'), findsOneWidget);
    });

    testWidgets('photoConsentTrue_mountsCachedNetworkImage', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const ServeMemberAvatar(
            memberId: 'minor-uuid-2',
            displayName: 'Mina Adel',
            photoConsent: true,
            photoUrl: 'https://cdn.example.org/photo.jpg',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });

  group('Serve* Primitives & RTL Rendering', () {
    testWidgets('serveButtonAndIconButton_renderAndDispatchCallbacks', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        makeTestableWidget(
          Column(
            children: <Widget>[
              ServeButton(
                label: 'Save Attendance',
                onPressed: () => tapped = true,
              ),
              ServeIconButton(
                icon: Icons.sync,
                tooltip: 'Sync now',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Save Attendance'));
      expect(tapped, isTrue);
      expect(find.byType(ServeIconButton), findsOneWidget);
    });

    testWidgets('defaultErrorView_forbiddenScopeError_hidesRetryButton', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          DefaultErrorView(
            error: const ForbiddenScopeError(
              message: 'Out of assigned group scope',
            ),
            onRetry: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Out of assigned group scope'), findsOneWidget);
      expect(find.byType(ServeButton), findsNothing);
    });

    testWidgets('rtlDirectionality_rendersCardsInputsSegmentsAndShimmers', (
      tester,
    ) async {
      var selected = 'present';
      await tester.pumpWidget(
        makeTestableWidget(
          ListView(
            children: <Widget>[
              const ServeSyncBanner(mode: ServeSyncBannerMode.offline),
              ServeSegmentedControl<String>(
                items: const <ServeSegmentItem<String>>[
                  ServeSegmentItem<String>(value: 'present', label: 'حاضر'),
                  ServeSegmentItem<String>(value: 'absent', label: 'غائب'),
                ],
                selectedValue: selected,
                onChanged: (val) => selected = val,
              ),
              const ServeCard(
                child: ServeBadge(
                  label: 'مجموعة',
                  tone: ServeBadgeTone.green,
                ),
              ),
              const ServeTextField(label: 'الاسم', hintText: 'أدخل الاسم'),
              const ServeEmptyState(title: 'لا توجد بيانات'),
              const ServeCardShimmer(),
              const ServeListShimmer(itemCount: 2),
            ],
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('غائب'));
      expect(selected, 'absent');
      expect(find.byType(ServeCard), findsWidgets);
    });
  });
}

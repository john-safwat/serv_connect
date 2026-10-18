# 08 — Mobile Theme & Shared UI Component Catalogue (`serv_connect_mobile`)

| Field | Value |
| --- | --- |
| Design System Source | `designs/main.main.svg` (Warm Editorial Palette) |
| Theme Files | `lib/core/theme/{app_colors.dart, app_typography.dart, app_theme.dart, serve_spacing.dart, serve_breakpoints.dart}` |
| Component Catalogue | `lib/core/common_ui/` (`Serve*` primitives) |
| Accessibility | WCAG 2.1 AA contrast, ≥ 48 × 48 dp touch targets, localized `Semantics` / `tooltip`, RTL-first directional layouts |

---

## 1. Color Tokens (`AppColors`)

Defined in `lib/core/theme/app_colors.dart` directly from `designs/main.main.svg`. Feature widgets never hard-code `Color(0xFF...)`:

| Token | Hex | Swatch Role |
| --- | --- | --- |
| `AppColors.ink` | `0xFF1E1913` | Primary editorial ink text & dark button fill |
| `AppColors.ink2` | `0xFF4A4139` | Secondary body text |
| `AppColors.muted` | `0xFF8C8173` | Captions, hints, inactive icons |
| `AppColors.cream` | `0xFFF4EDE0` | Secondary warm canvas & subtle card fill |
| `AppColors.paper` | `0xFFFBF6EC` | Primary scaffold background |
| `AppColors.ivory` | `0xFFFFFFFF` | Elevated card & input fill |
| `AppColors.line` | `0xFFE7DDC9` | Hairline card & section borders |
| `AppColors.line2` | `0xFFDBCFB5` | Input & outline button borders |
| `AppColors.segmentedTrack` | `0xFFEAE1CF` | Segmented control background track |
| `AppColors.red` | `0xFFC0182A` | Primary liturgical crimson action color |
| `AppColors.oxblood` | `0xFF8C1420` | Deep oxblood accent & error foreground |
| `AppColors.redSoft` | `0xFFF6E5E1` | Soft crimson badge & alert surface |
| `AppColors.gold` | `0xFFB0862F` | Primary warm gold accent |
| `AppColors.gold2` | `0xFFC6A15B` | Light liturgical gold highlight |
| `AppColors.goldDark` | `0xFF9C7C34` | High-contrast gold badge text |
| `AppColors.goldSoft` | `0xFFEFE2C4` | Soft gold badge & avatar surface |
| `AppColors.green` | `0xFF3B7A54` | Present / synced / success foreground |
| `AppColors.greenSoft` | `0xFFE6F0E7` | Soft green badge & avatar surface |
| `AppColors.amber` | `0xFFB07C13` | Excused / offline warning foreground |
| `AppColors.amberSoft` | `0xFFF5E9CD` | Soft amber warning surface |
| `AppColors.blue` | `0xFF34568C` | Info / stage badge foreground |
| `AppColors.blueSoft` | `0xFFE6EBF4` | Soft blue badge & avatar surface |
| `AppColors.shimmerBase` | `0xFFECE4D3` | Warm skeleton shimmer base |
| `AppColors.shimmerHighlight` | `0xFFF6F1E6` | Warm skeleton shimmer highlight |

---

## 2. Typography (`AppTypography`) & Spacing (`ServeSpacing`)

- **English (`en`, LTR):** `Fraunces` (display/headline serif) + `Inter` (UI sans).
- **Arabic (`ar`, RTL):** `Amiri` (display/headline serif) + `Cairo` (UI sans).
- **Spacing & Radii (`ServeSpacing`):**
  - Spacing scale: `xxs: 4`, `xs: 8`, `sm: 12`, `md: 16`, `lg: 20`, `xl: 24`, `xxl: 32`.
  - Radii: `radiusSm: 8`, `radiusMd: 12`, `radiusButton: 14`, `radiusCard: 18`, `radiusPill: 999`.
  - Touch target: `minHitTarget: 48` (48 × 48 dp minimum interactive area).

---

## 3. Shared `Serve*` UI Component Catalogue (`lib/core/common_ui/`)

Every shared cross-feature widget is registered below (`CLAUDE.md §1.4`). Check this table before creating any new UI primitive:

| Component | File Path | Constructor Signature (Named Params & Defaults) | Purpose |
| --- | --- | --- | --- |
| `ServeButton` | `lib/core/common_ui/buttons/serve_button.dart` | `ServeButton({required String label, required VoidCallback? onPressed, ServeButtonVariant variant = ServeButtonVariant.primaryRed, bool isLoading = false, bool isEnabled = true, bool isExpanded = false, IconData? leadingIcon, Key? key})` | Editorial action button (`primaryRed`, `ink`, `gold`, `outline`, `soft`) with 48dp hit target and inline loading spinner. |
| `ServeIconButton` | `lib/core/common_ui/buttons/serve_icon_button.dart` | `ServeIconButton({required IconData icon, required String tooltip, required VoidCallback? onPressed, Color color = AppColors.ink, Color? backgroundColor, Key? key})` | Accessible 48×48dp icon button requiring a localized `tooltip` / `Semantics` label. |
| `ServeTextField` | `lib/core/common_ui/inputs/serve_text_field.dart` | `ServeTextField({TextEditingController? controller, String? label, String? hintText, String? errorText, FormFieldValidator<String>? validator, ValueChanged<String>? onChanged, TextInputType? keyboardType, bool obscureText = false, bool enabled = true, IconData? prefixIcon, Widget? suffixIcon, Key? key})` | Warm ivory form input with `line2` border, `gold` focus ring, and localized validation error support. |
| `ServeCard` | `lib/core/common_ui/cards/serve_card.dart` | `ServeCard({required Widget child, ServeCardVariant variant = ServeCardVariant.elevatedIvory, EdgeInsetsGeometry padding = const EdgeInsetsDirectional.all(16), VoidCallback? onTap, Key? key})` | 18px-radius editorial surface container (`elevatedIvory`, `flatPaper`, `cream`) with `line` border. |
| `ServeBadge` | `lib/core/common_ui/badges/serve_badge.dart` | `ServeBadge({required String label, ServeBadgeTone tone = ServeBadgeTone.gold, bool showDot = true, Key? key})` | Semantic pill badge (`red`, `gold`, `green`, `amber`, `blue`, `gray`, `line`) with optional leading status dot. |
| `ServeAvatar` | `lib/core/common_ui/avatars/serve_avatar.dart` | `ServeAvatar({required String displayName, String? imageUrl, String? cacheKey, double radius = 22, Key? key})` | Base circular avatar rendering cached network image or deterministic warm soft-tinted serif initials. |
| `ServeMemberAvatar` | `lib/core/common_ui/avatars/serve_member_avatar.dart` | `ServeMemberAvatar({required String memberId, required String displayName, required bool photoConsent, String? photoUrl, String? photoChecksum, double radius = 22, Key? key})` | Safeguarding-gated member avatar (`FR-13.5`) that suppresses `photoUrl` whenever `photoConsent == false`. |
| `ServeSegmentedControl<T>` | `lib/core/common_ui/controls/serve_segmented_control.dart` | `ServeSegmentedControl({required List<ServeSegmentItem<T>> items, required T selectedValue, required ValueChanged<T> onChanged, Key? key})` | Segmented pill selector (`#EAE1CF` track with ivory active pill). |
| `ServeEmptyState` | `lib/core/common_ui/feedback/serve_empty_state.dart` | `ServeEmptyState({required String title, String? subtitle, IconData icon = Icons.inbox_outlined, String? actionLabel, VoidCallback? onActionPressed, Key? key})` | Centered empty state with warm cream icon badge, title, subtitle, and optional CTA button. |
| `DefaultErrorView` | `lib/core/common_ui/feedback/default_error_view.dart` | `DefaultErrorView({Errors? error, String? customMessage, VoidCallback? onRetry, Key? key})` | Error fallback view handling `ForbiddenScopeError` (`403`), `FeatureDisabledError` (`403`), `NetworkError`, and retry CTA. |
| `ServeSyncBanner` | `lib/core/common_ui/feedback/serve_sync_banner.dart` | `ServeSyncBanner({required ServeSyncBannerMode mode, int pendingCount = 0, VoidCallback? onTap, Key? key})` | Non-blocking top status banner for `offline`, `syncing`, `graceExpired` (`FR-1.3`), and pending outbox items. |
| `Toaster` | `lib/core/common_ui/feedback/toaster.dart` | `@lazySingleton Toaster` (`showSuccess`, `showWarning`, `showError`) | Global floating toast/snackbar facade wired via `ServeConnectApp`'s `scaffoldMessengerKey`. |
| `BottomSheetHost` | `lib/core/common_ui/feedback/bottom_sheet_host.dart` | `@lazySingleton BottomSheetHost` (`show<T>({required BuildContext context, required WidgetBuilder builder, bool isScrollControlled = true})`) | Centralised host for rounded warm-paper modal bottom sheets. |
| `ServeShimmerBox` | `lib/core/common_ui/shimmer/serve_shimmer_box.dart` | `ServeShimmerBox({required double height, double width = double.infinity, double borderRadius = 8, Key? key})` | Warm editorial shimmer rectangle (`#ECE4D3` → `#F6F1E6`). |
| `ServeRowShimmer` | `lib/core/common_ui/shimmer/serve_row_shimmer.dart` | `ServeRowShimmer({Key? key})` | Avatar + two-line row skeleton shimmer. |
| `ServeCardShimmer` | `lib/core/common_ui/shimmer/serve_card_shimmer.dart` | `ServeCardShimmer({Key? key})` | `ServeCard` skeleton shimmer for loading detail/summary cards. |
| `ServeListShimmer` | `lib/core/common_ui/shimmer/serve_list_shimmer.dart` | `ServeListShimmer({int itemCount = 6, Key? key})` | Non-scrollable list of `ServeRowShimmer` placeholders for initial cache-miss loading states. |

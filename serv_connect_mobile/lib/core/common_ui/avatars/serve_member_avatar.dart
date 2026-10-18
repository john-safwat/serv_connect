import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/avatars/serve_avatar.dart';

/// Safeguarding-aware member avatar (`FR-13.5`, `CLAUDE.md §7 & §19`).
///
/// Strictly enforces [photoConsent]: when `photoConsent == false`, [photoUrl]
/// is NEVER passed to [ServeAvatar] / `CachedNetworkImage`, rendering the
/// deterministic initials placeholder instead.
class ServeMemberAvatar extends StatelessWidget {
  const ServeMemberAvatar({
    required this.memberId,
    required this.displayName,
    required this.photoConsent,
    this.photoUrl,
    this.photoChecksum,
    this.radius = 22,
    super.key,
  });

  final String memberId;
  final String displayName;
  final bool photoConsent;
  final String? photoUrl;
  final String? photoChecksum;
  final double radius;

  String? get _effectiveUrl => photoConsent ? photoUrl : null;

  String? get _stableCacheKey {
    if (!photoConsent || photoUrl == null) return null;
    final checksum = photoChecksum ?? 'v1';
    return 'member_${memberId}_$checksum';
  }

  @override
  Widget build(BuildContext context) {
    return ServeAvatar(
      displayName: displayName,
      imageUrl: _effectiveUrl,
      cacheKey: _stableCacheKey,
      radius: radius,
    );
  }
}

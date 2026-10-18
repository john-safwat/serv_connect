import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/shimmer/serve_row_shimmer.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// List skeleton shimmer rendering [itemCount] [ServeRowShimmer] placeholders
/// (`CLAUDE.md §13`).
class ServeListShimmer extends StatelessWidget {
  const ServeListShimmer({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(ServeSpacing.md),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: ServeSpacing.xs),
      itemBuilder: (_, index) =>
          ServeRowShimmer(key: ValueKey<String>('shimmer_row_$index')),
    );
  }
}

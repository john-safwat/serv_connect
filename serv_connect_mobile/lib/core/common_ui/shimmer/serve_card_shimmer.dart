import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/cards/serve_card.dart';
import 'package:serv_connect_mobile/core/common_ui/shimmer/serve_shimmer_box.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Card-shaped skeleton shimmer (`CLAUDE.md §13`).
class ServeCardShimmer extends StatelessWidget {
  const ServeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ServeShimmerBox(height: 16, width: 140),
          SizedBox(height: ServeSpacing.sm),
          ServeShimmerBox(height: 12),
          SizedBox(height: ServeSpacing.xs),
          ServeShimmerBox(height: 12, width: 200),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/common_ui/shimmer/serve_shimmer_box.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

/// Single-row skeleton shimmer for member/attendance/task list items
/// (`CLAUDE.md §13`).
class ServeRowShimmer extends StatelessWidget {
  const ServeRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: ServeSpacing.xs),
      child: Row(
        children: <Widget>[
          ServeShimmerBox(
            width: 44,
            height: 44,
            borderRadius: ServeSpacing.radiusPill,
          ),
          SizedBox(width: ServeSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ServeShimmerBox(height: 14, width: 160),
                SizedBox(height: ServeSpacing.xs),
                ServeShimmerBox(height: 11, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

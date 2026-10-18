import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';
import 'package:shimmer/shimmer.dart';

/// Base warm editorial shimmer block (`#ECE4D3` → `#F6F1E6`,
/// `designs/main.main.svg`, `CLAUDE.md §13`).
class ServeShimmerBox extends StatelessWidget {
  const ServeShimmerBox({
    required this.height,
    this.width = double.infinity,
    this.borderRadius = ServeSpacing.radiusSm,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadiusDirectional.circular(borderRadius),
        ),
      ),
    );
  }
}

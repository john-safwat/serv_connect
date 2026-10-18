import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

enum ServeCardVariant { elevatedIvory, flatPaper, cream }

/// Editorial surface card with 18px radius and warm hairline border
/// (`designs/main.main.svg`, `CLAUDE.md §1.4`).
class ServeCard extends StatelessWidget {
  const ServeCard({
    required this.child,
    this.variant = ServeCardVariant.elevatedIvory,
    this.padding = const EdgeInsetsDirectional.all(ServeSpacing.md),
    this.onTap,
    super.key,
  });

  final Widget child;
  final ServeCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: _buildDecoration(),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ServeSpacing.radiusCard),
        onTap: onTap,
        child: box,
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      color: _backgroundColor,
      borderRadius: BorderRadiusDirectional.circular(ServeSpacing.radiusCard),
      border: Border.all(color: AppColors.line),
      boxShadow: variant == ServeCardVariant.elevatedIvory
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x0D1E1913),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  Color get _backgroundColor {
    return switch (variant) {
      ServeCardVariant.elevatedIvory => AppColors.ivory,
      ServeCardVariant.flatPaper => AppColors.paper,
      ServeCardVariant.cream => AppColors.cream,
    };
  }
}

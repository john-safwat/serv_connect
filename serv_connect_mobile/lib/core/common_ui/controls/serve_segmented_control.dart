import 'package:flutter/material.dart';
import 'package:serv_connect_mobile/core/theme/app_colors.dart';
import 'package:serv_connect_mobile/core/theme/serve_spacing.dart';

class ServeSegmentItem<T> {
  const ServeSegmentItem({required this.value, required this.label});
  final T value;
  final String label;
}

/// Editorial segmented control (`#EAE1CF` track with ivory active pill)
/// matching `designs/main.main.svg`.
class ServeSegmentedControl<T> extends StatelessWidget {
  const ServeSegmentedControl({
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    super.key,
  });

  final List<ServeSegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(ServeSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.segmentedTrack,
        borderRadius: BorderRadiusDirectional.circular(
          ServeSpacing.radiusButton,
        ),
      ),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: _SegmentPill<T>(
                  item: item,
                  isSelected: item.value == selectedValue,
                  onTap: () => onChanged(item.value),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SegmentPill<T> extends StatelessWidget {
  const _SegmentPill({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ServeSegmentItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: isSelected ? AppColors.ink : AppColors.ink2,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ivory : Colors.transparent,
          borderRadius: BorderRadiusDirectional.circular(
            ServeSpacing.radiusMd,
          ),
        ),
        child: Text(item.label, style: textStyle),
      ),
    );
  }
}

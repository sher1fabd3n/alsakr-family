import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({
    super.key,
    required this.count,
    required this.child,
    this.inverted = false,
    this.offset = const Offset(6, -6),
  });

  final int count;
  final Widget child;
  final bool inverted;
  final Offset offset;

  static String labelFor(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    if (inverted) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (count > 0)
            Positioned(
              top: offset.dy,
              left: offset.dx,
              child: UnreadCountPill(count: count, inverted: true),
            ),
        ],
      );
    }

    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      alignment: AlignmentDirectional.topEnd,
      offset: offset,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      label: Text(
        labelFor(count),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      child: child,
    );
  }
}

class UnreadCountPill extends StatelessWidget {
  const UnreadCountPill({
    super.key,
    required this.count,
    this.inverted = false,
  });

  final int count;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: inverted ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        UnreadCountBadge.labelFor(count),
        style: TextStyle(
          color: inverted ? AppColors.primary : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lightweight shimmer skeleton for loading placeholders.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                AppColors.surfaceMuted,
                Colors.white.withValues(alpha: 0.9),
                AppColors.surfaceMuted,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChildCarouselSkeleton extends StatelessWidget {
  const ChildCarouselSkeleton({super.key, this.height = 168});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: ShimmerBox(
          width: double.infinity,
          height: height - 20,
          borderRadius: 22,
        ),
      ),
    );
  }
}

class FamilyDashboardSkeleton extends StatelessWidget {
  const FamilyDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: double.infinity, height: 100, borderRadius: 20),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerBox(width: double.infinity, height: 44, borderRadius: 12)),
              const SizedBox(width: 8),
              Expanded(child: ShimmerBox(width: double.infinity, height: 44, borderRadius: 12)),
            ],
          ),
          const SizedBox(height: 20),
          const ShimmerBox(width: 120, height: 22, borderRadius: 8),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ShimmerBox(width: double.infinity, height: 140, borderRadius: 20),
            ),
          ),
        ],
      ),
    );
  }
}

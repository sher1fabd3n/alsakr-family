import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/student_avatar.dart';
import '../models/parent_family_models.dart';
import '../state/parent_child_context.dart';
import 'child_photo_actions.dart';

typedef ActiveChildTapCallback = void Function(ChildDashboardSummary child);

/// ColorOS-style swipeable card carousel for switching the active child.
class ChildSwitcher extends StatefulWidget {
  const ChildSwitcher({
    super.key,
    this.height = 188,
    this.compact = false,
    this.showPageIndicator = true,
    this.onActiveCardTap,
  });

  final double height;
  final bool compact;
  final bool showPageIndicator;
  final ActiveChildTapCallback? onActiveCardTap;

  @override
  State<ChildSwitcher> createState() => _ChildSwitcherState();
}

class _ChildSwitcherState extends State<ChildSwitcher> {
  static const _viewportFraction = 0.78;
  static const _animDuration = Duration(milliseconds: 320);

  PageController? _pageController;
  int? _lastSyncedStudentId;
  int? _lastHapticStudentId;
  int _pageCount = 0;

  double get _effectiveHeight => widget.compact ? widget.height.clamp(128, 152) : widget.height;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _initOrUpdateController(int pageCount, int initialPage) {
    if (_pageController == null || _pageCount != pageCount) {
      _pageController?.dispose();
      _pageController = PageController(
        viewportFraction: _viewportFraction,
        initialPage: initialPage.clamp(0, pageCount - 1),
      );
      _pageCount = pageCount;
    }
  }

  void _syncToActiveChild(List<ChildDashboardSummary> children, int? activeStudentId) {
    if (_pageController == null || children.isEmpty) return;

    final targetIndex = _indexForStudent(children, activeStudentId);
    if (activeStudentId == _lastSyncedStudentId) return;

    _lastSyncedStudentId = activeStudentId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageController == null || !_pageController!.hasClients) return;
      final current = _pageController!.page?.round() ?? _pageController!.initialPage;
      if (current != targetIndex) {
        _pageController!.animateToPage(
          targetIndex,
          duration: _animDuration,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  int _indexForStudent(List<ChildDashboardSummary> children, int? studentId) {
    if (studentId == null) return 0;
    final index = children.indexWhere((c) => c.studentId == studentId);
    return index >= 0 ? index : 0;
  }

  void _onPageChanged(int index, List<ChildDashboardSummary> children, ParentChildContext ctx) {
    if (index < 0 || index >= children.length) return;
    final child = children[index];
    _lastSyncedStudentId = child.studentId;

    if (_lastHapticStudentId != child.studentId) {
      _lastHapticStudentId = child.studentId;
      HapticFeedback.selectionClick();
    }

    if (ctx.activeStudentId != child.studentId) {
      ctx.selectChild(child.studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<ParentChildContext>();
    final children = ctx.children;

    if (children.isEmpty) {
      if (ctx.isLoading) {
        return ChildCarouselSkeleton(height: _effectiveHeight);
      }
      return const SizedBox.shrink();
    }

    final activeIndex = _indexForStudent(children, ctx.activeStudentId);
    _initOrUpdateController(children.length, activeIndex);
    _syncToActiveChild(children, ctx.activeStudentId);

    final controller = _pageController!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _effectiveHeight,
          child: PageView.builder(
            controller: controller,
            padEnds: true,
            clipBehavior: Clip.none,
            itemCount: children.length,
            onPageChanged: (index) => _onPageChanged(index, children, ctx),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final page =
                      controller.hasClients ? (controller.page ?? activeIndex.toDouble()) : activeIndex.toDouble();
                  final delta = page - index;
                  final focus = (1 - delta.abs()).clamp(0.0, 1.0);
                  final scale = 0.86 + (0.14 * focus);
                  final elevation = 4.0 + (14.0 * focus);
                  final opacity = 0.72 + (0.28 * focus);
                  final parallax = delta * 14;

                  return _CarouselCard(
                    child: children[index],
                    isActive: focus > 0.92,
                    scale: scale,
                    elevation: elevation,
                    opacity: opacity,
                    parallaxOffset: parallax,
                    compact: widget.compact,
                    onTap: focus > 0.92 ? widget.onActiveCardTap : null,
                  );
                },
              );
            },
          ),
        ),
        if (widget.showPageIndicator && children.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final page =
                    controller.hasClients ? (controller.page ?? activeIndex.toDouble()) : activeIndex.toDouble();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(children.length, (i) {
                    final distance = (page - i).abs();
                    final active = (1 - distance).clamp(0.0, 1.0);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6 + (10 * active),
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.primary.withValues(alpha: 0.25 + (0.75 * active)),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.child,
    required this.isActive,
    required this.scale,
    required this.elevation,
    required this.opacity,
    required this.parallaxOffset,
    required this.compact,
    this.onTap,
  });

  final ChildDashboardSummary child;
  final bool isActive;
  final double scale;
  final double elevation;
  final double opacity;
  final double parallaxOffset;
  final bool compact;
  final ActiveChildTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = compact ? 22.0 : 30.0;
    final statusColor = statusIndicatorColor(child.statusIndicator);

    final card = Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 6 : 8),
          child: Material(
            elevation: elevation,
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(22),
            color: AppColors.surface,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.06),
                  width: isActive ? 1.5 : 1,
                ),
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.06),
                          AppColors.secondary.withValues(alpha: 0.04),
                        ],
                      )
                    : null,
              ),
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      StudentAvatar(
                        studentId: child.studentId,
                        name: child.name,
                        photoUrl: child.profilePhotoUrl,
                        radius: avatarRadius,
                        enableHero: isActive,
                        parallaxOffset: parallaxOffset,
                        onEditPhoto: isActive
                            ? () => ChildPhotoActions.pickAndUpload(context, child.studentId)
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 2),
                          ),
                        ),
                      ),
                      if (child.unreadNotificationCount > 0)
                        Positioned(
                          left: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              child.unreadNotificationCount > 9 ? '9+' : '${child.unreadNotificationCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                      'مدرسة الصقر للغات',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 10 : 11,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 3),
                    Row(
                          children: [
                            Expanded(
                              child: Text(
                                child.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: compact ? 15 : 17,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'نشط',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'كود السيستم ${child.rollNo}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        if (isActive && !compact) ...[
                          const SizedBox(height: 8),
                          Text(
                            child.grade,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          if (child.routeName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.route_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    child.routeName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _TransportChip(chip: child.transportationChip),
                              _AttendanceChip(
                                percentage: child.attendancePercentage,
                                trend: child.attendanceTrend,
                              ),
                            ],
                          ),
                        ] else if (!compact) ...[
                          const SizedBox(height: 4),
                          Text(
                            child.grade,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap == null || !isActive) return card;

    return GestureDetector(
      onTap: () => onTap!(child),
      child: card,
    );
  }
}

class _TransportChip extends StatelessWidget {
  const _TransportChip({required this.chip});

  final TransportationChip chip;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (chip) {
      TransportationChip.onBus => ('على الحافلة', AppColors.success, Icons.directions_bus_filled_rounded),
      TransportationChip.arrived => ('وصل', const Color(0xFF2563EB), Icons.where_to_vote_rounded),
      TransportationChip.private => ('نقل خاص', const Color(0xFFFFB000), Icons.directions_car_rounded),
      TransportationChip.notAssigned => ('غير محدد', AppColors.textMuted, Icons.block_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  const _AttendanceChip({required this.percentage, required this.trend});

  final double percentage;
  final AttendanceTrend trend;

  @override
  Widget build(BuildContext context) {
    final trendIcon = switch (trend) {
      AttendanceTrend.up => Icons.arrow_upward_rounded,
      AttendanceTrend.down => Icons.arrow_downward_rounded,
      AttendanceTrend.stable => Icons.remove_rounded,
    };
    final trendColor = switch (trend) {
      AttendanceTrend.up => AppColors.success,
      AttendanceTrend.down => AppColors.danger,
      AttendanceTrend.stable => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_rounded, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success),
          ),
          const SizedBox(width: 3),
          Icon(trendIcon, size: 12, color: trendColor),
        ],
      ),
    );
  }
}

Color statusIndicatorColor(ChildStatusIndicator indicator) => switch (indicator) {
      ChildStatusIndicator.green => AppColors.success,
      ChildStatusIndicator.yellow => AppColors.accent,
      ChildStatusIndicator.red => AppColors.danger,
    };

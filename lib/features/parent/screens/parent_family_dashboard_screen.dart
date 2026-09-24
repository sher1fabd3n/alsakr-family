import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../state/parent_child_context.dart';
import '../widgets/family_child_card.dart';
import 'parent_child_hub_screen.dart';
import 'parent_family_overview_screen.dart';
import 'parent_family_transport_screen.dart';

class ParentFamilyDashboardScreen extends StatefulWidget {
  const ParentFamilyDashboardScreen({super.key});

  @override
  State<ParentFamilyDashboardScreen> createState() => _ParentFamilyDashboardScreenState();
}

class _ParentFamilyDashboardScreenState extends State<ParentFamilyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = context.read<ParentChildContext>();
      if (ctx.family == null && !ctx.isLoading) ctx.bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<ParentChildContext>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ctx.refreshFamily();
          if (ctx.activeStudentId != null) {
            await ctx.refreshActiveChildData();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'لوحة العائلة',
                subtitle: ctx.childCount > 0 ? '${ctx.childCount} أبناء مرتبطين' : 'متابعة أبنائك',
              ),
            ),
            if (ctx.isLoading && ctx.family == null)
              const SliverToBoxAdapter(child: FamilyDashboardSkeleton())
            else if (ctx.error != null && ctx.family == null)
              SliverFillRemaining(child: Center(child: Text(ctx.error!)))
            else if (ctx.children.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('لا يوجد أبناء مرتبطون بحسابك.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeSlideIn(
                      child: AppCard(
                        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('مرحباً بك', style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'تابع ${ctx.childCount} أبناء من مكان واحد',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 40),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ParentFamilyOverviewScreen()),
                            ),
                            icon: const Icon(Icons.dashboard_customize_rounded),
                            label: const Text('نظرة عامة'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ParentFamilyTransportScreen()),
                            ),
                            icon: const Icon(Icons.directions_bus_rounded),
                            label: const Text('النقل'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'أبنائي'),
                    const SizedBox(height: 12),
                    ...ctx.children.asMap().entries.map((entry) {
                      final child = entry.value;
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 60 * entry.key),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: FamilyChildCard(
                            child: child,
                            onTap: () async {
                              await ctx.selectChild(child.studentId);
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ParentChildHubScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

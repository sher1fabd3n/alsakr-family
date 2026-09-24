import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../models/parent_family_models.dart';
import '../services/parent_family_service.dart';
import '../widgets/child_switcher.dart';
import '../../transportation/screens/live_tracking_screen.dart';
import '../../transportation/screens/transportation_dashboard_screen.dart';

class ParentFamilyTransportScreen extends StatefulWidget {
  const ParentFamilyTransportScreen({super.key});

  @override
  State<ParentFamilyTransportScreen> createState() => _ParentFamilyTransportScreenState();
}

class _ParentFamilyTransportScreenState extends State<ParentFamilyTransportScreen> {
  late Future<FamilyTransportationSummary> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ParentFamilyService>().getFamilyTransportation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _future;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'نقل العائلة',
                subtitle: 'معلومات النقل لجميع الأبناء',
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ChildSwitcher(compact: true, height: 120),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: FutureBuilder<FamilyTransportationSummary>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', ''))),
                    );
                  }

                  final data = snapshot.data!;
                  if (data.routes.isEmpty && data.privateTransportChildren.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('لا توجد بيانات نقل.')));
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (data.routes.isNotEmpty) ...[
                        const SectionHeader(title: 'ملخص الرحلات المشتركة'),
                        const SizedBox(height: 12),
                        ...data.routes.asMap().entries.map((entry) {
                          final route = entry.value;
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 * entry.key),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RouteCard(route: route),
                            ),
                          );
                        }),
                      ],
                      if (data.privateTransportChildren.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const SectionHeader(title: 'نقل خاص'),
                        const SizedBox(height: 12),
                        ...data.privateTransportChildren.asMap().entries.map((entry) {
                          final child = entry.value;
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 * entry.key),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransportationDashboardScreen(studentId: child.studentId),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(child.name.isNotEmpty ? child.name[0] : '?'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(child.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                          Text(child.transportationTypeAr,
                                              style: const TextStyle(color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_left_rounded),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final FamilyTransportationRoute route;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_bus_rounded, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.routeName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    if (route.busNumber != null)
                      Text('${route.busNumber}', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if (route.driverName != null || route.supervisorName != null) ...[
            const SizedBox(height: 14),
            if (route.driverName != null)
              _ContactRow(label: 'السائق', name: route.driverName!, phone: route.driverPhone),
            if (route.supervisorName != null)
              _ContactRow(label: 'المشرف', name: route.supervisorName!, phone: route.supervisorPhone),
          ],
          const SizedBox(height: 14),
          const Text('الأبناء على هذا الخط', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...route.children.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${c.name} • ${c.grade}')),
                  IconButton(
                    tooltip: 'تتبع مباشر',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LiveTrackingScreen(studentId: c.studentId)),
                    ),
                    icon: const Icon(Icons.map_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.name, this.phone});

  final String label;
  final String name;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (phone != null && phone!.isNotEmpty)
            Text(phone!, textDirection: TextDirection.ltr, style: const TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }
}

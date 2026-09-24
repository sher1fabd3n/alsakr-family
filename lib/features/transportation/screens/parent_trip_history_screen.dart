import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/transportation_models.dart';
import '../services/transportation_service.dart';
import 'transport_notifications_screen.dart';

class ParentTripHistoryScreen extends StatefulWidget {
  const ParentTripHistoryScreen({super.key, this.studentId});

  final int? studentId;

  @override
  State<ParentTripHistoryScreen> createState() => _ParentTripHistoryScreenState();
}

class _ParentTripHistoryScreenState extends State<ParentTripHistoryScreen> {
  late Future<List<ParentTripHistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<TransportationService>().getParentTripHistory(studentId: widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل النقل'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الرحلات'),
              Tab(text: 'الإشعارات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: FutureBuilder<List<ParentTripHistoryItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text('${snapshot.error}'))]);
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد رحلات سابقة.'))),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('رحلة #${item.tripId} • ${item.tripType}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text('${item.routeName} • ${item.busNumber} • ${item.driverName}'),
                                const SizedBox(height: 8),
                                if (item.startedAt != null) Text('بدء: ${dateFormat.format(item.startedAt!.toLocal())}'),
                                if (item.boardedAt != null) Text('صعود: ${dateFormat.format(item.boardedAt!.toLocal())}', style: const TextStyle(color: AppColors.success)),
                                if (item.droppedAtSchoolAt != null)
                                  Text('وصول المدرسة: ${dateFormat.format(item.droppedAtSchoolAt!.toLocal())}', style: const TextStyle(color: AppColors.primary)),
                                if (item.arrivedHomeAt != null)
                                  Text('وصول المنزل: ${dateFormat.format(item.arrivedHomeAt!.toLocal())}', style: const TextStyle(color: Color(0xFF2563EB))),
                                const SizedBox(height: 6),
                                Chip(label: Text(item.studentStatus), visualDensity: VisualDensity.compact),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            TransportNotificationsScreen(studentId: widget.studentId),
          ],
        ),
      ),
    );
  }
}

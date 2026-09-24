import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../transportation/models/transportation_models.dart';
import '../services/driver_service.dart';

class DriverAttendanceScreen extends StatefulWidget {
  const DriverAttendanceScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends State<DriverAttendanceScreen> {
  late Future<List<DriverAttendanceStudent>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<DriverService>().getTripAttendance(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حضور الحافلة')),
      body: FutureBuilder<List<DriverAttendanceStudent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(_reload),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final attendance = snapshot.data ?? [];
          final boarded = attendance.where((s) => s.isBoarded).toList();
          final missing = attendance.where((s) => s.isMissing || s.tripStatus == 'Pending' || s.tripStatus == 'Approaching' || s.tripStatus == 'Arrived').toList();
          final delivered = attendance.where((s) => s.isDelivered).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SummaryRow(boarded: boarded.length, missing: missing.length, delivered: delivered.length),
                const SizedBox(height: 20),
                _Section(
                  title: 'على الحافلة',
                  color: AppColors.success,
                  students: boarded,
                  tripId: widget.tripId,
                  onChanged: () => setState(_reload),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'لم يُلتقطوا / غائبون',
                  color: AppColors.accent,
                  students: missing,
                  tripId: widget.tripId,
                  onChanged: () => setState(_reload),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'تم التوصيل',
                  color: const Color(0xFF2563EB),
                  students: delivered,
                  tripId: widget.tripId,
                  onChanged: () => setState(_reload),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.boarded, required this.missing, required this.delivered});

  final int boarded;
  final int missing;
  final int delivered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _box('على الحافلة', boarded, AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _box('لم يُلتقطوا', missing, AppColors.accent)),
        const SizedBox(width: 8),
        Expanded(child: _box('تم التوصيل', delivered, const Color(0xFF2563EB))),
      ],
    );
  }

  Widget _box(String label, int count, Color color) => AppCard(
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.color,
    required this.students,
    required this.tripId,
    required this.onChanged,
  });

  final String title;
  final Color color;
  final List<DriverAttendanceStudent> students;
  final int tripId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 8),
        if (students.isEmpty)
          const AppCard(child: Text('لا يوجد طلاب في هذه الفئة'))
        else
          ...students.map((s) => AppCard(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text('${s.grade} • ${_statusAr(s.tripStatus)}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (status) => _update(context, s.studentId, status),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'Boarded', child: Text('تم الالتقاط / صعد')),
                      PopupMenuItem(value: 'DroppedAtSchool', child: Text('وصل المدرسة')),
                      PopupMenuItem(value: 'ArrivedHome', child: Text('وصل المنزل')),
                      PopupMenuItem(value: 'Absent', child: Text('غائب')),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  String _statusAr(String status) {
    switch (status) {
      case 'Boarded':
        return 'على الحافلة';
      case 'OnWayHome':
        return 'في طريق العودة';
      case 'DroppedAtSchool':
        return 'نزل في المدرسة';
      case 'ArrivedHome':
        return 'وصل المنزل';
      case 'Absent':
        return 'غائب';
      default:
        return 'لم يُلتقط';
    }
  }

  Future<void> _update(BuildContext context, int studentId, String status) async {
    final service = context.read<DriverService>();
    await service.updateStudentStatus(tripId, studentId, status);
    onChanged();
  }
}

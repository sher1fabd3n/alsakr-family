import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../transportation/models/transportation_models.dart';
import '../models/driver_models.dart';
import '../services/driver_location_tracker.dart';
import '../services/driver_service.dart';
import 'driver_attendance_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  late Future<DriverDashboard> _future;
  DriverLocationTracker? _tracker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tracker?.stop();
    super.dispose();
  }

  void _load() {
    _future = context.read<DriverService>().getDashboard().then((dashboard) {
      final activeTrip = dashboard.activeTrip;
      if (activeTrip != null && _tracker == null) {
        _tracker = DriverLocationTracker(context.read<DriverService>());
        _tracker!.start(activeTrip.id);
      }
      return dashboard;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تطبيق السائق')),
      floatingActionButton: FutureBuilder<DriverDashboard>(
        future: _future,
        builder: (context, snapshot) {
          final trip = snapshot.data?.activeTrip;
          if (trip == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: Colors.red.shade700,
            onPressed: () => _triggerPanic(trip.id),
            icon: const Icon(Icons.emergency_rounded),
            label: const Text('طوارئ'),
          );
        },
      ),
      body: FutureBuilder<DriverDashboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data!;
          if (!data.hasBus) {
            return const Center(child: Text('لا توجد حافلة مرتبطة بحسابك.'));
          }

          final activeTrip = data.activeTrip;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.routeName} • ${data.busNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      if (data.supervisorName != null)
                        Text('المشرف: ${data.supervisorName} • ${data.supervisorPhone ?? ''}'),
                    ],
                  ),
                ),
                if (data.occupancy != null) ...[
                  const SizedBox(height: 12),
                  _OccupancyPanel(occupancy: data.occupancy!),
                ],
                const SizedBox(height: 16),
                if (activeTrip == null) ...[
                  _TripButton(label: 'بدء رحلة الذهاب', icon: Icons.wb_sunny_rounded, onPressed: () => _startTrip('Morning')),
                  _TripButton(label: 'بدء رحلة العودة', icon: Icons.nights_stay_rounded, onPressed: () => _startTrip('Afternoon')),
                  _TripButton(label: 'رحلة مخصصة', icon: Icons.alt_route_rounded, onPressed: () => _startTrip('Custom')),
                ] else ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رحلة نشطة #${activeTrip.id}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text('الحالة: ${activeTrip.status} • ${activeTrip.tripType}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await context.read<DriverService>().pauseTrip(activeTrip.id);
                                  await _tracker?.stop();
                                  setState(_load);
                                },
                                child: const Text('إيقاف مؤقت'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  await context.read<DriverService>().completeTrip(activeTrip.id);
                                  await _tracker?.stop();
                                  _tracker = null;
                                  setState(_load);
                                },
                                child: const Text('إنهاء الرحلة'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () async {
                            await context.read<DriverService>().resumeTrip(activeTrip.id);
                            _tracker ??= DriverLocationTracker(context.read<DriverService>());
                            await _tracker!.start(activeTrip.id);
                            setState(_load);
                          },
                          child: const Text('استئناف الرحلة'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DriverAttendanceScreen(tripId: activeTrip.id),
                              ),
                            );
                            if (mounted) setState(_load);
                          },
                          icon: const Icon(Icons.fact_check_rounded),
                          label: const Text('شاشة الحضور'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('الطلاب على الحافلة', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ...data.attendance.isNotEmpty
                    ? data.attendance.map(
                        (s) => _StudentAttendanceTile(
                          student: s,
                          tripId: activeTrip?.id,
                          onStatusChanged: () {
                            if (mounted) setState(_load);
                          },
                        ),
                      )
                    : data.students.map((s) => AppCard(
                          child: ListTile(
                            leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                            title: Text(s.name),
                            subtitle: Text('${s.grade} • ${s.stopName ?? ''}'),
                          ),
                        )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _startTrip(String type) async {
    final service = context.read<DriverService>();
    final tripId = await service.startTrip(tripType: type);
    _tracker = DriverLocationTracker(service);
    await _tracker!.start(tripId);
    setState(_load);
  }

  Future<void> _triggerPanic(int tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الطوارئ'),
        content: const Text('سيتم إرسال تنبيه فوري للإدارة والمشرف مع موقعك الحالي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<DriverService>().triggerEmergency(
            tripId: tripId,
            message: 'طلب طوارئ من السائق',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال تنبيه الطوارئ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _OccupancyPanel extends StatelessWidget {
  const _OccupancyPanel({required this.occupancy});

  final BusOccupancy occupancy;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إشغال الحافلة', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('معينين', occupancy.totalAssigned, AppColors.primary),
              _chip('على الحافلة', occupancy.onBus, AppColors.success),
              _chip('لم يُلتقطوا', occupancy.notYetPickedUp, AppColors.accent),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('تم التوصيل', occupancy.delivered, const Color(0xFF2563EB)),
              _chip('غائبون', occupancy.missing, Colors.red.shade400),
              _chip('السعة', occupancy.busCapacity, AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int value, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text('$value', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _StudentAttendanceTile extends StatelessWidget {
  const _StudentAttendanceTile({
    required this.student,
    this.tripId,
    this.onStatusChanged,
  });

  final DriverAttendanceStudent student;
  final int? tripId;
  final VoidCallback? onStatusChanged;

  Color get _color {
    if (student.isDelivered) return AppColors.success;
    if (student.isBoarded) return const Color(0xFF2563EB);
    if (student.isMissing) return Colors.red;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: _color.withValues(alpha: 0.15), child: Icon(Icons.person, color: _color)),
          title: Text(student.name),
          subtitle: Text('${student.grade} • ${student.stopName ?? ''} • ${student.tripStatus}'),
          trailing: tripId != null
              ? PopupMenuButton<String>(
                  onSelected: (status) async {
                    try {
                      await context.read<DriverService>().updateStudentStatus(
                            tripId!,
                            student.studentId,
                            status,
                          );
                    } catch (_) {}
                    onStatusChanged?.call();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'Boarded', child: Text('تم الالتقاط / صعد')),
                    PopupMenuItem(value: 'DroppedAtSchool', child: Text('نزل — المدرسة')),
                    PopupMenuItem(value: 'ArrivedHome', child: Text('وصل المنزل')),
                    PopupMenuItem(value: 'Absent', child: Text('غائب')),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _TripButton extends StatelessWidget {
  const _TripButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
    );
  }
}

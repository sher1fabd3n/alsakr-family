import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../features/parent/state/parent_child_context.dart';
import '../../../services/student_services.dart';
import '../models/transportation_models.dart';
import '../services/transportation_service.dart';
import 'live_tracking_screen.dart';
import 'private_driver_declaration_screen.dart';
import 'private_driver_form_screen.dart';
import 'transportation_card_screen.dart';

class TransportationDashboardScreen extends StatefulWidget {
  const TransportationDashboardScreen({super.key, this.studentId});

  final int? studentId;

  @override
  State<TransportationDashboardScreen> createState() => _TransportationDashboardScreenState();
}

class _TransportationDashboardScreenState extends State<TransportationDashboardScreen> {
  late Future<TransportDashboard> _future;
  late Future<TransportationCardData?> _cardFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final service = context.read<TransportationService>();
    _future = service.getDashboard(studentId: widget.studentId);
    _cardFuture = _loadCard(service);
  }

  Future<TransportationCardData?> _loadCard(TransportationService service) async {
    try {
      return await service.getCard(studentId: widget.studentId);
    } catch (_) {
      return null;
    }
  }

  void _openPrivateForm({String? studentName, String? grade}) {
    final child = context.read<ParentChildContext>().activeChild;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PrivateDriverFormScreen(
              studentId: widget.studentId ?? child?.studentId ?? 0,
              studentName: studentName ?? child?.name,
              studentGrade: grade ?? child?.grade,
            ),
          ),
        )
        .then((_) {
      if (mounted) setState(_load);
    });
  }

  void _openDeclaration(TransportationCardData card) {
    final parent = context.read<AuthService>().currentParent;
    final private = card.private;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivateDriverDeclarationScreen(
          initial: PrivateDriverDeclarationData(
            studentId: widget.studentId ?? 0,
            studentName: card.studentName,
            grade: card.grade,
            stage: '',
            academicYear: '2026 / 2027',
            driverName: private?.driverFullName ?? '',
            driverPhone: private?.driverPhone ?? '',
            driverNationalId: private?.nationalIdNumber ?? '',
            parentName: parent?.fullName ?? '',
            parentPhone: parent?.phone ?? '',
            relationship: parent?.parentType.labelAr ?? 'ولي أمر',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النقل المدرسي')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await Future.wait([_future, _cardFuture]);
        },
        child: FutureBuilder<TransportDashboard>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                  ),
                ],
              );
            }
            final data = snapshot.data!;

            if (data.isPrivate) {
              return _buildPrivateBody(data);
            }
            return _buildSchoolBusBody(data);
          },
        ),
      ),
    );
  }

  Widget _buildSchoolBusBody(TransportDashboard data) {
    final tripActive = data.hasActiveTrip;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tripActive
                    ? const [Color(0xFF166534), Color(0xFF22C55E)]
                    : const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حالة الرحلة',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  tripActive ? 'نشطة' : 'غير نشطة',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  data.routeName ?? 'حافلة مدرسية',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<TransportationCardData?>(
          future: _cardFuture,
          builder: (context, cardSnap) {
            final card = cardSnap.data;
            if (card?.schoolBus == null) {
              return const AppCard(child: Text('لا توجد بيانات حافلة مرتبطة حالياً'));
            }
            final bus = card!.schoolBus!;
            return FadeSlideIn(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'بيانات الرحلة'),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.person_rounded, label: 'اسم السائق', value: bus.driverName.isEmpty ? '—' : bus.driverName),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.supervisor_account_rounded, label: 'اسم المشرفة', value: bus.supervisorName.isEmpty ? '—' : bus.supervisorName),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.phone_rounded, label: 'تليفون المشرفة', value: bus.supervisorPhone.isEmpty ? '—' : bus.supervisorPhone),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        if (tripActive)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveTrackingScreen(
                  studentId: widget.studentId,
                  tripId: data.activeTripId,
                ),
              ),
            ),
            icon: const Icon(Icons.map_rounded),
            label: const Text('تتبع مباشر للرحلة'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.success,
            ),
          )
        else
          AppCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'التتبع المباشر يظهر فقط عندما تكون الرحلة نشطة.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.badge_rounded,
          title: 'بطاقة النقل',
          subtitle: 'عرض البطاقة',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransportationCardScreen(studentId: widget.studentId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateBody(TransportDashboard data) {
    return FutureBuilder<TransportationCardData?>(
      future: _cardFuture,
      builder: (context, cardSnap) {
        if (cardSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final card = cardSnap.data;
        final private = card?.private;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFC68400), Color(0xFFFFB000)]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نقل خاص',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'تسجيل بيانات السائق الخاص وإقرار الاستلام',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (private == null) ...[
              const AppCard(
                child: Text(
                  'لم يتم تسجيل سائق خاص بعد. أدخل الاسم والرقم القومي ورقم التليفون وارفع صورة البطاقة (وجه وظهر).',
                  style: TextStyle(height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openPrivateForm(
                  studentName: card?.studentName,
                  grade: card?.grade,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('إضافة بيانات السائق الخاص'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ] else ...[
              FadeSlideIn(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'بيانات السائق الخاص'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.person_rounded, label: 'اسم السائق', value: private.driverFullName),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.phone_rounded, label: 'رقم التليفون', value: private.driverPhone),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.badge_rounded, label: 'الرقم القومي', value: private.nationalIdNumber),
                      if (private.nationalIdFrontUrl != null || private.nationalIdBackUrl != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'تم رفع صور البطاقة',
                          style: TextStyle(color: AppColors.success.withValues(alpha: 0.95), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openDeclaration(card!),
                icon: const Icon(Icons.description_rounded),
                label: const Text('عرض / تعبئة الإقرار وتصدير PDF'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openPrivateForm(
                  studentName: card?.studentName,
                  grade: card?.grade,
                ),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل بيانات السائق'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.badge_rounded,
                title: 'بطاقة النقل',
                subtitle: 'عرض البطاقة',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransportationCardScreen(studentId: widget.studentId),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
          trailing: const Icon(Icons.chevron_left_rounded),
        ),
      ),
    );
  }
}

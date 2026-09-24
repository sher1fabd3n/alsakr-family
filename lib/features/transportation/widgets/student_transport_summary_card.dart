import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../parent/state/parent_child_context.dart';
import '../../parent/widgets/child_photo_actions.dart';
import '../models/transportation_models.dart';
import '../screens/transportation_card_screen.dart';
import '../screens/transportation_dashboard_screen.dart';
import '../services/transportation_service.dart';
import '../widgets/transportation_id_card.dart';

class StudentTransportSummaryCard extends StatefulWidget {
  const StudentTransportSummaryCard({
    super.key,
    this.studentId,
    this.titleOnly = false,
  });

  final int? studentId;
  /// في الرئيسية: عنوان فقط دون بيانات البطاقة.
  final bool titleOnly;

  @override
  State<StudentTransportSummaryCard> createState() => _StudentTransportSummaryCardState();
}

class _StudentTransportSummaryCardState extends State<StudentTransportSummaryCard> {
  late Future<TransportationCardData?> _future;
  int _seenPhotoRevision = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StudentTransportSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      setState(_load);
    }
  }

  void _load() {
    _future = _loadCard();
  }

  Future<TransportationCardData?> _loadCard() async {
    try {
      return await context.read<TransportationService>().getCard(studentId: widget.studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoRevision = context.watch<ParentChildContext>().photoRevision;
    if (_seenPhotoRevision != photoRevision) {
      _seenPhotoRevision = photoRevision;
      if (_seenPhotoRevision > 0) {
        _future = _loadCard();
      }
    }
    if (widget.titleOnly) {
      return FadeSlideIn(
        child: AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransportationDashboardScreen(studentId: widget.studentId),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'النقل المدرسي',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: AppColors.textMuted.withValues(alpha: 0.8)),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<TransportationCardData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final card = snapshot.data;
        if (card == null) {
          return FadeSlideIn(
            child: AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TransportationDashboardScreen(studentId: widget.studentId)),
              ),
              child: const ListTile(
                leading: Icon(Icons.directions_bus_rounded, color: AppColors.primary),
                title: Text('النقل المدرسي', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('لم يتم تحديد نوع النقل بعد'),
                trailing: Icon(Icons.chevron_left_rounded),
              ),
            ),
          );
        }

        return FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransportationIdCard(
                card: card,
                studentId: widget.studentId,
                onPhotoTap: widget.studentId == null
                    ? null
                    : () => ChildPhotoActions.pickAndUpload(context, widget.studentId!),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransportationCardScreen(studentId: widget.studentId),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('عرض البطاقة كاملة'),
              ),
            ],
          ),
        );
      },
    );
  }
}

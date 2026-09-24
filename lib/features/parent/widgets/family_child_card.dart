import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/student_avatar.dart';
import '../models/parent_family_models.dart';
import '../widgets/child_switcher.dart';
import 'child_photo_actions.dart';

class FamilyChildCard extends StatelessWidget {
  const FamilyChildCard({super.key, required this.child, required this.onTap});

  final ChildDashboardSummary child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = statusIndicatorColor(child.statusIndicator);
    final currency = NumberFormat('#,##0', 'ar');

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(
                studentId: child.studentId,
                name: child.name,
                photoUrl: child.profilePhotoUrl,
                radius: 28,
                onEditPhoto: () => ChildPhotoActions.pickAndUpload(context, child.studentId),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مدرسة الصقر للغات',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(child.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    Text('كود السيستم ${child.rollNo} • ${child.grade}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(icon: Icons.directions_bus_rounded, label: child.transportationTypeAr),
              _Chip(icon: Icons.event_available_rounded, label: '${child.attendancePercentage.toStringAsFixed(0)}% حضور'),
              if (child.outstandingFees > 0)
                _Chip(
                  icon: Icons.payments_rounded,
                  label: 'متبقي ${currency.format(child.outstandingFees)}',
                  color: AppColors.danger,
                ),
              if (child.pendingHomeworkCount > 0)
                _Chip(icon: Icons.assignment_rounded, label: '${child.pendingHomeworkCount} واجب'),
            ],
          ),
          if (child.routeName != null) ...[
            const SizedBox(height: 10),
            Text('${child.routeName}${child.busNumber != null ? ' • ${child.busNumber}' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

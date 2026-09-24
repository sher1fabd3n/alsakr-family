import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../models/communication_models.dart';
import '../services/communication_service.dart';

class AnnouncementCenterScreen extends StatefulWidget {
  const AnnouncementCenterScreen({super.key});

  @override
  State<AnnouncementCenterScreen> createState() => _AnnouncementCenterScreenState();
}

class _AnnouncementCenterScreenState extends State<AnnouncementCenterScreen> {
  late Future<List<AnnouncementItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<CommunicationService>().getAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات المدرسية')),
      body: FutureBuilder<List<AnnouncementItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد إعلانات حالياً'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(title: 'آخر الإعلانات'),
              const SizedBox(height: 12),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                return FadeSlideIn(
                  delay: Duration(milliseconds: 60 * entry.key),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (item.isEmergency)
                                const Chip(
                                  label: Text('عاجل'),
                                  backgroundColor: Color(0xFFFFE4E6),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.body),
                          if (item.sentAt != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              DateFormat('yyyy/MM/dd HH:mm').format(item.sentAt!.toLocal()),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

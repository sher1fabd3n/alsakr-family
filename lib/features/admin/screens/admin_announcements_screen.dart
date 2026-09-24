import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../communication/models/communication_models.dart';
import '../services/admin_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _searchController = TextEditingController();
  late Future<List<AnnouncementItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AdminService>().getAnnouncements(
          search: _searchController.text.trim(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جميع الإعلانات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث في الإعلانات...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => setState(_load),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AnnouncementItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('لا توجد إعلانات'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
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
                          if (item.sentAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('yyyy/MM/dd HH:mm').format(item.sentAt!.toLocal()),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

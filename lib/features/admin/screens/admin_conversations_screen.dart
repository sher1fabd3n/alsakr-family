import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import 'admin_conversation_detail_screen.dart';

class AdminConversationsScreen extends StatefulWidget {
  const AdminConversationsScreen({super.key});

  @override
  State<AdminConversationsScreen> createState() => _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends State<AdminConversationsScreen> {
  final _searchController = TextEditingController();
  final _gradeController = TextEditingController();
  late Future<List<AdminConversationSummary>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AdminService>().searchConversations(
          search: _searchController.text.trim(),
          grade: _gradeController.text.trim().isEmpty
              ? null
              : _gradeController.text.trim(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراقبة المحادثات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث في المحادثات...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(_load),
                    ),
                  ),
                  onSubmitted: (_) => setState(_load),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _gradeController,
                  decoration: InputDecoration(
                    hintText: 'فلترة بالصف (مثل 5/A)',
                    prefixIcon: const Icon(Icons.class_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.filter_alt_rounded),
                      onPressed: () => setState(_load),
                    ),
                  ),
                  onSubmitted: (_) => setState(_load),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AdminConversationSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('لا توجد محادثات'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminConversationDetailScreen(
                            conversation: item,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.studentName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${item.studentGrade} • ${item.teacherName} ↔ ${item.parentName}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          if (item.lastMessagePreview != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.lastMessagePreview!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (item.lastMessageAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('yyyy/MM/dd HH:mm')
                                    .format(item.lastMessageAt!.toLocal()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
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

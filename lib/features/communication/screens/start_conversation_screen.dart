import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../models/communication_models.dart';
import '../services/communication_service.dart';
import '../../parent/models/parent_family_models.dart';
import '../../parent/services/parent_family_service.dart';
import 'conversation_screen.dart';

class StartConversationScreen extends StatefulWidget {
  const StartConversationScreen({super.key});

  @override
  State<StartConversationScreen> createState() => _StartConversationScreenState();
}

class _StartConversationScreenState extends State<StartConversationScreen> {
  int _step = 0;
  List<ChildDashboardSummary> _children = [];
  List<TeacherOfClassItem> _teachers = [];
  ChildDashboardSummary? _selectedChild;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  ParentFamilyService get _familyService => context.read<ParentFamilyService>();
  CommunicationService get _chatService => context.read<CommunicationService>();

  Future<void> _loadChildren() async {
    setState(() { _loading = true; _error = null; });
    try {
      final summary = await _familyService.getFamilyDashboard();
      _children = summary.children;
      setState(() { _loading = false; });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _loading = false; _error = msg; });
    }
  }

  Future<void> _loadTeachers(ChildDashboardSummary child) async {
    if (child.classId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا الطفل غير مسجل في أي فصل حالياً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() { _loading = true; _error = null; _selectedChild = child; _step = 1; });
    try {
      _teachers = await _chatService.getTeachersOfClass(child.classId!);
      setState(() { _loading = false; });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _loading = false; _error = msg; });
    }
  }

  Future<void> _startChat(TeacherOfClassItem teacher) async {
    if (_selectedChild == null) return;
    try {
      final conversationId = await _chatService.startConversation(
        teacherAccountId: teacher.teacherAccountId,
        studentId: _selectedChild!.studentId,
      );
      if (!mounted) return;
      final conversations = await _chatService.getConversations();
      if (!mounted) return;
      final conversation = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => ConversationItem(
          id: conversationId,
          studentId: _selectedChild!.studentId,
          studentName: _selectedChild!.name,
          studentGrade: _selectedChild!.grade,
          teacherName: teacher.fullName,
          parentName: '',
          unreadCount: 0,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conversation)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $msg'), backgroundColor: AppColors.danger),
      );
    }
  }

  String get _title => switch (_step) {
    0 => 'اختر الطفل',
    1 => 'اختر المعلم',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _loadChildren, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_step == 0 && _children.isEmpty) {
      return const Center(child: Text('لا توجد أطفال مرتبطين بحسابك'));
    }
    if (_step == 1 && _teachers.isEmpty) {
      return const Center(child: Text('لا يوجد معلمون مخصصون لهذا الفصل'));
    }

    final items = _step == 0 ? _children : _teachers;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: 40 * index),
          child: _buildItemTile(item),
        );
      },
    );
  }

  Widget _buildItemTile(dynamic item) {
    if (item is ChildDashboardSummary) {
      return AppCard(
        onTap: () => _loadTeachers(item),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              radius: 22,
              child: Text(
                item.name.isNotEmpty ? item.name[0] : 'ط',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    item.grade,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      );
    }

    if (item is TeacherOfClassItem) {
      return AppCard(
        onTap: () => _startChat(item),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../services/parent_family_service.dart';
import '../state/parent_child_context.dart';

class ParentUploadReportScreen extends StatefulWidget {
  const ParentUploadReportScreen({super.key, required this.studentId});

  final int studentId;

  @override
  State<ParentUploadReportScreen> createState() => _ParentUploadReportScreenState();
}

class _ParentUploadReportScreenState extends State<ParentUploadReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'تقرير طبي';
  bool _loading = false;
  String? _fileName;
  List<int>? _fileBytes;

  static const _categories = ['تقرير طبي', 'تقرير عام', 'أخرى'];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _fileBytes = bytes;
      _fileName = picked.name.isNotEmpty ? picked.name : 'report.jpg';
    });
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fileBytes = bytes;
      _fileName = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_fileBytes == null || _fileBytes!.isEmpty) &&
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب نص التقرير أو ارفع ملفاً')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<ParentFamilyService>().uploadChildReport(
            studentId: widget.studentId,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
            category: _category,
            bytes: _fileBytes,
            filename: _fileName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال التقرير إلى الإدارة')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<ParentChildContext>().activeChild;

    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع تقرير'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              child?.name ?? 'تقرير يخص الطالب',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيظهر التقرير فوراً في قسم التقارير بلوحة تحكم الإدارة.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان التقرير',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'نوع التقرير',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'نص التقرير (اختياري إذا رفعت ملفاً)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('صورة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('ملف PDF'),
                  ),
                ),
              ],
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_fileName!)),
                    IconButton(
                      onPressed: () => setState(() {
                        _fileName = null;
                        _fileBytes = null;
                      }),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_loading ? 'جاري الإرسال...' : 'إرسال للإدارة'),
            ),
          ],
        ),
      ),
    );
  }
}

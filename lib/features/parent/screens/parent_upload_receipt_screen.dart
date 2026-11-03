import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../services/parent_family_service.dart';
import '../state/parent_child_context.dart';

class ParentUploadReceiptScreen extends StatefulWidget {
  const ParentUploadReceiptScreen({super.key, required this.studentId});

  final int studentId;

  @override
  State<ParentUploadReceiptScreen> createState() => _ParentUploadReceiptScreenState();
}

class _ParentUploadReceiptScreenState extends State<ParentUploadReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Tuition';
  bool _loading = false;
  String? _fileName;
  List<int>? _fileBytes;

  static const _categories = [
    ('Tuition', 'رسوم دراسية'),
    ('Books', 'كتب'),
    ('Uniform', 'يونيفورم'),
    ('Bus', 'باص'),
    ('Installment1', 'القسط الأول'),
    ('Installment2', 'القسط الثاني'),
    ('OtherFees', 'مصاريف أخرى'),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _fileBytes = bytes;
      _fileName = picked.name.isNotEmpty ? picked.name : 'receipt.jpg';
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
    if (_fileBytes == null || _fileBytes!.isEmpty || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر صورة أو ملف PDF للإيصال')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final msg = await context.read<ParentFamilyService>().uploadChildFeeReceipt(
            studentId: widget.studentId,
            category: _category,
            amount: double.tryParse(_amountController.text.trim()) ?? 0,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            bytes: _fileBytes!,
            filename: _fileName!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      appBar: AppBar(title: const Text('رفع إيصال دفع')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(child?.name ?? 'إيصال دفع', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'ارفع صورة أو PDF للإيصال ليظهر فوراً في إيصالات الطلاب بلوحة الإدارة.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'البند',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                final value = double.tryParse(v?.trim() ?? '');
                if (value == null || value < 0) return 'أدخل مبلغاً صحيحاً';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon: Icon(Icons.notes_outlined),
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
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('ملف PDF'),
                  ),
                ),
              ],
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Text('تم اختيار: $_fileName', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('رفع الإيصال'),
            ),
          ],
        ),
      ),
    );
  }
}

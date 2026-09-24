import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/student_services.dart';
import '../services/transportation_service.dart';
import 'private_driver_declaration_screen.dart';

class PrivateDriverFormScreen extends StatefulWidget {
  const PrivateDriverFormScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.studentGrade,
  });

  final int studentId;
  final String? studentName;
  final String? studentGrade;

  @override
  State<PrivateDriverFormScreen> createState() => _PrivateDriverFormScreenState();
}

class _PrivateDriverFormScreenState extends State<PrivateDriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  bool _loading = false;
  String? _frontImagePath;
  String? _backImagePath;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool front) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('من المعرض'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('من الكاميرا'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() {
      if (front) {
        _frontImagePath = file.path;
      } else {
        _backImagePath = file.path;
      }
    });
  }

  Future<void> _submit({bool openDeclaration = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_frontImagePath == null || _backImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى رفع صورة بطاقة السائق (وجه وظهر)')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final service = context.read<TransportationService>();
      await service.savePrivateDriver(
        studentId: widget.studentId,
        driverFullName: _nameController.text.trim(),
        driverPhone: _phoneController.text.trim(),
        nationalIdNumber: _nationalIdController.text.trim(),
        vehicleType: 'سيارة خاصة',
        vehiclePlateNumber: 'غير محدد',
        relationshipToStudent: 'ولي أمر',
      );
      await service.uploadPrivateDriverImages(
        studentId: widget.studentId,
        frontPath: _frontImagePath,
        backPath: _backImagePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات السائق الخاص')),
      );

      final parent = context.read<AuthService>().currentParent;
      final declaration = PrivateDriverDeclarationData(
        studentId: widget.studentId,
        studentName: widget.studentName ?? '',
        grade: widget.studentGrade ?? '',
        stage: '',
        academicYear: '2026 / 2027',
        driverName: _nameController.text.trim(),
        driverPhone: _phoneController.text.trim(),
        driverNationalId: _nationalIdController.text.trim(),
        parentName: parent?.fullName ?? '',
        parentPhone: parent?.phone ?? '',
        relationship: parent?.parentType.labelAr ?? 'ولي أمر',
      );

      if (openDeclaration) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PrivateDriverDeclarationScreen(initial: declaration),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات السائق الخاص')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نقل خاص',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'أدخل بيانات السائق وارفع صورة البطاقة القومية (وجه وظهر)، ثم يمكنك تعبئة الإقرار وتصديره PDF.',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم السائق',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم تليفون السائق',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الرقم القومي للسائق',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    if (v.trim().length != 14) return 'الرقم القومي يجب أن يكون 14 رقماً';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('بطاقة السائق القومية', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _ImagePickBox(
                      label: 'وجه البطاقة',
                      path: _frontImagePath,
                      onTap: () => _pickImage(true),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _ImagePickBox(
                      label: 'ظهر البطاقة',
                      path: _backImagePath,
                      onTap: () => _pickImage(false),
                    )),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : () => _submit(openDeclaration: true),
                    icon: const Icon(Icons.description_rounded),
                    label: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('حفظ وفتح الإقرار'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => _submit(openDeclaration: false),
                    child: const Text('حفظ فقط'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickBox extends StatelessWidget {
  const _ImagePickBox({
    required this.label,
    required this.path,
    required this.onTap,
  });

  final String label;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          color: AppColors.primary.withValues(alpha: 0.04),
        ),
        clipBehavior: Clip.antiAlias,
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(path!), fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/profile_photo_encoder.dart';
import '../state/parent_child_context.dart';

class ChildPhotoActions {
  static final _picker = ImagePicker();

  static Future<void> pickAndUpload(BuildContext context, int studentId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'رفع صورة الطالب',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
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
    if (source == null || !context.mounted) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );
    if (file == null || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جاري رفع الصورة...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final raw = await file.readAsBytes();
      if (raw.isEmpty) {
        throw Exception('تعذر قراءة الصورة من الجهاز. جرّب صورة أخرى.');
      }
      final jpeg = encodeProfileJpeg(raw);
      if (!context.mounted) return;
      await context.read<ParentChildContext>().updateChildPhoto(studentId, jpeg);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث صورة الطالب')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

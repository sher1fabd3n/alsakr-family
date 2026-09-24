import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../services/app_update_service.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.info});

  final AppUpdateInfo info;

  Future<void> _openDownload() async {
    final raw = info.downloadUrl.trim();
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: AppColors.gradientPrimary,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  const AppLogo(width: 140, padding: EdgeInsets.all(16), borderRadius: 28),
                  const SizedBox(height: 28),
                  const Icon(Icons.system_update_alt_rounded, color: Colors.white, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'تحديث مطلوب',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'إصدارك الحالي: ${info.currentVersion}  •  الأحدث: ${info.latestVersion}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _openDownload,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'تحديث الآن',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

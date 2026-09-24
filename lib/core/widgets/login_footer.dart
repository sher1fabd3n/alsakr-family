import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../constants/app_branding.dart';
import '../theme/app_colors.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  Future<void> _openDeveloperPage() async {
    final uri = Uri.parse(AppBranding.developerFacebookUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: 11,
          height: 1.4,
        );
    final linkStyle = mutedStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppBranding.copyright,
            textAlign: TextAlign.center,
            style: mutedStyle,
          ),
          const SizedBox(height: 4),
          Text(
            ApiConfig.baseUrl,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: mutedStyle?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('تصميم وبرمجة : ', style: mutedStyle),
              InkWell(
                onTap: _openDeveloperPage,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Text(AppBranding.developerName, style: linkStyle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

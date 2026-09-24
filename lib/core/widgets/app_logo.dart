import 'package:flutter/material.dart';

import '../constants/app_branding.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 120,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = Colors.white,
    this.borderRadius = 20,
    this.showShadow = true,
  });

  final double width;
  final EdgeInsets padding;
  final Color backgroundColor;
  final double borderRadius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Image.asset(
        AppBranding.logoAsset,
        fit: BoxFit.contain,
      ),
    );
  }
}

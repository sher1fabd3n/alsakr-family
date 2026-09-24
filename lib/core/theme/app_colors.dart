import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const secondary = Color(0xFF06B6D4);
  static const accent = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFEF4444);

  static const background = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEEF2FF);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const gradientPrimary = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
  ];

  static const gradientWarm = [
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  static const gradientCool = [
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
  ];

  static const navBar = Color(0xFFFFFFFF);
}

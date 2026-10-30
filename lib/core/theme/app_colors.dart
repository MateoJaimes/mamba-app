import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF34D399);
  static const primaryDark = Color(0xFF10B981);
  static const emeraldGlow = Color(0x5534D399);

  // Background
  static const background = Color(0xFF101412);
  static const surface = Color(0xFF191F1C);
  static const surfaceRaised = Color(0xFF222A26);

  // Text
  static const textPrimary = Color(0xFFF2F7F4);
  static const textSecondary = Color(0xFFA2B0A8);

  // Border
  static const border = Color(0x33D7E5DC);

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Base
  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;
}

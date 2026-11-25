import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF59CFC4);
  static const secondary = Color(0xFFC7B6F0);
  static const primaryGlow = Color(0x5559CFC4);

  // Background
  static const background = Color(0xFF0E1B34);
  static const surface = Color(0xFF162642);
  static const surfaceRaised = Color(0xFF233654);

  // Text
  static const textPrimary = Color(0xFFF7F6F1);
  static const textSecondary = Color(0xFFB6C4D8);

  // Border
  static const border = Color(0x33C7D5EB);

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

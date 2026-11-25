import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

abstract final class AppDecoration {
  AppDecoration._();

  static BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.sm,
  );

  static BoxDecoration sheet = BoxDecoration(
    color: AppColors.surfaceRaised,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(AppRadius.xl),
    ),
  );
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/colombian_rating.dart';

class ColombianRatingBadge extends StatelessWidget {
  const ColombianRatingBadge({
    super.key,
    required this.label,
    required this.target,
    this.prominent = false,
    this.overImage = false,
  });

  final String label;
  final ColombianRatingTarget target;
  final bool prominent;
  final bool overImage;

  int get _score {
    final normalized = label.toLowerCase();
    if (target == ColombianRatingTarget.experience) {
      if (normalized.contains('chimba')) return 5;
      if (normalized.contains('planazo')) return 4;
      if (normalized.contains('súper') || normalized.contains('super')) {
        return 3;
      }
      if (normalized.contains('buen parche')) return 2;
      if (normalized.contains('no fue')) return 1;
    } else {
      if (normalized.contains('lució') || normalized.contains('lucio')) {
        return 5;
      }
      if (normalized.contains('energía') || normalized.contains('energia')) {
        return 4;
      }
      if (normalized.contains('buen anfitrión') ||
          normalized.contains('buen anfitrion')) {
        return 3;
      }
      if (normalized.contains('atención normal') ||
          normalized.contains('atencion normal')) {
        return 2;
      }
      if (normalized.contains('volvería') || normalized.contains('volveria')) {
        return 1;
      }
    }
    return 0;
  }

  Color get _accent => switch (_score) {
    5 => const Color(0xFF22E6A0),
    4 => const Color(0xFF39D6C2),
    3 => const Color(0xFFFFC857),
    2 => const Color(0xFFFF9F43),
    1 => const Color(0xFFFF667A),
    _ => AppColors.primary,
  };

  String get _title =>
      target == ColombianRatingTarget.experience ? 'Plan' : 'Anfitrión';

  IconData get _icon => target == ColombianRatingTarget.experience
      ? Icons.local_activity_rounded
      : Icons.handshake_rounded;

  @override
  Widget build(BuildContext context) {
    final compact = !prominent;
    final foreground = overImage ? Colors.white : _accent;
    final background = overImage
        ? const Color(0xD91A211E)
        : _accent.withValues(alpha: prominent ? .18 : .13);
    final border = overImage
        ? _accent.withValues(alpha: .8)
        : _accent.withValues(alpha: .42);

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: overImage ? 14 : 0,
          sigmaY: overImage ? 14 : 0,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: prominent ? 14 : 10,
            vertical: prominent ? 10 : 6,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: border, width: prominent ? 1.2 : .9),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: overImage ? .32 : .13),
                blurRadius: prominent ? 18 : 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: prominent ? 18 : 14, color: foreground),
              SizedBox(width: compact ? 5 : 7),
              if (prominent) ...[
                Text(
                  '$_title · ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground.withValues(alpha: .82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              Text(
                label,
                style:
                    (prominent
                            ? Theme.of(context).textTheme.labelLarge
                            : Theme.of(context).textTheme.labelSmall)
                        ?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .1,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

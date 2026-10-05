import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressPercentBar extends StatelessWidget {
  final String label;
  final double used;
  final double cap;
  final String unit;
  final Color barColor;

  const ProgressPercentBar({
    super.key,
    required this.label,
    required this.used,
    required this.cap,
    required this.unit,
    this.barColor = AppTheme.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = cap > 0 ? (used / cap).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);
    final isNearFull = ratio >= 0.9;
    final effectiveColor = isNearFull ? AppTheme.warningAmber : barColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${used.toStringAsFixed(1)} / ${cap.toStringAsFixed(1)} $unit ($percent%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/enums.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusChip.fromTripStatus(TripStatus status) {
    Color bg;
    Color fg;
    IconData? icon;

    switch (status) {
      case TripStatus.draft:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        icon = Icons.edit_note;
        break;
      case TripStatus.confirmed:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        icon = Icons.verified_outlined;
        break;
      case TripStatus.loading:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        icon = Icons.inventory_2_outlined;
        break;
      case TripStatus.loaded:
        bg = AppTheme.primaryLight;
        fg = AppTheme.primaryDark;
        icon = Icons.check_box_outlined;
        break;
      case TripStatus.inProgress:
        bg = Colors.indigo.shade100;
        fg = Colors.indigo.shade800;
        icon = Icons.local_shipping_outlined;
        break;
      case TripStatus.completed:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon = Icons.task_alt;
        break;
      case TripStatus.blocked:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        icon = Icons.block;
        break;
      case TripStatus.cancelled:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade800;
        icon = Icons.cancel_outlined;
        break;
    }

    final name = status.name.toUpperCase();
    return StatusChip(
      label: name,
      backgroundColor: bg,
      textColor: fg,
      icon: icon,
    );
  }

  factory StatusChip.fromStopStatus(StopStatus status, {bool isPendingSync = false}) {
    Color bg;
    Color fg;
    IconData? icon = isPendingSync ? Icons.access_time : null;

    switch (status) {
      case StopStatus.pending:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        icon ??= Icons.hourglass_empty;
        break;
      case StopStatus.arrived:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        icon ??= Icons.pin_drop_outlined;
        break;
      case StopStatus.delivered:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon ??= Icons.check_circle_outline;
        break;
      case StopStatus.partial:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        icon ??= Icons.pie_chart_outline;
        break;
      case StopStatus.failed:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        icon ??= Icons.error_outline;
        break;
      case StopStatus.exception:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFF9A3412);
        icon ??= Icons.report_problem_outlined;
        break;
      case StopStatus.skipped:
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF64748B);
        icon ??= Icons.skip_next_outlined;
        break;
    }

    final name = status.name.toUpperCase();
    return StatusChip(
      label: isPendingSync ? '$name (PENDING)' : name,
      backgroundColor: bg,
      textColor: fg,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

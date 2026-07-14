import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum StatusType { active, inactive, maintenance, completed, inProgress, pending, closed, present, absent, holiday, critical, warning, info, low, normal }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.small = false,
  });

  factory StatusBadge.fromString(String status, {bool small = false}) {
    final statusMap = {
      'active': StatusType.active,
      'inactive': StatusType.inactive,
      'maintenance': StatusType.maintenance,
      'completed': StatusType.completed,
      'in_progress': StatusType.inProgress,
      'pending': StatusType.pending,
      'closed': StatusType.closed,
      'present': StatusType.present,
      'absent': StatusType.absent,
      'holiday': StatusType.holiday,
      'critical': StatusType.critical,
      'warning': StatusType.warning,
      'info': StatusType.info,
      'low': StatusType.low,
      'normal': StatusType.normal,
    };

    final labelMap = {
      'active': 'Active',
      'inactive': 'Inactive',
      'maintenance': 'Maintenance',
      'completed': 'Completed',
      'in_progress': 'In Progress',
      'pending': 'Pending',
      'closed': 'Closed',
      'present': 'Present',
      'absent': 'Absent',
      'holiday': 'Holiday',
      'critical': 'Critical',
      'warning': 'Warning',
      'info': 'Info',
      'low': 'Low Stock',
      'normal': 'Normal',
    };

    return StatusBadge(
      label: labelMap[status] ?? status,
      type: statusMap[status] ?? StatusType.info,
      small: small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 5 : 6,
            height: small ? 5 : 6,
            decoration: BoxDecoration(
              color: colors.$2,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: colors.$2,
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (type) {
      case StatusType.active:
      case StatusType.completed:
      case StatusType.closed:
      case StatusType.present:
      case StatusType.normal:
        return (AppColors.successBg, AppColors.successLight);
      case StatusType.inactive:
      case StatusType.absent:
        return (AppColors.errorBg, AppColors.errorLight);
      case StatusType.maintenance:
      case StatusType.inProgress:
      case StatusType.warning:
        return (AppColors.warningBg, AppColors.warningLight);
      case StatusType.pending:
      case StatusType.info:
        return (AppColors.infoBg, AppColors.infoLight);
      case StatusType.holiday:
        return (const Color(0xFFF5F3FF), const Color(0xFF7C3AED));
      case StatusType.critical:
      case StatusType.low:
        return (AppColors.errorBg, AppColors.errorLight);
    }
  }
}

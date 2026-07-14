import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../providers/alerts_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    // Group alerts by read status
    final unread = alertsState.alerts.where((a) => !a.isRead).toList();
    final read = alertsState.alerts.where((a) => a.isRead).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operational Alert Center',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Monitor automated alerts for low inventory, missed visits, or inactivity',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (unread.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(alertsProvider.notifier).markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('All alerts marked as read.')),
                      );
                    },
                    icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                    label: const Text('Mark All as Read'),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab bar like container or scrollable sections
            Expanded(
              child: alertsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : alertsState.alerts.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.notifications_none,
                          title: 'No Operational Alerts',
                          message:
                              'All system checks are running normally. No warnings flagged.',
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (unread.isNotEmpty) ...[
                                Text('Unread Alerts (${unread.length})',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 12),
                                ...unread.map((alert) =>
                                    _buildAlertCard(context, ref, alert)),
                                const SizedBox(height: 24),
                              ],
                              if (read.isNotEmpty) ...[
                                Text('Acknowledged / History',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textMuted)),
                                const SizedBox(height: 12),
                                ...read.map((alert) =>
                                    _buildAlertCard(context, ref, alert)),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, dynamic alert) {
    final severityColor = _alertColor(alert.severity);
    final borderCol = severityColor.withValues(alpha: 0.3);
    final bgCol = alert.isRead ? Colors.white : _alertBg(alert.severity);

    return Card(
      color: bgCol,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: alert.isRead ? AppColors.border : borderCol, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(_alertIcon(alert.type), color: severityColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: GoogleFonts.inter(
                            fontWeight: alert.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppDateUtils.timeAgo(alert.createdAt),
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (alert.unitName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Target Unit: ${alert.unitName}',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (!alert.isRead) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.check, size: 18),
                color: AppColors.primary,
                tooltip: 'Acknowledge',
                onPressed: () {
                  ref.read(alertsProvider.notifier).markAsRead(alert.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert acknowledged.')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _alertBg(String s) => s == 'critical'
      ? AppColors.errorBg
      : s == 'warning'
          ? AppColors.warningBg
          : AppColors.infoBg;
  Color _alertColor(String s) => s == 'critical'
      ? AppColors.errorLight
      : s == 'warning'
          ? AppColors.warningLight
          : AppColors.infoLight;
  IconData _alertIcon(String type) {
    switch (type) {
      case 'low_inventory':
        return Icons.inventory_2_outlined;
      case 'missing_attendance':
        return Icons.how_to_reg_outlined;
      case 'missed_visit':
        return Icons.map_outlined;
      case 'unit_inactivity':
        return Icons.directions_bus_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }
}

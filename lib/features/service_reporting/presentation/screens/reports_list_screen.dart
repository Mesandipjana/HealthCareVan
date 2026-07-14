import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../providers/reports_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsProvider);
    final user = ref.watch(currentUserProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Reports',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Aggregated patient health statistics and outreach logs',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (user != null && user.isOfficer)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/reports/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Report'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: reportsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reportsState.reports.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.assignment_outlined,
                          title: 'No Service Reports Found',
                          message:
                              'Submit service delivery logs for mobile unit camps.',
                        )
                      : isDesktop
                          ? _buildTableView(
                              context, ref, user, reportsState.reports)
                          : _buildListView(
                              context, ref, user, reportsState.reports),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView(
      BuildContext context, WidgetRef ref, dynamic user, List reports) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Camp Date')),
              DataColumn(label: Text('Mobile Unit')),
              DataColumn(label: Text('Village')),
              DataColumn(label: Text('Population Served')),
              DataColumn(label: Text('Consultations')),
              DataColumn(label: Text('Diabetes Scr.')),
              DataColumn(label: Text('Hyper. Scr.')),
              DataColumn(label: Text('Referrals')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: reports.map<DataRow>((rep) {
              return DataRow(
                cells: [
                  DataCell(Text(AppDateUtils.formatDate(rep.campDate))),
                  DataCell(Text(rep.unitName)),
                  DataCell(Text(rep.villageName)),
                  DataCell(Text(
                      '${rep.totalPopulationServed} (M:${rep.totalMale}, F:${rep.totalFemale})')),
                  DataCell(Text('${rep.generalConsultations}')),
                  DataCell(Text('${rep.diabetesScreening}')),
                  DataCell(Text('${rep.hypertensionScreening}')),
                  DataCell(Text('${rep.referralCases}')),
                  DataCell(
                    StatusBadge(
                      label:
                          rep.isVerified ? 'Verified' : 'Pending Verification',
                      type: rep.isVerified
                          ? StatusType.completed
                          : StatusType.pending,
                      small: true,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _showReportDetails(context, rep),
                          child: const Text('View'),
                        ),
                        if (!rep.isVerified && user != null && !user.isOfficer)
                          TextButton(
                            onPressed: () async {
                              await ref
                                  .read(reportsProvider.notifier)
                                  .verifyReport(rep.id, user.id);
                              ref.invalidate(dashboardSummaryProvider);
                              ref.invalidate(analyticsProvider);
                            },
                            child: const Text('Verify'),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(
      BuildContext context, WidgetRef ref, dynamic user, List reports) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final rep = reports[index];
        final action = rep.isVerified || user == null || user.isOfficer
            ? Icon(
                rep.isVerified ? Icons.check_circle : Icons.pending_actions,
                color: rep.isVerified
                    ? AppColors.successLight
                    : AppColors.warningLight,
                size: 20,
              )
            : TextButton(
                onPressed: () async {
                  await ref
                      .read(reportsProvider.notifier)
                      .verifyReport(rep.id, user.id);
                  ref.invalidate(dashboardSummaryProvider);
                  ref.invalidate(analyticsProvider);
                },
                child: const Text('Verify'),
              );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showReportDetails(context, rep),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${rep.villageName} (${rep.unitName})',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      action,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _ReportMetaText(
                          label: AppDateUtils.formatDate(rep.campDate)),
                      _ReportMetaText(
                          label: '${rep.totalPopulationServed} patients'),
                      _ReportMetaText(
                          label: '${rep.generalConsultations} consultations'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View details',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReportDetails(BuildContext context, dynamic report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Service Report Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: report.isVerified
                          ? 'Verified'
                          : 'Pending Verification',
                      type: report.isVerified
                          ? StatusType.completed
                          : StatusType.pending,
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ReportDetailRow(label: 'Mobile unit', value: report.unitName),
                _ReportDetailRow(
                    label: 'Doctor/Nurse', value: report.officerName),
                _ReportDetailRow(
                    label: 'Camp date',
                    value: AppDateUtils.formatDate(report.campDate)),
                _ReportDetailRow(
                    label: 'Village / District / State',
                    value:
                        '${report.villageName}, ${report.district}, ${report.state}'),
                const Divider(height: 24),
                Text(
                  'Population Served',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                        label: 'Total',
                        value: '${report.totalPopulationServed}'),
                    _MetricPill(label: 'Male', value: '${report.totalMale}'),
                    _MetricPill(
                        label: 'Female', value: '${report.totalFemale}'),
                    _MetricPill(
                        label: 'Children', value: '${report.totalChildren}'),
                    _MetricPill(
                        label: 'Senior citizens',
                        value: '${report.totalSeniorCitizens}'),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Services Delivered',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                        label: 'General consults',
                        value: '${report.generalConsultations}'),
                    _MetricPill(
                        label: 'Diabetes screens',
                        value: '${report.diabetesScreening}'),
                    _MetricPill(
                        label: 'Hypertension screens',
                        value: '${report.hypertensionScreening}'),
                    _MetricPill(
                        label: 'Maternal services',
                        value: '${report.maternalHealthServices}'),
                    _MetricPill(
                        label: 'Child health',
                        value: '${report.childHealthServices}'),
                    _MetricPill(
                        label: 'Vaccination',
                        value: '${report.vaccinationSupport}'),
                    _MetricPill(
                        label: 'Referrals', value: '${report.referralCases}'),
                  ],
                ),
                const Divider(height: 24),
                _ReportDetailRow(
                    label: 'Submitted',
                    value: AppDateUtils.formatDateTime(report.submittedAt)),
                _ReportDetailRow(
                    label: 'Verified by',
                    value:
                        report.verifiedBy == null || report.verifiedBy!.isEmpty
                            ? 'Not verified yet'
                            : report.verifiedBy!),
                _ReportDetailRow(
                    label: 'Remarks',
                    value:
                        report.remarks.isEmpty ? 'No remarks' : report.remarks),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportMetaText extends StatelessWidget {
  final String label;

  const _ReportMetaText({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
    );
  }
}

class _ReportDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

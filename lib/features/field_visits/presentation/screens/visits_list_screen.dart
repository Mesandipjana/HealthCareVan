import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/visits_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class VisitsListScreen extends ConsumerWidget {
  const VisitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsState = ref.watch(visitsProvider);
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
                        'Field Visit Logs',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Monitor check-ins, GPS timestamps, and site photos',
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
                    onPressed: () => context.go('/visits/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Start Visit'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (visitsState.activeVisit != null)
              _buildActiveVisitCard(context, visitsState.activeVisit!),
            const SizedBox(height: 16),
            Expanded(
              child: visitsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visitsState.visits.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.map_outlined,
                          title: 'No Visit Logs Registered',
                          message:
                              'All completed and in-progress visit logs will display here.',
                        )
                      : isDesktop
                          ? _buildTableView(context, visitsState.visits)
                          : _buildListView(context, visitsState.visits),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveVisitCard(BuildContext context, dynamic visit) {
    final isNarrow = MediaQuery.sizeOf(context).width < 680;

    return Card(
      color: AppColors.primarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActiveVisitDetails(visit),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _buildActiveVisitButton(context),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildActiveVisitDetails(visit)),
                  const SizedBox(width: 16),
                  _buildActiveVisitButton(context),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveVisitDetails(dynamic visit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, color: AppColors.primary, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Visit In Progress',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Village: ${visit.villageName} (${visit.district}) - Started: ${AppDateUtils.formatDateTime(visit.startTime)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveVisitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/visits/new'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
      child: const Text('Update / End Visit'),
    );
  }

  Widget _buildTableView(BuildContext context, List visits) {
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
              DataColumn(label: Text('Unit')),
              DataColumn(label: Text('Doctor/Nurse')),
              DataColumn(label: Text('Village / District')),
              DataColumn(label: Text('Start Time')),
              DataColumn(label: Text('End Time')),
              DataColumn(label: Text('Duration')),
              DataColumn(label: Text('Patients')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: visits.map<DataRow>((visit) {
              final durationText = visit.duration != null
                  ? AppDateUtils.formatDuration(visit.duration!)
                  : '-';
              return DataRow(
                cells: [
                  DataCell(Text(visit.unitName)),
                  DataCell(Text(visit.officerName)),
                  DataCell(Text('${visit.villageName}, ${visit.district}')),
                  DataCell(Text(AppDateUtils.formatDateTime(visit.startTime))),
                  DataCell(Text(visit.endTime != null
                      ? AppDateUtils.formatDateTime(visit.endTime!)
                      : '-')),
                  DataCell(Text(durationText)),
                  DataCell(Text('${visit.patientsServed}')),
                  DataCell(StatusBadge.fromString(visit.status)),
                  DataCell(
                    TextButton(
                      onPressed: () => _showVisitDetails(context, visit),
                      child: const Text('View'),
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

  Widget _buildListView(BuildContext context, List visits) {
    return ListView.builder(
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showVisitDetails(context, visit),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          visit.unitName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.fromString(visit.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Doctor/Nurse: ${visit.officerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Location: ${visit.villageName}, ${visit.district}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        'Started: ${AppDateUtils.formatTime(visit.startTime)}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      Text(
                        'Patients Served: ${visit.patientsServed}',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
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

  void _showVisitDetails(BuildContext context, dynamic visit) {
    final durationText = visit.duration != null
        ? AppDateUtils.formatDuration(visit.duration!)
        : 'In progress';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
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
                        'Field Visit Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge.fromString(visit.status),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(label: 'Mobile unit', value: visit.unitName),
                _DetailRow(label: 'Doctor/Nurse', value: visit.officerName),
                _DetailRow(
                    label: 'Village / District',
                    value: '${visit.villageName}, ${visit.district}'),
                _DetailRow(
                    label: 'Started',
                    value: AppDateUtils.formatDateTime(visit.startTime)),
                _DetailRow(
                    label: 'Ended',
                    value: visit.endTime != null
                        ? AppDateUtils.formatDateTime(visit.endTime!)
                        : 'Not ended yet'),
                _DetailRow(label: 'Duration', value: durationText),
                _DetailRow(
                    label: 'Patients served', value: '${visit.patientsServed}'),
                _DetailRow(
                    label: 'Start GPS',
                    value: _formatCoordinates(
                        visit.startLatitude, visit.startLongitude)),
                _DetailRow(
                    label: 'End GPS',
                    value: _formatCoordinates(
                        visit.endLatitude, visit.endLongitude)),
                _DetailRow(
                    label: 'Photo evidence',
                    value: visit.photoUrl == null || visit.photoUrl!.isEmpty
                        ? 'No photo evidence'
                        : visit.photoUrl!),
                _DetailRow(
                    label: 'Remarks',
                    value:
                        visit.remarks.isEmpty ? 'No remarks' : visit.remarks),
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

  String _formatCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return 'Not captured';
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
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

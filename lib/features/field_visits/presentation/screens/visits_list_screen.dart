import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/prescription_pdf_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/visits_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../patients/domain/entities/patient_record.dart';
import '../../../patients/presentation/providers/patients_provider.dart';

class VisitsListScreen extends ConsumerWidget {
  const VisitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsState = ref.watch(visitsProvider);
    final patientsState = ref.watch(patientsProvider);
    final user = ref.watch(currentUserProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final visitPatients = _patientsByVisit(patientsState.patients);

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
                          ? _buildTableView(
                              context, visitsState.visits, visitPatients)
                          : _buildListView(
                              context, visitsState.visits, visitPatients),
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
                'Village: ${visit.villageName} (${visit.district}, ${visit.state}) - Started: ${AppDateUtils.formatDateTime(visit.startTime)}',
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

  Map<String, List<({PatientRecord patient, PatientEncounter encounter})>>
      _patientsByVisit(List<PatientRecord> patients) {
    final map =
        <String, List<({PatientRecord patient, PatientEncounter encounter})>>{};
    for (final patient in patients) {
      for (final encounter in patient.encounters) {
        if (encounter.visitId.isEmpty) continue;
        map.putIfAbsent(encounter.visitId, () => []).add(
          (patient: patient, encounter: encounter),
        );
      }
    }
    return map;
  }

  Widget _buildTableView(
    BuildContext context,
    List visits,
    Map<String, List<({PatientRecord patient, PatientEncounter encounter})>>
        visitPatients,
  ) {
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
                  DataCell(Text('${visit.villageName}, ${visit.district}, ${visit.state}')),
                  DataCell(Text(AppDateUtils.formatDateTime(visit.startTime))),
                  DataCell(Text(visit.endTime != null
                      ? AppDateUtils.formatDateTime(visit.endTime!)
                      : '-')),
                  DataCell(Text(durationText)),
                  DataCell(Text('${visitPatients[visit.id]?.length ?? 0}')),
                  DataCell(StatusBadge.fromString(visit.status)),
                  DataCell(
                    TextButton(
                      onPressed: () => _showVisitDetails(
                        context,
                        visit,
                        visitPatients[visit.id] ?? const [],
                      ),
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

  Widget _buildListView(
    BuildContext context,
    List visits,
    Map<String, List<({PatientRecord patient, PatientEncounter encounter})>>
        visitPatients,
  ) {
    return ListView.builder(
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showVisitDetails(
              context,
              visit,
              visitPatients[visit.id] ?? const [],
            ),
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
                    'Location: ${visit.villageName}, ${visit.district}, ${visit.state}',
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
                        'Patients: ${visitPatients[visit.id]?.length ?? 0}',
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

  void _showVisitDetails(
    BuildContext context,
    dynamic visit,
    List<({PatientRecord patient, PatientEncounter encounter})> patients,
  ) {
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
                    value: '${visit.villageName}, ${visit.district}, ${visit.state}'),
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
                    label: 'Patients recorded', value: '${patients.length}'),
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
                const Divider(height: 24),
                Text(
                  'Patients In This Visit',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                if (patients.isEmpty)
                  Text(
                    'No patients recorded for this visit yet.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  ...patients.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.patient.name),
                        subtitle: Text(
                          '${item.patient.phone} • ${item.encounter.diagnosisSummary}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: TextButton(
                          onPressed: () => _showPatientDetails(
                            context,
                            item.patient,
                            item.encounter,
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ),
                  ),
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

  void _showPatientDetails(
    BuildContext context,
    PatientRecord patient,
    PatientEncounter encounter,
  ) {
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
                Text(
                  patient.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Phone', value: patient.phone),
                _DetailRow(
                    label: 'Age / Gender',
                    value: '${patient.age} / ${patient.gender}'),
                _DetailRow(label: 'Address', value: patient.address),
                const Divider(height: 24),
                _DetailRow(
                    label: 'Visit date',
                    value: AppDateUtils.formatDateTime(encounter.visitDate)),
                _DetailRow(label: 'Mobile unit', value: encounter.unitName),
                _DetailRow(label: 'Doctor/Nurse', value: encounter.officerName),
                _DetailRow(
                    label: 'Location',
                    value:
                        '${encounter.villageName}, ${encounter.district}, ${encounter.state}'),
                const Divider(height: 24),
                _DetailRow(
                    label: 'Vitals',
                    value:
                        'BP: ${_dash(encounter.bloodPressure)}, O2: ${_dash(encounter.oxygenSaturation)}, Temp: ${_dash(encounter.temperature)}, Pulse: ${_dash(encounter.pulseRate)}'),
                _DetailRow(
                    label: 'Categories',
                    value: encounter.serviceCategories.isEmpty
                        ? '-'
                        : encounter.serviceCategories.join(', ')),
                _DetailRow(
                    label: 'Diagnosis', value: encounter.diagnosisSummary),
                _DetailRow(
                    label: 'Medicines', value: encounter.prescribedMedicines),
                _DetailRow(
                    label: 'Tests', value: _dash(encounter.recommendedTests)),
                _DetailRow(label: 'Remarks', value: _dash(encounter.remarks)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => PrescriptionPdfUtils.download(
                          patient: patient,
                          encounter: encounter,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Download Prescription'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dash(String value) => value.trim().isEmpty ? '-' : value.trim();
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

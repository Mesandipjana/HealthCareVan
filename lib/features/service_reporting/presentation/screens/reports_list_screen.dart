import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/prescription_pdf_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../field_visits/presentation/providers/visits_provider.dart';
import '../../../patients/domain/entities/patient_record.dart';
import '../../../patients/presentation/providers/patients_provider.dart';

class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsState = ref.watch(patientsProvider);
    final visitsState = ref.watch(visitsProvider);
    final user = ref.watch(currentUserProvider);
    final activeVisit = visitsState.activeVisit;
    final canAddPatient = user?.isOfficer == true && activeVisit != null;
    final encounters = patientsState.patients
        .expand((patient) => patient.encounters.map((encounter) {
              return (patient: patient, encounter: encounter);
            }))
        .toList()
      ..sort((a, b) => b.encounter.visitDate.compareTo(a.encounter.visitDate));
    final visibleEncounters = user?.isOfficer == true
        ? encounters
            .where((item) => item.encounter.officerId == user?.id)
            .toList()
        : encounters;

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
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Records',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        activeVisit == null && user?.isOfficer == true
                            ? 'Start a field visit before adding patients'
                            : 'Individual patient encounters and prescription history',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (user != null && user.isOfficer)
                  ElevatedButton.icon(
                    onPressed:
                        canAddPatient ? () => context.go('/reports/new') : null,
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Add Patient'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeVisit != null && user?.isOfficer == true)
              Card(
                color: AppColors.primarySurface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Active visit: ${activeVisit.villageName}, ${activeVisit.district}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: patientsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleEncounters.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: 'No Patient Records Found',
                          message:
                              'Patient encounters entered during field visits will appear here.',
                        )
                      : ListView.builder(
                          itemCount: visibleEncounters.length,
                          itemBuilder: (context, index) {
                            final item = visibleEncounters[index];
                            return _PatientEncounterCard(
                              patient: item.patient,
                              encounter: item.encounter,
                              onTap: () => _showPatientDetails(
                                context,
                                item.patient,
                                item.encounter,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
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

class _PatientEncounterCard extends StatelessWidget {
  final PatientRecord patient;
  final PatientEncounter encounter;
  final VoidCallback onTap;

  const _PatientEncounterCard({
    required this.patient,
    required this.encounter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      patient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    AppDateUtils.formatDate(encounter.visitDate),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${patient.phone} • ${encounter.villageName}, ${encounter.district}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                encounter.diagnosisSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_data_service.dart';
import '../../domain/entities/patient_record.dart';

class PatientsState {
  final List<PatientRecord> patients;
  final bool isLoading;
  final String? error;

  const PatientsState({
    this.patients = const [],
    this.isLoading = false,
    this.error,
  });

  PatientsState copyWith({
    List<PatientRecord>? patients,
    bool? isLoading,
    String? error,
  }) {
    return PatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PatientsNotifier extends StateNotifier<PatientsState> {
  PatientsNotifier() : super(const PatientsState(isLoading: true)) {
    refresh();
  }

  Future<void> refresh() async {
    final patients = await FirebaseDataService.getPatients();
    state = PatientsState(patients: patients);
  }

  Future<void> saveEncounter({
    required PatientRecord patient,
    required PatientEncounter encounter,
  }) async {
    state = state.copyWith(isLoading: true);
    await FirebaseDataService.savePatientEncounter(
      patient: patient,
      encounter: encounter,
    );
    await refresh();
  }
}

final patientsProvider =
    StateNotifierProvider<PatientsNotifier, PatientsState>((ref) {
  return PatientsNotifier();
});

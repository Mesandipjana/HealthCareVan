import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/field_visit.dart';
import '../../../../core/services/firebase_data_service.dart';

class VisitsState {
  final List<FieldVisit> visits;
  final bool isLoading;
  final FieldVisit? activeVisit;
  final String? error;

  const VisitsState({
    this.visits = const [],
    this.isLoading = false,
    this.activeVisit,
    this.error,
  });

  VisitsState copyWith({
    List<FieldVisit>? visits,
    bool? isLoading,
    FieldVisit? activeVisit,
    String? error,
    bool clearActiveVisit = false,
  }) {
    return VisitsState(
      visits: visits ?? this.visits,
      isLoading: isLoading ?? this.isLoading,
      activeVisit: clearActiveVisit ? null : (activeVisit ?? this.activeVisit),
      error: error ?? this.error,
    );
  }
}

class VisitsNotifier extends StateNotifier<VisitsState> {
  VisitsNotifier() : super(const VisitsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final visits = await FirebaseDataService.getFieldVisits();
    final active = visits.where((v) => v.isInProgress).firstOrNull;
    state = VisitsState(visits: visits, activeVisit: active);
  }

  Future<void> refresh() => _load();

  Future<void> startVisit({
    required String unitId,
    required String unitName,
    required String officerId,
    required String officerName,
    required String villageName,
    required String district,
    required double lat,
    required double lng,
    required String remarks,
    String? photoUrl,
  }) async {
    final visit = FieldVisit(
      id: 'visit_new_${DateTime.now().millisecondsSinceEpoch}',
      unitId: unitId,
      unitName: unitName,
      officerId: officerId,
      officerName: officerName,
      villageName: villageName,
      district: district,
      startTime: DateTime.now(),
      endTime: null,
      startLatitude: lat,
      startLongitude: lng,
      endLatitude: null,
      endLongitude: null,
      remarks: remarks,
      status: 'in_progress',
      patientsServed: 0,
      photoUrl: photoUrl,
    );
    await FirebaseDataService.saveFieldVisit(visit);
    final updatedVisits = [visit, ...state.visits];
    state = state.copyWith(visits: updatedVisits, activeVisit: visit);
  }

  Future<void> endVisit(String visitId,
      {required int patientsServed, required String remarks}) async {
    FieldVisit? completedVisit;
    final updated = state.visits.map((v) {
      if (v.id == visitId) {
        completedVisit = FieldVisit(
          id: v.id,
          unitId: v.unitId,
          unitName: v.unitName,
          officerId: v.officerId,
          officerName: v.officerName,
          villageName: v.villageName,
          district: v.district,
          startTime: v.startTime,
          endTime: DateTime.now(),
          startLatitude: v.startLatitude,
          startLongitude: v.startLongitude,
          endLatitude: v.startLatitude,
          endLongitude: v.startLongitude,
          remarks: remarks,
          status: 'completed',
          patientsServed: patientsServed,
          photoUrl: v.photoUrl,
        );
        return completedVisit!;
      }
      return v;
    }).toList();
    if (completedVisit != null) {
      await FirebaseDataService.saveFieldVisit(completedVisit!);
      await FirebaseDataService.updateUnitAfterVisit(completedVisit!);
      state = state.copyWith(visits: updated, clearActiveVisit: true);
    }
  }
}

final visitsProvider =
    StateNotifierProvider<VisitsNotifier, VisitsState>((ref) {
  return VisitsNotifier();
});

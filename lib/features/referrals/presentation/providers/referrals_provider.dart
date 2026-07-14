import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/referral.dart';
import '../../../../core/services/firebase_data_service.dart';

class ReferralsState {
  final List<Referral> referrals;
  final bool isLoading;
  final String statusFilter;
  final String? error;

  const ReferralsState({
    this.referrals = const [],
    this.isLoading = false,
    this.statusFilter = 'all',
    this.error,
  });

  List<Referral> get filteredReferrals {
    if (statusFilter == 'all') return referrals;
    return referrals.where((r) => r.status == statusFilter).toList();
  }

  ReferralsState copyWith({
    List<Referral>? referrals,
    bool? isLoading,
    String? statusFilter,
    String? error,
  }) {
    return ReferralsState(
      referrals: referrals ?? this.referrals,
      isLoading: isLoading ?? this.isLoading,
      statusFilter: statusFilter ?? this.statusFilter,
      error: error ?? this.error,
    );
  }
}

class ReferralsNotifier extends StateNotifier<ReferralsState> {
  ReferralsNotifier() : super(const ReferralsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final referrals = await FirebaseDataService.getReferrals();
    state = ReferralsState(referrals: referrals);
  }

  Future<void> refresh() => _load();

  void setFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  Future<void> createReferral(Referral referral) async {
    state = state.copyWith(isLoading: true);
    await FirebaseDataService.saveReferral(referral);
    state = ReferralsState(referrals: [referral, ...state.referrals]);
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final updated = state.referrals.map((r) {
      if (r.id == id) {
        return Referral(
          id: r.id,
          unitId: r.unitId,
          unitName: r.unitName,
          officerId: r.officerId,
          officerName: r.officerName,
          patientCode: r.patientCode,
          age: r.age,
          gender: r.gender,
          reason: r.reason,
          referredFacility: r.referredFacility,
          status: newStatus,
          priority: r.priority,
          followUpNotes: r.followUpNotes,
          createdAt: r.createdAt,
          resolvedAt: newStatus == 'closed' ? DateTime.now() : r.resolvedAt,
        );
      }
      return r;
    }).toList();
    await FirebaseDataService.updateReferralStatus(id, newStatus);
    state = state.copyWith(referrals: updated, isLoading: false);
  }
}

final referralsProvider =
    StateNotifierProvider<ReferralsNotifier, ReferralsState>((ref) {
  return ReferralsNotifier();
});

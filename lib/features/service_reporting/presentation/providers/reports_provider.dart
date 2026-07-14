import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_report.dart';
import '../../../../core/services/firebase_data_service.dart';

class ReportsState {
  final List<ServiceReport> reports;
  final bool isLoading;
  final String? error;

  const ReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });

  ReportsState copyWith({
    List<ServiceReport>? reports,
    bool? isLoading,
    String? error,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier() : super(const ReportsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final reports = await FirebaseDataService.getServiceReports();
    state = ReportsState(reports: reports);
  }

  Future<void> refresh() => _load();

  Future<void> submitReport(ServiceReport report) async {
    state = state.copyWith(isLoading: true);
    await FirebaseDataService.saveServiceReport(report);
    state = ReportsState(reports: [report, ...state.reports]);
  }

  Future<void> verifyReport(String id, String verifiedBy) async {
    final updated = state.reports.map((report) {
      if (report.id != id) return report;
      return ServiceReport(
        id: report.id,
        unitId: report.unitId,
        unitName: report.unitName,
        officerId: report.officerId,
        officerName: report.officerName,
        campDate: report.campDate,
        villageName: report.villageName,
        district: report.district,
        state: report.state,
        totalMale: report.totalMale,
        totalFemale: report.totalFemale,
        totalChildren: report.totalChildren,
        totalSeniorCitizens: report.totalSeniorCitizens,
        generalConsultations: report.generalConsultations,
        diabetesScreening: report.diabetesScreening,
        hypertensionScreening: report.hypertensionScreening,
        maternalHealthServices: report.maternalHealthServices,
        childHealthServices: report.childHealthServices,
        vaccinationSupport: report.vaccinationSupport,
        referralCases: report.referralCases,
        remarks: report.remarks,
        submittedAt: report.submittedAt,
        isVerified: true,
        verifiedBy: verifiedBy,
      );
    }).toList();
    state = state.copyWith(reports: updated);
    await FirebaseDataService.verifyServiceReport(id, verifiedBy);
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier();
});

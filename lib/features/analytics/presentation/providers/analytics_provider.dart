import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/analytics_data.dart';
import '../../../../core/services/firebase_data_service.dart';
import '../../../mobile_units/domain/entities/mobile_unit.dart';

final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final units = await FirebaseDataService.getMobileUnits();
  final reports = await FirebaseDataService.getServiceReports();
  final referrals = await FirebaseDataService.getReferrals();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final monthly = List.generate(12, (index) {
    final monthReports =
        reports.where((report) => report.campDate.month == index + 1);
    final patients = monthReports.fold<int>(
      0,
      (sum, report) => sum + report.totalPopulationServed,
    );
    return MonthlyTrend(
      month: months[index],
      patientsServed: patients,
    );
  });

  final totalDiseaseSignals = reports.fold<int>(
    0,
    (sum, report) =>
        sum +
        report.hypertensionScreening +
        report.diabetesScreening +
        report.maternalHealthServices +
        report.childHealthServices +
        report.vaccinationSupport,
  );
  List<DiseaseData> diseases;
  if (totalDiseaseSignals == 0) {
    diseases = const [];
  } else {
    DiseaseData item(String name, int count) => DiseaseData(
          name: name,
          count: count,
          percentage: count / totalDiseaseSignals * 100,
        );
    final hypertension =
        reports.fold<int>(0, (sum, r) => sum + r.hypertensionScreening);
    final diabetes =
        reports.fold<int>(0, (sum, r) => sum + r.diabetesScreening);
    final maternal =
        reports.fold<int>(0, (sum, r) => sum + r.maternalHealthServices);
    final child = reports.fold<int>(0, (sum, r) => sum + r.childHealthServices);
    final vaccination =
        reports.fold<int>(0, (sum, r) => sum + r.vaccinationSupport);
    diseases = [
      item('Hypertension', hypertension),
      item('Diabetes', diabetes),
      item('Maternal Health', maternal),
      item('Child Health', child),
      item('Vaccination', vaccination),
    ];
  }

  final regionMap = <String, List<MobileUnit>>{};
  for (final unit in units) {
    regionMap.putIfAbsent(unit.state, () => []).add(unit);
  }
  final regions = regionMap.entries.map((entry) {
    final regionUnits = entry.value;
    final patients = regionUnits.fold<int>(
        0, (sum, unit) => sum + unit.patientsServedThisMonth);
    final villages =
        regionUnits.fold<int>(0, (sum, unit) => sum + unit.villagesCovered);
    final visits =
        regionUnits.fold<int>(0, (sum, unit) => sum + unit.visitsThisMonth);
    return RegionPerformance(
      region: entry.key,
      units: regionUnits.length,
      patients: patients,
      villages: villages,
      visits: visits,
      score: patients > 0 ? (patients / 25).clamp(0, 100).toInt() : 0,
    );
  }).toList()
    ..sort((a, b) => b.patients.compareTo(a.patients));

  final unitPerformance = units
      .map(
        (unit) => UnitPerformance(
          unitId: unit.id,
          unitCode: unit.unitCode,
          unitName: unit.name,
          patientsServed: unit.patientsServedThisMonth,
          visits: unit.visitsThisMonth,
          villages: unit.villagesCovered,
          status: unit.status,
          score: unit.patientsServedThisMonth > 0
              ? (unit.patientsServedThisMonth / 25).clamp(0, 100).toInt()
              : 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.patientsServed.compareTo(a.patientsServed));

  final referralAnalytics = [
    ReferralCount(
        status: 'Closed',
        count: referrals.where((r) => r.status == 'closed').length,
        color: 0xFF10B981),
    ReferralCount(
        status: 'In Progress',
        count: referrals.where((r) => r.status == 'in_progress').length,
        color: 0xFFF59E0B),
    ReferralCount(
        status: 'Pending',
        count: referrals.where((r) => r.status == 'pending').length,
        color: 0xFF3B82F6),
  ];

  final coverage = List.generate(12, (index) {
    final covered = reports
        .where((report) => report.campDate.month == index + 1)
        .map((report) => report.villageName)
        .toSet()
        .length;
    return CoverageTrend(
      month: months[index],
      villagesCovered: covered,
    );
  });

  return AnalyticsData(
    monthlyServiceTrends: monthly,
    diseaseDistribution: diseases,
    regionPerformance: regions,
    unitPerformance: unitPerformance,
    referralAnalytics: referralAnalytics,
    coverageTrends: coverage,
  );
});

final dashboardSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final units = await FirebaseDataService.getMobileUnits();
  final visits = await FirebaseDataService.getFieldVisits();
  final referrals = await FirebaseDataService.getReferrals();
  final inventory = await FirebaseDataService.getInventoryItems();
  final alerts = await FirebaseDataService.getAlerts();
  final reports = await FirebaseDataService.getServiceReports();
  final activeUnits = units.where((u) => u.status == 'active').length;
  final totalPatients =
      units.fold<int>(0, (sum, u) => sum + u.patientsServedThisMonth);
  final coveredVillages = {
    ...visits
        .map((visit) => visit.villageName.trim())
        .where((v) => v.isNotEmpty),
    ...reports
        .map((report) => report.villageName.trim())
        .where((v) => v.isNotEmpty),
  };
  final coveredStates = {
    ...reports.map((report) => report.state.trim()).where((s) => s.isNotEmpty),
  };

  return {
    'totalUnits': units.length,
    'activeUnits': activeUnits,
    'unitsActiveToday': units
        .where(
            (u) => DateTime.now().difference(u.lastActivityTime).inHours < 24)
        .length,
    'statesCovered': coveredStates.length,
    'villagesCovered': coveredVillages.length,
    'communitiesReached': coveredVillages.length,
    'patientsServed': totalPatients,
    'referralCases': referrals.length,
    'inventoryAlerts': inventory.where((i) => i.isLowStock).length,
    'activeAlerts': alerts.where((a) => !a.isRead).length,
    'pendingReferrals': referrals.where((r) => r.status == 'pending').length,
  };
});

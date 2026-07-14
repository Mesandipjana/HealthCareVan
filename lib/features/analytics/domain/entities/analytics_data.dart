class AnalyticsData {
  final List<MonthlyTrend> monthlyServiceTrends;
  final List<DiseaseData> diseaseDistribution;
  final List<RegionPerformance> regionPerformance;
  final List<UnitPerformance> unitPerformance;
  final List<ReferralCount> referralAnalytics;
  final List<CoverageTrend> coverageTrends;

  const AnalyticsData({
    required this.monthlyServiceTrends,
    required this.diseaseDistribution,
    required this.regionPerformance,
    required this.unitPerformance,
    required this.referralAnalytics,
    required this.coverageTrends,
  });
}

class MonthlyTrend {
  final String month;
  final int patientsServed;
  const MonthlyTrend({required this.month, required this.patientsServed});
}

class DiseaseData {
  final String name;
  final int count;
  final double percentage;
  const DiseaseData({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

class RegionPerformance {
  final String region;
  final int units;
  final int patients;
  final int villages;
  final int visits;
  final int score;
  const RegionPerformance({
    required this.region,
    required this.units,
    required this.patients,
    required this.villages,
    required this.visits,
    required this.score,
  });
}

class UnitPerformance {
  final String unitId;
  final String unitCode;
  final String unitName;
  final int patientsServed;
  final int visits;
  final int villages;
  final String status;
  final int score;
  const UnitPerformance({
    required this.unitId,
    required this.unitCode,
    required this.unitName,
    required this.patientsServed,
    required this.visits,
    required this.villages,
    required this.status,
    required this.score,
  });
}

class ReferralCount {
  final String status;
  final int count;
  final int color;
  const ReferralCount({
    required this.status,
    required this.count,
    required this.color,
  });
}

class CoverageTrend {
  final String month;
  final int villagesCovered;
  const CoverageTrend({required this.month, required this.villagesCovered});
}

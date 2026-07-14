import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../providers/analytics_provider.dart';
import '../../domain/entities/analytics_data.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operational Analytics & Reporting',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Comprehensive overview of region, disease, coverage, and unit metrics',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Export Report'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            analyticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error loading analytics: $err')),
              data: (data) {
                return Column(
                  children: [
                    // Region Scorecard
                    _buildRegionScorecard(context, data.regionPerformance),
                    const SizedBox(height: 24),

                    // Trends & Coverage row
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 1,
                              child: _buildServiceTrends(
                                  context, data.monthlyServiceTrends)),
                          const SizedBox(width: 20),
                          Expanded(
                              flex: 1,
                              child: _buildCoverageTrends(
                                  context, data.coverageTrends)),
                        ],
                      )
                    else ...[
                      _buildServiceTrends(context, data.monthlyServiceTrends),
                      const SizedBox(height: 20),
                      _buildCoverageTrends(context, data.coverageTrends),
                    ],
                    const SizedBox(height: 24),

                    // Disease distribution & Referrals
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 1,
                              child: _buildDiseaseTrends(
                                  context, data.diseaseDistribution)),
                          const SizedBox(width: 20),
                          Expanded(
                              flex: 1,
                              child: _buildReferralAnalytics(
                                  context, data.referralAnalytics)),
                        ],
                      )
                    else ...[
                      _buildDiseaseTrends(context, data.diseaseDistribution),
                      const SizedBox(height: 20),
                      _buildReferralAnalytics(context, data.referralAnalytics),
                    ],
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionScorecard(
      BuildContext context, List<RegionPerformance> regionalData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Region-wise Operations Scorecard',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Region / State')),
                  DataColumn(label: Text('Mobile Units')),
                  DataColumn(label: Text('Patients Served')),
                  DataColumn(label: Text('Villages Covered')),
                  DataColumn(label: Text('Camps Logged')),
                  DataColumn(label: Text('Efficiency Score')),
                ],
                rows: regionalData.map((reg) {
                  return DataRow(
                    cells: [
                      DataCell(Text(reg.region,
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.bold))),
                      DataCell(Text('${reg.units}')),
                      DataCell(Text('${reg.patients}')),
                      DataCell(Text('${reg.villages}')),
                      DataCell(Text('${reg.visits}')),
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: reg.score >= 80
                                    ? AppColors.successBg
                                    : AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${reg.score}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: reg.score >= 80
                                      ? AppColors.successLight
                                      : AppColors.warningLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTrends(BuildContext context, List<MonthlyTrend> trends) {
    final spots = trends
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.patientsServed.toDouble()))
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Outreach Volume',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                            '${(v / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx >= 0 && idx < trends.length && idx % 2 == 0) {
                            return Text(trends[idx].month,
                                style: const TextStyle(fontSize: 9));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageTrends(
      BuildContext context, List<CoverageTrend> trends) {
    final spots = trends
        .asMap()
        .entries
        .map(
            (e) => FlSpot(e.key.toDouble(), e.value.villagesCovered.toDouble()))
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Villages Coverage Timeline',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}',
                            style: const TextStyle(fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx >= 0 && idx < trends.length && idx % 2 == 0) {
                            return Text(trends[idx].month,
                                style: const TextStyle(fontSize: 9));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.successLight,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseTrends(
      BuildContext context, List<DiseaseData> diseaseData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('disease Distribution Analytics',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...diseaseData.take(5).map((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(d.name,
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        Text(
                            '${d.count} patients (${d.percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: d.percentage / 100,
                      backgroundColor: Colors.grey.shade100,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralAnalytics(
      BuildContext context, List<ReferralCount> referrals) {
    final colors = [
      AppColors.successLight,
      AppColors.warningLight,
      AppColors.primary
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Referral Resolution Statuses',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx >= 0 && idx < referrals.length) {
                            return Text(referrals[idx].status,
                                style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: referrals.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.count.toDouble(),
                          color: colors[e.key % colors.length],
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

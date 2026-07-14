import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_data_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../../features/alerts/presentation/providers/alerts_provider.dart';
import '../../../../features/analytics/presentation/providers/analytics_provider.dart';
import '../../../../features/analytics/domain/entities/analytics_data.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../field_visits/presentation/providers/visits_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../mobile_units/presentation/providers/units_provider.dart';
import '../../../referrals/presentation/providers/referrals_provider.dart';
import '../../../service_reporting/presentation/providers/reports_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final alerts = ref.watch(alertsProvider).alerts;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1200;
    final isTablet = width >= 700;
    final padding = isDesktop ? 28.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Executive Dashboard',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(
                      'Overview of all mobile healthcare operations — ${AppDateUtils.formatDate(DateTime.now())}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _clearDemoData(context, ref),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Clear Demo Data'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _seedDemoData(context, ref),
                    icon: const Icon(Icons.cloud_sync_outlined, size: 16),
                    label: const Text('Seed Demo Data'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Grid
          summaryAsync.when(
            loading: () => _buildKpiGrid(context, null, isTablet),
            error: (e, _) => Text('Error: $e'),
            data: (s) => _buildKpiGrid(context, s, isTablet),
          ),
          const SizedBox(height: 28),

          // Charts Row
          analyticsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (data) => _buildChartsSection(context, data, isDesktop),
          ),
          const SizedBox(height: 28),

          // Bottom Row: Unit Performance + Alerts
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: analyticsAsync.when(
                    loading: () => const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text('Error: $e'),
                    data: (data) => _buildUnitPerformanceTable(context, data),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: _buildAlertsCard(context, ref, alerts),
                ),
              ],
            )
          else
            Column(
              children: [
                analyticsAsync.when(
                  loading: () => const SizedBox(height: 200),
                  error: (_, __) => const SizedBox(),
                  data: (d) => _buildUnitPerformanceTable(context, d),
                ),
                const SizedBox(height: 20),
                _buildAlertsCard(context, ref, alerts),
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _clearDemoData(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clearing seeded demo data...')),
    );
    await FirebaseDataService.clearDemoData();
    _refreshData(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeded demo data was cleared.')),
      );
    }
  }

  Future<void> _seedDemoData(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seeding demo Firestore data...')),
    );
    await FirebaseDataService.resetDemoData();
    _refreshData(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo data is ready.')),
      );
    }
  }

  void _refreshData(WidgetRef ref) {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(analyticsProvider);
    ref.invalidate(unitsProvider);
    ref.read(inventoryProvider.notifier).load();
    ref.read(alertsProvider.notifier).refresh();
    ref.read(attendanceProvider.notifier).refresh();
    ref.read(visitsProvider.notifier).refresh();
    ref.read(reportsProvider.notifier).refresh();
    ref.read(referralsProvider.notifier).refresh();
  }

  Widget _buildKpiGrid(
      BuildContext context, Map<String, dynamic>? s, bool isTablet) {
    final kpis = [
      {
        'label': 'Total Mobile Units',
        'value': '${s?['totalUnits'] ?? 0}',
        'icon': Icons.directions_bus,
        'color': AppColors.kpiBlue,
        'bg': AppColors.kpiBlueBg,
        'trend': '+2 this quarter',
        'trendUp': true,
        'sub': 'Across ${s?['statesCovered'] ?? 0} states',
      },
      {
        'label': 'Active Units',
        'value': '${s?['activeUnits'] ?? 0}',
        'icon': Icons.check_circle_outline,
        'color': AppColors.kpiGreen,
        'bg': AppColors.kpiGreenBg,
        'trend': '75% of fleet',
        'trendUp': null,
        'sub': '1 maintenance, 1 inactive',
      },
      {
        'label': 'Active Today',
        'value': '${s?['unitsActiveToday'] ?? 0}',
        'icon': Icons.today,
        'color': AppColors.kpiTeal,
        'bg': AppColors.kpiTealBg,
        'trend': '+1 vs yesterday',
        'trendUp': true,
        'sub': 'Field operations',
      },
      {
        'label': 'Villages Covered',
        'value': '${s?['villagesCovered'] ?? 0}',
        'icon': Icons.location_city,
        'color': AppColors.kpiPurple,
        'bg': AppColors.kpiPurpleBg,
        'trend': '+12 this month',
        'trendUp': true,
        'sub': 'Cumulative reach',
      },
      {
        'label': 'Communities Reached',
        'value': '${s?['communitiesReached'] ?? 0}',
        'icon': Icons.people_outline,
        'color': AppColors.kpiBlue,
        'bg': AppColors.kpiBlueBg,
        'trend': 'This month',
        'trendUp': null,
        'sub': 'Active outreach zones',
      },
      {
        'label': 'Patients Served',
        'value': _formatCount(s?['patientsServed'] ?? 0),
        'icon': Icons.person_outlined,
        'color': AppColors.kpiGreen,
        'bg': AppColors.kpiGreenBg,
        'trend': '+340 vs last month',
        'trendUp': true,
        'sub': 'This month',
      },
      {
        'label': 'Referral Cases',
        'value': '${s?['referralCases'] ?? 0}',
        'icon': Icons.transfer_within_a_station,
        'color': AppColors.kpiOrange,
        'bg': AppColors.kpiOrangeBg,
        'trend': '2 pending',
        'trendUp': null,
        'sub': '2 closed, 2 in progress',
      },
      {
        'label': 'Inventory Alerts',
        'value': '${s?['inventoryAlerts'] ?? 0}',
        'icon': Icons.warning_amber,
        'color': AppColors.kpiRed,
        'bg': AppColors.kpiRedBg,
        'trend': 'Action required',
        'trendUp': false,
        'sub': 'Low stock items',
      },
    ];

    final availableWidth =
        MediaQuery.sizeOf(context).width - (isTablet ? 56 : 32);
    final cols = availableWidth >= 1100
        ? 4
        : availableWidth >= 640
            ? 2
            : 1;
    final count = kpis.length;
    final rows = (count / cols).ceil();

    return Column(
      children: List.generate(rows, (r) {
        final start = r * cols;
        final end = (start + cols).clamp(0, count);
        final rowItems = kpis.sublist(start, end);
        return Padding(
          padding: EdgeInsets.only(bottom: r < rows - 1 ? 12 : 0),
          child: Row(
            children: rowItems.asMap().entries.map((e) {
              final idx = e.key;
              final kpi = e.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: idx < rowItems.length - 1 ? 12 : 0),
                  child: KpiCard(
                    label: kpi['label'] as String,
                    value: kpi['value'] as String,
                    icon: kpi['icon'] as IconData,
                    iconColor: kpi['color'] as Color,
                    iconBg: kpi['bg'] as Color,
                    trend: kpi['trend'] as String,
                    trendUp: kpi['trendUp'] as bool?,
                    subtitle: kpi['sub'] as String,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildChartsSection(
      BuildContext context, AnalyticsData data, bool isDesktop) {
    final charts = [
      _buildServiceTrendChart(data),
      _buildDiseaseDistributionChart(data),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: charts[0]),
          const SizedBox(width: 20),
          Expanded(flex: 4, child: charts[1]),
        ],
      );
    }
    return Column(children: [charts[0], const SizedBox(height: 20), charts[1]]);
  }

  Widget _buildServiceTrendChart(AnalyticsData data) {
    final trends = data.monthlyServiceTrends;
    final spots = trends
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.patientsServed.toDouble()))
        .toList();

    return _ChartCard(
      title: 'Service Delivery Trends',
      subtitle: 'Monthly patient count over the past 12 months',
      height: 240,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 1000,
                getTitlesWidget: (v, _) => Text(
                  '${(v / 1000).toStringAsFixed(0)}k',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 2,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < trends.length && idx % 2 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(trends[idx].month,
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppColors.textMuted)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: 3500,
        ),
      ),
    );
  }

  Widget _buildDiseaseDistributionChart(AnalyticsData data) {
    final diseases = data.diseaseDistribution;
    const colors = AppColors.chartColors;
    var touchedIndex = -1;

    return _ChartCard(
      title: 'Disease Distribution',
      subtitle: 'Primary health conditions (this month)',
      height: 240,
      child: diseases.isEmpty
          ? _emptyChart('No service report data yet')
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: StatefulBuilder(
                    builder: (ctx, setState) {
                      return PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                touchedIndex = response
                                        ?.touchedSection?.touchedSectionIndex ??
                                    -1;
                              });
                            },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: diseases.asMap().entries.map((e) {
                            final isTouched = e.key == touchedIndex;
                            return PieChartSectionData(
                              color: colors[e.key % colors.length],
                              value: e.value.percentage,
                              radius: isTouched ? 54 : 46,
                              title:
                                  '${e.value.percentage.toStringAsFixed(0)}%',
                              titleStyle: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                              showTitle: isTouched || e.value.percentage > 15,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: diseases.asMap().entries.take(7).map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors[e.key % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.value.name,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.value.percentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _emptyChart(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildUnitPerformanceTable(BuildContext context, AnalyticsData data) {
    final units = data.unitPerformance.take(6).toList();
    return _ChartCard(
      title: 'Unit Performance',
      subtitle: 'Top performing mobile healthcare units this month',
      height: null,
      child: units.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _emptyChart('No mobile units yet'),
            )
          : Column(
              children: [
                // Table header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration:
                      const BoxDecoration(color: AppColors.surfaceVariant),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _tableHeader('Unit')),
                      Expanded(flex: 2, child: _tableHeader('Patients')),
                      Expanded(flex: 2, child: _tableHeader('Visits')),
                      Expanded(flex: 2, child: _tableHeader('Villages')),
                      Expanded(flex: 2, child: _tableHeader('Status')),
                    ],
                  ),
                ),
                // Rows
                ...units.asMap().entries.map((e) {
                  final u = e.value;
                  final isEven = e.key % 2 == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFFAFBFC),
                      border: const Border(
                          bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.unitCode,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                              Text(u.unitName,
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatCount(u.patientsServed),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('${u.visits}',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textPrimary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('${u.villages}',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textPrimary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: _unitStatusChip(u.status),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildAlertsCard(BuildContext context, WidgetRef ref, List alerts) {
    final unread = alerts.where((a) => !a.isRead).toList();
    return _ChartCard(
      title: 'Active Alerts',
      subtitle: '${unread.length} unread alerts require attention',
      height: null,
      action: TextButton(
        onPressed: () => context.go('/alerts'),
        child: const Text('View All'),
      ),
      child: Column(
        children: unread.take(5).map((alert) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _alertBg(alert.severity),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      _alertBorderColor(alert.severity).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_alertIcon(alert.type),
                    color: _alertColor(alert.severity), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(alert.unitName ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }

  Widget _unitStatusChip(String status) {
    Color color;
    Color bg;
    String label;
    switch (status) {
      case 'active':
        color = AppColors.successLight;
        bg = AppColors.successBg;
        label = 'Active';
        break;
      case 'maintenance':
        color = AppColors.warningLight;
        bg = AppColors.warningBg;
        label = 'Maint.';
        break;
      default:
        color = AppColors.errorLight;
        bg = AppColors.errorBg;
        label = 'Inactive';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _alertBg(String s) => s == 'critical'
      ? AppColors.errorBg
      : s == 'warning'
          ? AppColors.warningBg
          : AppColors.infoBg;
  Color _alertColor(String s) => s == 'critical'
      ? AppColors.errorLight
      : s == 'warning'
          ? AppColors.warningLight
          : AppColors.infoLight;
  Color _alertBorderColor(String s) => _alertColor(s);
  IconData _alertIcon(String type) {
    switch (type) {
      case 'low_inventory':
        return Icons.inventory_2_outlined;
      case 'missing_attendance':
        return Icons.how_to_reg_outlined;
      case 'missed_visit':
        return Icons.map_outlined;
      case 'unit_inactivity':
        return Icons.directions_bus_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? height;
  final Widget child;
  final Widget? action;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.height,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          if (height != null) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

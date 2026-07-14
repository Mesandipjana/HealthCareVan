import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../providers/referrals_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReferralsListScreen extends ConsumerWidget {
  const ReferralsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refState = ref.watch(referralsProvider);
    final user = ref.watch(currentUserProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral Management',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Track external medical referrals, follow-up progress, and facilities',
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
                    onPressed: () => context.go('/referrals/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Referral'),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(ref, 'All', 'all', refState.statusFilter),
                _buildFilterChip(
                    ref, 'Pending', 'pending', refState.statusFilter),
                _buildFilterChip(
                    ref, 'In Progress', 'in_progress', refState.statusFilter),
                _buildFilterChip(
                    ref, 'Closed', 'closed', refState.statusFilter),
              ],
            ),
            const SizedBox(height: 20),

            // Referrals table/list
            Expanded(
              child: refState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : refState.filteredReferrals.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.transfer_within_a_station,
                          title: 'No Referral Cases Registered',
                          message:
                              'Create a referral to log patient transfers to public hospitals or clinics.',
                        )
                      : isDesktop
                          ? _buildTableView(
                              context, refState.filteredReferrals, ref)
                          : _buildListView(
                              context, refState.filteredReferrals, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      WidgetRef ref, String label, String value, String currentSelected) {
    final isSelected = currentSelected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(referralsProvider.notifier).setFilter(value);
        }
      },
    );
  }

  Widget _buildTableView(BuildContext context, List referrals, WidgetRef ref) {
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
              DataColumn(label: Text('Patient Code')),
              DataColumn(label: Text('Demographics')),
              DataColumn(label: Text('Referral Reason')),
              DataColumn(label: Text('Referred Facility')),
              DataColumn(label: Text('Date Registered')),
              DataColumn(label: Text('Priority')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: referrals.map<DataRow>((referral) {
              return DataRow(
                cells: [
                  DataCell(Text(referral.patientCode,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                  DataCell(Text('${referral.age}y / ${referral.gender}')),
                  DataCell(Text(referral.reason,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(referral.referredFacility)),
                  DataCell(Text(AppDateUtils.formatDate(referral.createdAt))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: referral.isHighPriority
                            ? AppColors.errorBg
                            : AppColors.infoBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        referral.priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: referral.isHighPriority
                              ? AppColors.errorLight
                              : AppColors.infoLight,
                        ),
                      ),
                    ),
                  ),
                  DataCell(StatusBadge.fromString(referral.status)),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        ref
                            .read(referralsProvider.notifier)
                            .updateStatus(referral.id, val);
                        ref.invalidate(dashboardSummaryProvider);
                        ref.invalidate(analyticsProvider);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'pending', child: Text('Mark Pending')),
                        const PopupMenuItem(
                            value: 'in_progress',
                            child: Text('Mark In Progress')),
                        const PopupMenuItem(
                            value: 'closed', child: Text('Mark Closed')),
                      ],
                      icon: const Icon(Icons.more_vert, size: 16),
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

  Widget _buildListView(BuildContext context, List referrals, WidgetRef ref) {
    return ListView.builder(
      itemCount: referrals.length,
      itemBuilder: (context, index) {
        final referral = referrals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(referral.patientCode,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    StatusBadge.fromString(referral.status, small: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Facility: ${referral.referredFacility}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text('Reason: ${referral.reason}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Priority: ${referral.priority}',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: referral.isHighPriority
                              ? AppColors.errorLight
                              : AppColors.infoLight),
                    ),
                    // Dropdown for list view quick state updates
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Pending'),
                                  onTap: () {
                                    ref
                                        .read(referralsProvider.notifier)
                                        .updateStatus(referral.id, 'pending');
                                    ref.invalidate(dashboardSummaryProvider);
                                    ref.invalidate(analyticsProvider);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('In Progress'),
                                  onTap: () {
                                    ref
                                        .read(referralsProvider.notifier)
                                        .updateStatus(
                                            referral.id, 'in_progress');
                                    ref.invalidate(dashboardSummaryProvider);
                                    ref.invalidate(analyticsProvider);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('Closed'),
                                  onTap: () {
                                    ref
                                        .read(referralsProvider.notifier)
                                        .updateStatus(referral.id, 'closed');
                                    ref.invalidate(dashboardSummaryProvider);
                                    ref.invalidate(analyticsProvider);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text('Change Status',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down,
                              size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/units_provider.dart';

class UnitDetailScreen extends ConsumerWidget {
  final String unitId;

  const UnitDetailScreen({super.key, required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(unitByIdProvider(unitId));
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unit Details')),
        body: const Center(child: Text('Unit not found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/units'),
        ),
        title: Text(unit.unitCode,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildProfileHeader(context, unit),
            const SizedBox(height: 24),

            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildLeftPanel(context, unit)),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: _buildRightPanel(context, unit)),
                ],
              )
            else
              Column(
                children: [
                  _buildLeftPanel(context, unit),
                  const SizedBox(height: 24),
                  _buildRightPanel(context, unit),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.directions_bus_filled,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        unit.name,
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge.fromString(unit.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vehicle No: ${unit.vehicleNumber} • Operating since ${AppDateUtils.formatDate(unit.operationalSince)}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, dynamic unit) {
    return Column(
      children: [
        // Operations Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Operational Visibility',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInfoRow('District / State', unit.location),
                const Divider(),
                _buildInfoRow(
                    'Villages Covered', '${unit.villagesCovered} Villages'),
                const Divider(),
                _buildInfoRow('Patients Served (Month)',
                    '${unit.patientsServedThisMonth} Patients'),
                const Divider(),
                _buildInfoRow('Visits Completed (Month)',
                    '${unit.visitsThisMonth} Visits'),
                const Divider(),
                _buildInfoRow('Last Active Timestamp',
                    AppDateUtils.formatDateTime(unit.lastActivityTime)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Live GPS / Map card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last Known GPS Location',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (unit.currentLatitude != null &&
                    unit.currentLongitude != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${unit.currentLatitude!.toStringAsFixed(4)}, Lng: ${unit.currentLongitude!.toStringAsFixed(4)}',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('Google Maps View (PoC Placeholder)',
                              style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ] else
                  const Center(child: Text('GPS coordinates not available')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(BuildContext context, dynamic unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned Health Team',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...unit.teamMembers.map<Widget>((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(Icons.person,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        member,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            _buildInfoRow('Team Size', '${unit.teamSize} Personnel'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

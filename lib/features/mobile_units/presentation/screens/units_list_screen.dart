import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_data_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/mobile_unit.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/units_provider.dart';

class UnitsListScreen extends ConsumerStatefulWidget {
  const UnitsListScreen({super.key});

  @override
  ConsumerState<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends ConsumerState<UnitsListScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl =
        TextEditingController(text: ref.read(unitSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(searchedUnitsProvider);
    final filter = ref.watch(unitFilterProvider);
    final user = ref.watch(currentUserProvider);
    final canManageUnits = user?.isAdmin == true;
    if (canManageUnits) ref.watch(officersProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Padding(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mobile Healthcare Units',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Monitor operational status and details of mobile units',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (canManageUnits)
                ElevatedButton.icon(
                  onPressed: () => _showUnitDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Mobile Unit'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters and Search Bar
          _buildFilters(ref, filter),
          const SizedBox(height: 20),

          // Main Listing Content
          Expanded(
            child: unitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error loading units: $err')),
              data: (units) {
                if (units.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.directions_bus_filled_outlined,
                    title: 'No Mobile Units Found',
                    message: canManageUnits
                        ? 'Create your first mobile unit to populate dashboard metrics.'
                        : 'No mobile units are available for your current filters.',
                  );
                }

                if (isDesktop) {
                  return _buildTableView(context, ref, units, canManageUnits);
                } else {
                  return _buildGridView(
                      context, ref, units, isTablet, canManageUnits);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    WidgetRef ref,
    List units,
    bool isTablet,
    bool canManageUnits,
  ) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        return Card(
          child: InkWell(
            onTap: () => context.go('/units/${unit.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        unit.unitCode,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge.fromString(unit.status),
                          if (canManageUnits)
                            IconButton(
                              tooltip: 'Edit unit',
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              onPressed: () =>
                                  _showUnitDialog(context, ref, unit: unit),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unit.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        unit.location,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric(Icons.people_outline,
                          '${unit.patientsServedThisMonth} served'),
                      _buildMetric(Icons.explore_outlined,
                          '${unit.villagesCovered} villages'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(
    BuildContext context,
    WidgetRef ref,
    List units,
    bool canManageUnits,
  ) {
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
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Unit Name')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Villages')),
              DataColumn(label: Text('Patients (Mo)')),
              DataColumn(label: Text('Last Active')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: units.map<DataRow>((unit) {
              return DataRow(
                cells: [
                  DataCell(Text(unit.unitCode,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary))),
                  DataCell(Text(unit.name)),
                  DataCell(Text(unit.location)),
                  DataCell(Text('${unit.villagesCovered}')),
                  DataCell(Text('${unit.patientsServedThisMonth}')),
                  DataCell(Text(AppDateUtils.timeAgo(unit.lastActivityTime))),
                  DataCell(StatusBadge.fromString(unit.status)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canManageUnits)
                          IconButton(
                            tooltip: 'Edit unit',
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            onPressed: () =>
                                _showUnitDialog(context, ref, unit: unit),
                          ),
                        IconButton(
                          tooltip: 'View unit',
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          onPressed: () => context.go('/units/${unit.id}'),
                        ),
                      ],
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

  Widget _buildMetric(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _showUnitDialog(
    BuildContext context,
    WidgetRef ref, {
    MobileUnit? unit,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: unit?.name ?? '');
    final codeCtrl = TextEditingController(text: unit?.unitCode ?? '');
    final districtCtrl = TextEditingController(text: unit?.district ?? '');
    final stateCtrl = TextEditingController(text: unit?.state ?? '');
    final vehicleCtrl = TextEditingController(text: unit?.vehicleNumber ?? '');
    final teamMembersCtrl =
        TextEditingController(text: unit?.teamMembers.join(', ') ?? '');
    final teamSizeCtrl = TextEditingController(text: '${unit?.teamSize ?? 0}');
    final villagesCtrl =
        TextEditingController(text: '${unit?.villagesCovered ?? 0}');
    final patientsCtrl =
        TextEditingController(text: '${unit?.patientsServedThisMonth ?? 0}');
    final visitsCtrl =
        TextEditingController(text: '${unit?.visitsThisMonth ?? 0}');
    final latCtrl = TextEditingController(
        text: unit?.currentLatitude == null ? '' : '${unit!.currentLatitude}');
    final lngCtrl = TextEditingController(
        text:
            unit?.currentLongitude == null ? '' : '${unit!.currentLongitude}');
    final officers = ref.read(officersProvider).value ?? const [];
    final existingUnits = ref.read(unitsProvider).value ?? const <MobileUnit>[];
    String? selectedOfficerId =
        officers.any((officer) => officer.id == unit?.supervisorId)
            ? unit?.supervisorId
            : officers
                .where((officer) => officer.unitId == unit?.id)
                .map((officer) => officer.id)
                .firstOrNull;
    var status = unit?.status ?? AppConstants.statusActive;

    final savedUnit = await showDialog<MobileUnit>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screen = MediaQuery.sizeOf(context);
            final dialogWidth = screen.width < 820 ? screen.width - 32 : 720.0;
            final dialogHeight =
                screen.height < 760 ? screen.height - 48 : 680.0;
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: SizedBox(
                width: dialogWidth.clamp(280.0, 720.0),
                height: dialogHeight.clamp(420.0, 680.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              unit == null
                                  ? 'Add Mobile Unit'
                                  : 'Edit Mobile Unit',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dialogRow([
                                _field(
                                  nameCtrl,
                                  'Unit name',
                                  required: true,
                                  validator: (value) {
                                    final name =
                                        value?.trim().toLowerCase() ?? '';
                                    final duplicate = existingUnits.any(
                                      (existing) =>
                                          existing.id != unit?.id &&
                                          existing.name.trim().toLowerCase() ==
                                              name,
                                    );
                                    return duplicate
                                        ? 'Unit name already exists'
                                        : null;
                                  },
                                ),
                                _field(
                                  codeCtrl,
                                  'Unit code',
                                  required: true,
                                  helperText: 'Use format MHU-001',
                                  validator: (value) {
                                    final code =
                                        value?.trim().toUpperCase() ?? '';
                                    if (!RegExp(r'^MHU-\d{3}$')
                                        .hasMatch(code)) {
                                      return 'Use format MHU-001';
                                    }
                                    final duplicate = existingUnits.any(
                                      (existing) =>
                                          existing.id != unit?.id &&
                                          existing.unitCode
                                                  .trim()
                                                  .toUpperCase() ==
                                              code,
                                    );
                                    return duplicate
                                        ? 'Unit code already exists'
                                        : null;
                                  },
                                ),
                              ]),
                              _dialogRow([
                                DropdownButtonFormField<String>(
                                  initialValue: status,
                                  decoration: const InputDecoration(
                                      labelText: 'Status'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: AppConstants.statusActive,
                                        child: Text('Active')),
                                    DropdownMenuItem(
                                        value: AppConstants.statusMaintenance,
                                        child: Text('Maintenance')),
                                    DropdownMenuItem(
                                        value: AppConstants.statusInactive,
                                        child: Text('Inactive')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() => status = value);
                                    }
                                  },
                                ),
                                _field(vehicleCtrl, 'Vehicle number'),
                              ]),
                              _dialogRow([
                                _field(districtCtrl, 'District',
                                    required: true),
                                _field(stateCtrl, 'State', required: true),
                              ]),
                              _dialogRow([
                                _field(latCtrl, 'Latitude', numeric: true),
                                _field(lngCtrl, 'Longitude', numeric: true),
                              ]),
                              _dialogRow([
                                _field(villagesCtrl, 'Villages covered',
                                    numeric: true),
                                _field(
                                    patientsCtrl, 'Patients served this month',
                                    numeric: true),
                              ]),
                              _dialogRow([
                                _field(visitsCtrl, 'Visits this month',
                                    numeric: true),
                                _field(teamSizeCtrl, 'Team size',
                                    numeric: true),
                              ]),
                              _field(teamMembersCtrl,
                                  'Team members, separated by commas'),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedOfficerId,
                                decoration: const InputDecoration(
                                  labelText: 'Assign Doctor/Nurse',
                                  helperText:
                                      'Select by name/email. The unit ID is synced automatically.',
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('No Doctor/Nurse assigned'),
                                  ),
                                  ...officers.map(
                                    (officer) => DropdownMenuItem<String>(
                                      value: officer.id,
                                      child: Text(
                                        '${officer.name} - ${officer.id} (${officer.email})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setDialogState(
                                      () => selectedOfficerId = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              final now = DateTime.now();
                              final teamMembers = teamMembersCtrl.text
                                  .split(',')
                                  .map((item) => item.trim())
                                  .where((item) => item.isNotEmpty)
                                  .toList();
                              final assignedOfficer = officers
                                  .where((officer) =>
                                      officer.id == selectedOfficerId)
                                  .firstOrNull;
                              if (assignedOfficer != null &&
                                  !teamMembers.contains(assignedOfficer.name)) {
                                teamMembers.add(assignedOfficer.name);
                              }
                              final saved = MobileUnit(
                                id: unit?.id ??
                                    'unit_${now.millisecondsSinceEpoch}',
                                name: nameCtrl.text.trim(),
                                unitCode: codeCtrl.text.trim().toUpperCase(),
                                status: status,
                                teamSize: _intValue(teamSizeCtrl.text),
                                teamMembers: teamMembers,
                                district: districtCtrl.text.trim(),
                                state: stateCtrl.text.trim(),
                                villagesCovered: _intValue(villagesCtrl.text),
                                lastActivityTime: unit?.lastActivityTime ?? now,
                                currentLatitude:
                                    double.tryParse(latCtrl.text.trim()),
                                currentLongitude:
                                    double.tryParse(lngCtrl.text.trim()),
                                patientsServedThisMonth:
                                    _intValue(patientsCtrl.text),
                                visitsThisMonth: _intValue(visitsCtrl.text),
                                operationalSince: unit?.operationalSince ?? now,
                                vehicleNumber: vehicleCtrl.text.trim(),
                                supervisorId: selectedOfficerId ?? '',
                              );
                              Navigator.pop(dialogContext, saved);
                            },
                            child: Text(
                                unit == null ? 'Create Unit' : 'Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (savedUnit != null) {
      try {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saving mobile unit...')),
          );
        }
        await ref.read(saveUnitProvider)(savedUnit);
        if (savedUnit.supervisorId.isNotEmpty) {
          await FirebaseDataService.assignUserToUnit(
            userId: savedUnit.supervisorId,
            unitId: savedUnit.id,
          );
          ref.invalidate(usersProvider);
          ref.invalidate(officersProvider);
        }
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(analyticsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                unit == null ? 'Mobile unit created.' : 'Mobile unit updated.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save mobile unit: $e')),
          );
        }
      }
    }

    nameCtrl.dispose();
    codeCtrl.dispose();
    districtCtrl.dispose();
    stateCtrl.dispose();
    vehicleCtrl.dispose();
    teamMembersCtrl.dispose();
    teamSizeCtrl.dispose();
    villagesCtrl.dispose();
    patientsCtrl.dispose();
    visitsCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
  }

  Widget _buildFilters(WidgetRef ref, String filter) {
    final search = SizedBox(
      height: 40,
      child: TextFormField(
        controller: _searchCtrl,
        onChanged: (val) =>
            ref.read(unitSearchQueryProvider.notifier).state = val,
        decoration: InputDecoration(
          hintText: 'Search by unit name, code, district, or state...',
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
    final dropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filter,
          onChanged: (val) {
            if (val != null) {
              ref.read(unitFilterProvider.notifier).state = val;
            }
          },
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Statuses')),
            DropdownMenuItem(
                value: AppConstants.statusActive, child: Text('Active Only')),
            DropdownMenuItem(
                value: AppConstants.statusMaintenance,
                child: Text('Maintenance')),
            DropdownMenuItem(
                value: AppConstants.statusInactive, child: Text('Inactive')),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: dropdown),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            dropdown,
          ],
        );
      },
    );
  }

  Widget _dialogRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: children
                  .map(
                    (child) => Padding(
                      padding: EdgeInsets.only(
                        bottom: child == children.last ? 0 : 12,
                      ),
                      child: child,
                    ),
                  )
                  .toList(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: children
                .map(
                  (child) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: child == children.last ? 0 : 12,
                      ),
                      child: child,
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, helperText: helperText),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        if (numeric &&
            value != null &&
            value.trim().isNotEmpty &&
            double.tryParse(value.trim()) == null) {
          return 'Enter a valid number';
        }
        return validator?.call(value);
      },
    );
  }

  int _intValue(String value) => int.tryParse(value.trim()) ?? 0;
}

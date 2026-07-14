import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../providers/reports_provider.dart';
import '../../domain/entities/service_report.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mobile_units/presentation/providers/units_provider.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Location / Metadata
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  DateTime _campDate = DateTime.now();

  // Population served controllers
  final _maleCtrl = TextEditingController(text: '0');
  final _femaleCtrl = TextEditingController(text: '0');
  final _childrenCtrl = TextEditingController(text: '0');
  final _seniorsCtrl = TextEditingController(text: '0');

  // Service tracking controllers
  final _consultsCtrl = TextEditingController(text: '0');
  final _diabetesCtrl = TextEditingController(text: '0');
  final _hyperCtrl = TextEditingController(text: '0');
  final _maternalCtrl = TextEditingController(text: '0');
  final _childCtrl = TextEditingController(text: '0');
  final _vaxCtrl = TextEditingController(text: '0');
  final _referralsCtrl = TextEditingController(text: '0');

  final _remarksCtrl = TextEditingController();
  String? _selectedUnitId;

  @override
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    _childrenCtrl.dispose();
    _seniorsCtrl.dispose();
    _consultsCtrl.dispose();
    _diabetesCtrl.dispose();
    _hyperCtrl.dispose();
    _maternalCtrl.dispose();
    _childCtrl.dispose();
    _vaxCtrl.dispose();
    _referralsCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final units = ref.read(unitsProvider).value ?? const [];
    final selectedUnitId = _selectedUnitId ??
        (units.any((unit) => unit.id == user?.unitId) ? user?.unitId : null);
    final selectedUnit =
        units.where((unit) => unit.id == selectedUnitId).firstOrNull;
    if (user == null || selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a mobile unit before submitting the report.'),
        ),
      );
      return;
    }

    final report = ServiceReport(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      unitId: selectedUnit.id,
      unitName: selectedUnit.name,
      officerId: user.id,
      officerName: user.name,
      campDate: _campDate,
      villageName: _villageCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      totalMale: int.parse(_maleCtrl.text),
      totalFemale: int.parse(_femaleCtrl.text),
      totalChildren: int.parse(_childrenCtrl.text),
      totalSeniorCitizens: int.parse(_seniorsCtrl.text),
      generalConsultations: int.parse(_consultsCtrl.text),
      diabetesScreening: int.parse(_diabetesCtrl.text),
      hypertensionScreening: int.parse(_hyperCtrl.text),
      maternalHealthServices: int.parse(_maternalCtrl.text),
      childHealthServices: int.parse(_childCtrl.text),
      vaccinationSupport: int.parse(_vaxCtrl.text),
      referralCases: int.parse(_referralsCtrl.text),
      remarks: _remarksCtrl.text.trim(),
      submittedAt: DateTime.now(),
      isVerified: false,
    );

    await ref.read(reportsProvider.notifier).submitReport(report);
    if (!mounted) return;
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(analyticsProvider);
    ref.invalidate(unitsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service report submitted successfully!')),
    );
    context.go('/reports');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final units = ref.watch(unitsProvider).value ?? const [];
    final selectedUnitId = _selectedUnitId ??
        (units.any((unit) => unit.id == user?.unitId) ? user?.unitId : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reports'),
        ),
        title: Text('New Outreach Service Report',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Form header card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Outreach Camp Location details',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text('Mobile Unit',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedUnitId,
                            decoration: const InputDecoration(
                              hintText: 'Select mobile unit',
                            ),
                            items: units
                                .map(
                                  (unit) => DropdownMenuItem<String>(
                                    value: unit.id,
                                    child: Text(
                                      '${unit.unitCode} - ${unit.name}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (value) => value == null
                                ? 'Mobile unit is required'
                                : null,
                            onChanged: (value) {
                              setState(() => _selectedUnitId = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildTextField(
                              label: 'Village / Site Name',
                              controller: _villageCtrl,
                              hintText: 'Enter site name',
                              requiredMessage: 'Village name required',
                            ),
                            _buildTextField(
                              label: 'District',
                              controller: _districtCtrl,
                              hintText: 'Enter district',
                              requiredMessage: 'District required',
                            ),
                          ]),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildTextField(
                              label: 'State',
                              controller: _stateCtrl,
                              hintText: 'Enter state',
                              requiredMessage: 'State required',
                            ),
                            _buildDateField(context),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Population Served Grid
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Population Served Metrics',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildCounterField('Male Patients', _maleCtrl),
                            _buildCounterField('Female Patients', _femaleCtrl),
                          ]),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildCounterField(
                                'Children (<12y)', _childrenCtrl),
                            _buildCounterField(
                                'Senior Citizens (>60y)', _seniorsCtrl),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Healthcare Services Provided
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Healthcare Services Provided',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildCounterField(
                                'General Consults', _consultsCtrl),
                            _buildCounterField(
                                'Diabetes Screens', _diabetesCtrl),
                          ]),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildCounterField(
                                'Hypertension Screens', _hyperCtrl),
                            _buildCounterField(
                                'Maternal Services', _maternalCtrl),
                          ]),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildCounterField('Child Health', _childCtrl),
                            _buildCounterField('Vaccination support', _vaxCtrl),
                          ]),
                          const SizedBox(height: 16),
                          _buildResponsiveFields([
                            _buildCounterField(
                                'Referral Cases', _referralsCtrl),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Remarks & actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Remarks / Additional Notes',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _remarksCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText:
                                    'Enter outreach camp feedback or emergency reports...'),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Submit Outreach Report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveFields(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                SizedBox(width: double.infinity, child: children[i]),
                if (i != children.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
            if (children.length == 1) const Expanded(child: SizedBox()),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String requiredMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
          validator: (v) => (v == null || v.isEmpty) ? requiredMessage : null,
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Camp Date',
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _campDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() => _campDate = picked);
            }
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${_campDate.day}/${_campDate.month}/${_campDate.year}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Count is required';
            }
            if (int.tryParse(v) == null) {
              return 'Must be a valid integer';
            }
            return null;
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

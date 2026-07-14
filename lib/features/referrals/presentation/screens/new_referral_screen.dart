import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../providers/referrals_provider.dart';
import '../../domain/entities/referral.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mobile_units/presentation/providers/units_provider.dart';

class NewReferralScreen extends ConsumerStatefulWidget {
  const NewReferralScreen({super.key});

  @override
  ConsumerState<NewReferralScreen> createState() => _NewReferralScreenState();
}

class _NewReferralScreenState extends ConsumerState<NewReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientCodeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _gender = 'Male';
  String _priority = 'Medium';
  String? _selectedUnitId;

  @override
  void dispose() {
    _patientCodeCtrl.dispose();
    _ageCtrl.dispose();
    _reasonCtrl.dispose();
    _facilityCtrl.dispose();
    _notesCtrl.dispose();
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
          content: Text('Select a mobile unit before creating the referral.'),
        ),
      );
      return;
    }

    final referral = Referral(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      unitId: selectedUnit.id,
      unitName: selectedUnit.name,
      officerId: user.id,
      officerName: user.name,
      patientCode: _patientCodeCtrl.text.trim(),
      age: int.parse(_ageCtrl.text),
      gender: _gender,
      reason: _reasonCtrl.text.trim(),
      referredFacility: _facilityCtrl.text.trim(),
      status: 'pending',
      priority: _priority,
      followUpNotes: _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(referralsProvider.notifier).createReferral(referral);
    if (!mounted) return;
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(analyticsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral case created successfully!')),
    );
    context.go('/referrals');
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
          onPressed: () => context.go('/referrals'),
        ),
        title: Text('Create Medical Referral Case',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient Details',
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
                        validator: (value) =>
                            value == null ? 'Mobile unit is required' : null,
                        onChanged: (value) {
                          setState(() => _selectedUnitId = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Patient Code
                      Text('Patient Code',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _patientCodeCtrl,
                        decoration: const InputDecoration(
                            hintText:
                                'Enter internal Patient identifier (e.g. PAT-2024-101)'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Patient code required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          // Age
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Age',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _ageCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(hintText: 'Years'),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Age required';
                                    }
                                    if (int.tryParse(v) == null) {
                                      return 'Must be a valid integer';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Gender Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gender',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _gender,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _gender = val);
                                        }
                                      },
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(
                                            value: 'Female',
                                            child: Text('Female')),
                                        DropdownMenuItem(
                                            value: 'Other',
                                            child: Text('Other')),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text('Clinical Referral Details',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Referred Facility
                      Text('Referred Facility / Hospital',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _facilityCtrl,
                        decoration: const InputDecoration(
                            hintText: 'e.g. District General Hospital'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Referred facility required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Priority Dropdown
                      Text('Referral Priority / Severity',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _priority,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _priority = val);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                  value: 'Low', child: Text('Low')),
                              DropdownMenuItem(
                                  value: 'Medium', child: Text('Medium')),
                              DropdownMenuItem(
                                  value: 'High', child: Text('High')),
                              DropdownMenuItem(
                                  value: 'Critical', child: Text('Critical')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      Text('Reason for Referral / Symptoms',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _reasonCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            hintText:
                                'Enter clinical symptoms, diagnosis reasons, glucose levels...'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Referral reason required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Follow-up Notes
                      Text('Follow-up Instructions / Notes',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            hintText:
                                'Any specific instructions for follow-up staff...'),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Create Referral Case'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

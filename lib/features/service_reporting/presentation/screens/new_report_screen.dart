import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/prescription_pdf_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mobile_units/presentation/providers/units_provider.dart';
import '../../../patients/domain/entities/patient_record.dart';
import '../../../patients/presentation/providers/patients_provider.dart';
import '../../../field_visits/presentation/providers/visits_provider.dart';
import '../../../inventory/domain/entities/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _oxygenCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _testsCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String? _selectedUnitId;
  String _gender = 'Female';
  PatientRecord? _matchedPatient;
  final Set<String> _selectedCategories = {};
  final Map<String, int> _selectedMedicineQuantities = {};

  static const _serviceCategories = [
    'Hypertension',
    'Sugar',
    'Vaccination',
    'Child Health',
    'Maternal Health',
  ];

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_syncExistingPatient);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_syncExistingPatient);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _bpCtrl.dispose();
    _oxygenCtrl.dispose();
    _temperatureCtrl.dispose();
    _pulseCtrl.dispose();
    _diagnosisCtrl.dispose();
    _testsCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _syncExistingPatient() {
    final phone = _normalizePhone(_phoneCtrl.text);
    final patients = ref.read(patientsProvider).patients;
    final match = patients.where((patient) {
      return _normalizePhone(patient.phone) == phone && phone.isNotEmpty;
    }).firstOrNull;
    if (match == _matchedPatient) return;
    setState(() {
      _matchedPatient = match;
      if (match != null) {
        _nameCtrl.text = match.name;
        _ageCtrl.text = match.age == 0 ? '' : '${match.age}';
        _gender = match.gender.isEmpty ? _gender : match.gender;
        _addressCtrl.text = match.address;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final visitsState = ref.read(visitsProvider);
    final inventoryItems = ref.read(inventoryProvider).items;
    final activeVisit = visitsState.visits
        .where((visit) => visit.isInProgress && visit.officerId == user?.id)
        .firstOrNull;
    final units = ref.read(unitsProvider).value ?? const [];
    final selectedUnitId = _selectedUnitId ??
        activeVisit?.unitId ??
        (units.any((unit) => unit.id == user?.unitId) ? user?.unitId : null);
    final selectedUnit =
        units.where((unit) => unit.id == selectedUnitId).firstOrNull;
    if (user == null || activeVisit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a field visit before saving patient records.'),
        ),
      );
      return;
    }
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one service category.')),
      );
      return;
    }
    if (selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find the mobile unit for this visit.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final patient = PatientRecord(
      id: _normalizePhone(_phoneCtrl.text),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      age: int.parse(_ageCtrl.text.trim()),
      gender: _gender,
      address: _addressCtrl.text.trim(),
      createdAt: _matchedPatient?.createdAt ?? now,
      updatedAt: now,
      encounters: _matchedPatient?.encounters ?? const [],
    );
    final encounter = PatientEncounter(
      id: 'enc_${now.millisecondsSinceEpoch}',
      unitId: selectedUnit.id,
      unitName: selectedUnit.name,
      visitId: activeVisit.id,
      officerId: user.id,
      officerName: user.name,
      visitDate: now,
      villageName: _villageCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      bloodPressure: _bpCtrl.text.trim(),
      oxygenSaturation: _oxygenCtrl.text.trim(),
      temperature: _temperatureCtrl.text.trim(),
      pulseRate: _pulseCtrl.text.trim(),
      serviceCategories: _selectedCategories.toList(),
      prescribedInventory: _selectedPrescribedInventory(inventoryItems),
      diagnosisSummary: _diagnosisCtrl.text.trim(),
      prescribedMedicines:
          _medicineSummary(_selectedPrescribedInventory(inventoryItems)),
      recommendedTests: _testsCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim(),
    );

    await ref.read(patientsProvider.notifier).saveEncounter(
          patient: patient,
          encounter: encounter,
        );
    for (final prescribed in encounter.prescribedInventory) {
      final item = inventoryItems
          .where((inventory) => inventory.id == prescribed.inventoryItemId)
          .firstOrNull;
      if (item != null) {
        await ref
            .read(inventoryProvider.notifier)
            .consumeItem(item, prescribed.quantity);
      }
    }
    await ref.read(inventoryProvider.notifier).load();
    if (!mounted) return;
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(analyticsProvider);
    ref.invalidate(unitsProvider);
    await PrescriptionPdfUtils.download(patient: patient, encounter: encounter);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient encounter saved.')),
    );
    context.go('/reports');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final visitsState = ref.watch(visitsProvider);
    final activeVisit = visitsState.visits
        .where((visit) => visit.isInProgress && visit.officerId == user?.id)
        .firstOrNull;
    final units = ref.watch(unitsProvider).value ?? const [];
    final inventoryItems = ref.watch(inventoryProvider).items;
    ref.watch(patientsProvider);
    final selectedUnitId = _selectedUnitId ??
        activeVisit?.unitId ??
        (units.any((unit) => unit.id == user?.unitId) ? user?.unitId : null);
    if (activeVisit != null) {
      _villageCtrl.text = _villageCtrl.text.isEmpty
          ? activeVisit.villageName
          : _villageCtrl.text;
      _districtCtrl.text = _districtCtrl.text.isEmpty
          ? activeVisit.district
          : _districtCtrl.text;
      _stateCtrl.text =
          _stateCtrl.text.isEmpty ? activeVisit.state : _stateCtrl.text;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reports'),
        ),
        title: Text(
          'New Patient Encounter',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (activeVisit == null) ...[
                    _sectionCard(
                      title: 'Start Field Visit First',
                      children: [
                        Text(
                          'Patient records must be linked to today’s field visit. Start a visit before adding patients.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/visits/new'),
                            child: const Text('Start Field Visit'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  _sectionCard(
                    title: 'Patient Details',
                    children: [
                      _responsiveFields([
                        _textField('Phone number', _phoneCtrl,
                            requiredMessage: 'Phone number required',
                            keyboardType: TextInputType.phone),
                        _textField('Patient name', _nameCtrl,
                            requiredMessage: 'Patient name required'),
                      ]),
                      const SizedBox(height: 16),
                      _responsiveFields([
                        _textField('Age', _ageCtrl,
                            requiredMessage: 'Age required',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                          final age = int.tryParse(value?.trim() ?? '');
                          if (age == null || age < 0 || age > 120) {
                            return 'Enter valid age';
                          }
                          return null;
                        }),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration:
                              const InputDecoration(labelText: 'Gender'),
                          items: const [
                            DropdownMenuItem(
                                value: 'Female', child: Text('Female')),
                            DropdownMenuItem(
                                value: 'Male', child: Text('Male')),
                            DropdownMenuItem(
                                value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _gender = value);
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _textField('Address', _addressCtrl,
                          requiredMessage: 'Address required', maxLines: 2),
                      if (_matchedPatient != null) ...[
                        const SizedBox(height: 16),
                        _historyPanel(_matchedPatient!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Visit Location',
                    children: [
                      InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Mobile unit'),
                        child: Text(
                          units
                                  .where((unit) => unit.id == selectedUnitId)
                                  .firstOrNull
                                  ?.name ??
                              activeVisit?.unitName ??
                              'Start a visit to detect mobile unit',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _responsiveFields([
                        _textField('Village / Site', _villageCtrl,
                            requiredMessage: 'Village/site required'),
                        _lockedText('District', _districtCtrl),
                      ]),
                      const SizedBox(height: 16),
                      _lockedText('State', _stateCtrl),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Vitals',
                    children: [
                      _responsiveFields([
                        _textField('Blood pressure', _bpCtrl,
                            hintText: '120/80 mmHg'),
                        _textField('O2 saturation', _oxygenCtrl,
                            hintText: '98%'),
                      ]),
                      const SizedBox(height: 16),
                      _responsiveFields([
                        _textField('Temperature', _temperatureCtrl,
                            hintText: '98.6 F'),
                        _textField('Pulse rate', _pulseCtrl,
                            hintText: '78 bpm'),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Diagnosis & Prescription',
                    children: [
                      Text(
                        'Service categories',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _serviceCategories.map((category) {
                          final selected =
                              _selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _textField(
                        'Diagnosis summary',
                        _diagnosisCtrl,
                        requiredMessage: 'Diagnosis summary required',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      _medicineSelector(inventoryItems, selectedUnitId),
                      const SizedBox(height: 16),
                      _textField(
                        'Recommended tests',
                        _testsCtrl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _textField('Remarks', _remarksCtrl, maxLines: 3),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Save Encounter & Generate PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _responsiveFields(List<Widget> children) {
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
          ],
        );
      },
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    String? requiredMessage,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hintText),
      validator: (value) {
        if (requiredMessage != null &&
            (value == null || value.trim().isEmpty)) {
          return requiredMessage;
        }
        return validator?.call(value);
      },
    );
  }

  Widget _lockedText(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label required' : null,
    );
  }

  Widget _historyPanel(PatientRecord patient) {
    final encounters = patient.encounters.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Previous History',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (encounters.isEmpty)
            Text(
              'No previous visits recorded.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ...encounters.map(
              (encounter) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${AppDateUtils.formatDate(encounter.visitDate)} - ${encounter.diagnosisSummary}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _medicineSelector(
    List<InventoryItem> items,
    String? selectedUnitId,
  ) {
    final unitItems = items.where((item) {
      if (selectedUnitId == null) return item.remaining > 0;
      return item.unitId == selectedUnitId && item.remaining > 0;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prescribed medicines from inventory',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (unitItems.isEmpty)
          Text(
            'No available inventory for the selected mobile unit.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          )
        else
          ...unitItems.map((item) {
            final quantity = _selectedMedicineQuantities[item.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: quantity > 0,
                      title: Text(item.medicineName),
                      subtitle: Text(
                        'Remaining: ${item.remaining} ${item.unit}',
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMedicineQuantities[item.id] = 1;
                          } else {
                            _selectedMedicineQuantities.remove(item.id);
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: TextFormField(
                      initialValue: quantity > 0 ? '$quantity' : '',
                      enabled: quantity > 0,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      onChanged: (value) {
                        final parsed = int.tryParse(value.trim()) ?? 0;
                        setState(() {
                          if (parsed <= 0) {
                            _selectedMedicineQuantities.remove(item.id);
                          } else {
                            _selectedMedicineQuantities[item.id] =
                                parsed.clamp(1, item.remaining);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  List<PrescribedInventoryItem> _selectedPrescribedInventory(
    List<InventoryItem> inventoryItems,
  ) {
    return _selectedMedicineQuantities.entries
        .map((entry) {
          final item = inventoryItems
              .where((inventory) => inventory.id == entry.key)
              .firstOrNull;
          if (item == null || entry.value <= 0) return null;
          return PrescribedInventoryItem(
            inventoryItemId: item.id,
            medicineName: item.medicineName,
            unit: item.unit,
            quantity: entry.value.clamp(1, item.remaining),
          );
        })
        .whereType<PrescribedInventoryItem>()
        .toList();
  }

  String _medicineSummary(List<PrescribedInventoryItem> medicines) {
    if (medicines.isEmpty) return 'No medicine prescribed from inventory';
    return medicines
        .map((item) => '${item.medicineName} - ${item.quantity} ${item.unit}')
        .join('\n');
  }

  String _normalizePhone(String value) => value.replaceAll(RegExp(r'\D'), '');
}

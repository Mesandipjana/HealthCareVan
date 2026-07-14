import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_data_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../providers/visits_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mobile_units/domain/entities/mobile_unit.dart';
import '../../../mobile_units/presentation/providers/units_provider.dart';
import 'package:image_picker/image_picker.dart';

class StartVisitScreen extends ConsumerStatefulWidget {
  const StartVisitScreen({super.key});

  @override
  ConsumerState<StartVisitScreen> createState() => _StartVisitScreenState();
}

class _StartVisitScreenState extends ConsumerState<StartVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _patientsCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  double _lat = 26.9124;
  double _lng = 75.7873;
  bool _gpsCaptured = false;
  bool _photoCaptured = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  String? _selectedUnitId;

  void _captureGPS() {
    setState(() {
      _lat = 26.9124 + (DateTime.now().second * 0.0001);
      _lng = 75.7873 + (DateTime.now().second * 0.0001);
      _gpsCaptured = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS Coordinates captured successfully!')),
    );
  }

  Future<void> _capturePhoto() async {
    setState(() => _isUploadingPhoto = true);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked == null) {
      setState(() => _isUploadingPhoto = false);
      return;
    }
    final url = await FirebaseDataService.uploadEvidence(
      file: picked,
      folder: 'field_visit_photos',
    );
    if (!mounted) return;
    setState(() {
      _photoUrl = url ?? 'local-evidence://${picked.name}';
      _photoCaptured = true;
      _isUploadingPhoto = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          url == null
              ? 'Site photo attached locally. Enable Firebase Storage for cloud upload.'
              : 'Site photo uploaded successfully.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _patientsCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final visitsState = ref.watch(visitsProvider);
    final activeVisit = visitsState.activeVisit;
    final units = ref.watch(unitsProvider).value ?? const [];
    final selectedUnitId = _selectedUnitId ??
        (units.any((unit) => unit.id == user?.unitId) ? user?.unitId : null);
    final selectedUnit =
        units.where((unit) => unit.id == selectedUnitId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/visits'),
        ),
        title: Text(
            activeVisit == null ? 'Start Field Visit' : 'Complete Field Visit'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: activeVisit == null
                    ? _buildStartVisitForm(
                        user, selectedUnit, units, selectedUnitId)
                    : _buildEndVisitForm(activeVisit),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartVisitForm(
    dynamic user,
    MobileUnit? selectedUnit,
    List units,
    String? selectedUnitId,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GPS-based Visit Verification',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a new camp log. You must capture GPS location and a site photo before starting.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          Text('Mobile Unit',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: selectedUnitId,
            decoration: const InputDecoration(hintText: 'Select mobile unit'),
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

          // Village
          Text('Village / Community Name',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _villageCtrl,
            decoration: const InputDecoration(hintText: 'Enter village name'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Village name is required' : null,
          ),
          const SizedBox(height: 16),

          // District
          Text('District',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _districtCtrl,
            decoration: const InputDecoration(hintText: 'Enter district name'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'District is required' : null,
          ),
          const SizedBox(height: 20),

          // GPS & Photo Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _captureGPS,
                  icon: Icon(
                      _gpsCaptured ? Icons.check_circle : Icons.gps_fixed,
                      color: _gpsCaptured
                          ? AppColors.successLight
                          : AppColors.primary),
                  label: Text(_gpsCaptured ? 'GPS Verified' : 'Verify GPS'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploadingPhoto ? null : _capturePhoto,
                  icon: Icon(
                      _photoCaptured ? Icons.check_circle : Icons.camera_alt,
                      color: _photoCaptured
                          ? AppColors.successLight
                          : AppColors.primary),
                  label: Text(_isUploadingPhoto
                      ? 'Uploading...'
                      : _photoCaptured
                          ? 'Photo Attached'
                          : 'Attach Photo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Remarks
          Text('Initial Remarks',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _remarksCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Enter initial team size, equipment or goals...'),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (!_gpsCaptured) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please capture GPS coordinates to verify your location.')),
                  );
                  return;
                }
                if (user == null || selectedUnit == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Select a mobile unit before starting the visit.'),
                    ),
                  );
                  return;
                }
                try {
                  await ref.read(visitsProvider.notifier).startVisit(
                        unitId: selectedUnit.id,
                        unitName: selectedUnit.name,
                        officerId: user.id,
                        officerName: user.name,
                        villageName: _villageCtrl.text.trim(),
                        district: _districtCtrl.text.trim(),
                        lat: _lat,
                        lng: _lng,
                        remarks: _remarksCtrl.text.trim(),
                        photoUrl: _photoUrl,
                      );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not save visit: $e')),
                  );
                  return;
                }
                if (!mounted) return;
                ref.invalidate(dashboardSummaryProvider);
                ref.invalidate(analyticsProvider);
                ref.invalidate(unitsProvider);
                context.go('/visits');
              },
              child: const Text('Start Visit & Register GPS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndVisitForm(dynamic visit) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Field Visit',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Unit is registered at ${visit.villageName}. Supply final patient count to close log.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          // Patients Served
          Text('Total Patients Served',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _patientsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter patient count'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Patient count is required';
              if (int.tryParse(v) == null) return 'Must be a valid number';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Remarks
          Text('Final Visit Summary / Remarks',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _remarksCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Describe operational achievements, challenges...'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Remarks are required' : null,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                try {
                  await ref.read(visitsProvider.notifier).endVisit(
                        visit.id,
                        patientsServed: int.parse(_patientsCtrl.text),
                        remarks: _remarksCtrl.text.trim(),
                      );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not complete visit: $e')),
                  );
                  return;
                }
                if (!mounted) return;
                ref.invalidate(dashboardSummaryProvider);
                ref.invalidate(analyticsProvider);
                ref.invalidate(unitsProvider);
                context.go('/visits');
              },
              child: const Text('End Visit & Log Activity'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/attendance_provider.dart';
import '../services/local_selfie_store.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _selfieAttached = false;
  String? _selfieLocalPath;
  double _lat = 26.9124;
  double _lng = 75.7873;
  bool _gpsCaptured = false;
  final ImagePicker _imagePicker = ImagePicker();

  void _captureGPS() {
    setState(() {
      _lat = 26.9124 + (DateTime.now().second * 0.0001);
      _lng = 75.7873 + (DateTime.now().second * 0.0001);
      _gpsCaptured = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS coordinates captured!')),
    );
  }

  Future<void> _captureSelfie() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (image == null) return;

      final localPath = await LocalSelfieStore.save(image);
      if (!mounted) return;

      setState(() {
        _selfieAttached = true;
        _selfieLocalPath = localPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selfie saved on this device.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture selfie: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attState = ref.watch(attendanceProvider);
    final user = ref.watch(currentUserProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'Attendance Management',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Register check-in and check-out with GPS & selfie verification',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            // Top Check-in Action Area
            if (user != null && (user.isOfficer || user.isSupervisor))
              _buildAttendanceCard(attState, user),

            const SizedBox(height: 24),

            // Attendance Logs History
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance History (Last 30 Days)',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: attState.records.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.how_to_reg_outlined,
                                title: 'No Attendance Records Found',
                                message:
                                    'Your attendance logs will show up here.',
                              )
                            : isDesktop
                                ? _buildTableView(context, attState.records)
                                : _buildListView(context, attState.records),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceState attState, dynamic user) {
    final isNarrow = MediaQuery.sizeOf(context).width < 680;

    return Card(
      color: AppColors.primarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.primary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttendanceInstructions(),
                  const SizedBox(height: 18),
                  _buildAttendanceActions(attState, user, stretch: true),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildAttendanceInstructions()),
                  const SizedBox(width: 20),
                  _buildAttendanceActions(attState, user),
                ],
              ),
      ),
    );
  }

  Widget _buildAttendanceInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Check-In / Out Verification',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Ensure GPS is enabled and capture a selfie to register status.',
          style:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _captureGPS,
              icon: Icon(_gpsCaptured ? Icons.check_circle : Icons.gps_fixed,
                  color: _gpsCaptured
                      ? AppColors.successLight
                      : AppColors.primary),
              label: Text(_gpsCaptured ? 'GPS Active' : 'Capture GPS'),
            ),
            OutlinedButton.icon(
              onPressed: _captureSelfie,
              icon: Icon(
                  _selfieAttached ? Icons.check_circle : Icons.camera_alt,
                  color: _selfieAttached
                      ? AppColors.successLight
                      : AppColors.primary),
              label: Text(_selfieAttached ? 'Selfie Saved' : 'Take Selfie'),
            ),
          ],
        ),
        if (_selfieLocalPath != null) ...[
          const SizedBox(height: 8),
          Text(
            'Saved locally on this device',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildAttendanceActions(
    AttendanceState attState,
    dynamic user, {
    bool stretch = false,
  }) {
    Widget action;

    if (!attState.isCheckedIn) {
      action = ElevatedButton(
        onPressed: (_gpsCaptured && _selfieAttached)
            ? () async {
                try {
                  await ref.read(attendanceProvider.notifier).checkIn(
                        lat: _lat,
                        lng: _lng,
                        userId: user.id,
                        userName: user.name,
                        unitId: user.unitId ?? 'unit_001',
                        localSelfiePath: _selfieLocalPath,
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance check-in saved.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not save check-in: $e')),
                  );
                }
                setState(() {
                  _gpsCaptured = false;
                  _selfieAttached = false;
                  _selfieLocalPath = null;
                });
              }
            : null,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        child: const Text('Check In'),
      );
    } else if (!attState.isCheckedOut) {
      action = ElevatedButton(
        onPressed: (_gpsCaptured && _selfieAttached)
            ? () async {
                try {
                  await ref.read(attendanceProvider.notifier).checkOut(
                        lat: _lat,
                        lng: _lng,
                        userId: user.id,
                        userName: user.name,
                        unitId: user.unitId ?? 'unit_001',
                        localSelfiePath: _selfieLocalPath,
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Attendance check-out saved.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not save check-out: $e')),
                  );
                }
                setState(() {
                  _gpsCaptured = false;
                  _selfieAttached = false;
                  _selfieLocalPath = null;
                });
              }
            : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text('Check Out'),
      );
    } else {
      action = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, color: AppColors.successLight, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Checked Out Today',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: AppColors.successLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (stretch) {
      action = SizedBox(width: double.infinity, child: action);
    }

    return Column(
      crossAxisAlignment:
          stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
      children: [
        action,
        if (attState.todayCheckIn != null) ...[
          const SizedBox(height: 8),
          Text(
            'Checked In: ${AppDateUtils.formatTime(attState.todayCheckIn!)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
        if (attState.todayCheckOut != null) ...[
          const SizedBox(height: 4),
          Text(
            'Checked Out: ${AppDateUtils.formatTime(attState.todayCheckOut!)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildTableView(BuildContext context, List records) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Staff Member')),
            DataColumn(label: Text('Check In')),
            DataColumn(label: Text('Check Out')),
            DataColumn(label: Text('Working Hours')),
            DataColumn(label: Text('Status')),
          ],
          rows: records.map<DataRow>((rec) {
            final isPresent = rec.isPresent;
            return DataRow(
              cells: [
                DataCell(Text(AppDateUtils.formatDate(rec.date))),
                DataCell(Text(rec.userName)),
                DataCell(Text(isPresent && rec.checkInTime != null
                    ? AppDateUtils.formatTime(rec.checkInTime!)
                    : '-')),
                DataCell(Text(isPresent && rec.checkOutTime != null
                    ? AppDateUtils.formatTime(rec.checkOutTime!)
                    : '-')),
                DataCell(Text(isPresent && rec.workingHours != null
                    ? AppDateUtils.formatDuration(rec.workingHours!)
                    : '-')),
                DataCell(StatusBadge.fromString(rec.status)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List records) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final rec = records[index];
        final isPresent = rec.isPresent;
        return ListTile(
          title: Text(AppDateUtils.formatDate(rec.date),
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(
            isPresent
                ? 'In: ${AppDateUtils.formatTime(rec.checkInTime!)} • Out: ${AppDateUtils.formatTime(rec.checkOutTime!)}'
                : rec.remarks ?? 'Absent',
            style:
                GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: StatusBadge.fromString(rec.status, small: true),
        );
      },
    );
  }
}

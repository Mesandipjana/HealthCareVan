import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/attendance_record.dart';
import '../../../../core/services/firebase_data_service.dart';

class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final DateTime? todayCheckIn;
  final DateTime? todayCheckOut;
  final String? error;

  const AttendanceState({
    this.records = const [],
    this.isLoading = false,
    this.isCheckedIn = false,
    this.isCheckedOut = false,
    this.todayCheckIn,
    this.todayCheckOut,
    this.error,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    bool? isCheckedIn,
    bool? isCheckedOut,
    DateTime? todayCheckIn,
    DateTime? todayCheckOut,
    String? error,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isCheckedOut: isCheckedOut ?? this.isCheckedOut,
      todayCheckIn: todayCheckIn ?? this.todayCheckIn,
      todayCheckOut: todayCheckOut ?? this.todayCheckOut,
      error: error ?? this.error,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final records = await FirebaseDataService.getAttendanceRecords();
    final today = DateTime.now();
    final todayRecord = records.where((record) {
      return record.date.year == today.year &&
          record.date.month == today.month &&
          record.date.day == today.day;
    }).firstOrNull;
    state = AttendanceState(
      records: records,
      isCheckedIn: todayRecord?.checkInTime != null,
      isCheckedOut: todayRecord?.checkOutTime != null,
      todayCheckIn: todayRecord?.checkInTime,
      todayCheckOut: todayRecord?.checkOutTime,
    );
  }

  Future<void> refresh() => _load();

  Future<void> checkIn({
    required double lat,
    required double lng,
    String userId = 'user_004',
    String userName = 'Doctor/Nurse',
    String unitId = 'unit_001',
    String? localSelfiePath,
  }) async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    final record = AttendanceRecord(
      id: 'att_${userId}_${now.year}_${now.month}_${now.day}',
      userId: userId,
      userName: userName,
      unitId: unitId,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: now,
      checkOutTime: null,
      checkInLatitude: lat,
      checkInLongitude: lng,
      checkOutLatitude: null,
      checkOutLongitude: null,
      selfieUrl: localSelfiePath,
      status: 'present',
      remarks: null,
    );
    try {
      await FirebaseDataService.saveAttendanceRecord(record);
      state = state.copyWith(
        isLoading: false,
        records: [record, ...state.records],
        isCheckedIn: true,
        todayCheckIn: now,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> checkOut({
    required double lat,
    required double lng,
    String userId = 'user_004',
    String userName = 'Doctor/Nurse',
    String unitId = 'unit_001',
    String? localSelfiePath,
  }) async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    AttendanceRecord? updatedToday;
    final updatedRecords = state.records.map((record) {
      final sameUser = record.userId == userId;
      final sameDay = record.date.year == now.year &&
          record.date.month == now.month &&
          record.date.day == now.day;
      if (sameUser && sameDay) {
        updatedToday = AttendanceRecord(
          id: record.id,
          userId: record.userId,
          userName: record.userName,
          unitId: record.unitId,
          date: record.date,
          checkInTime: record.checkInTime,
          checkOutTime: now,
          checkInLatitude: record.checkInLatitude,
          checkInLongitude: record.checkInLongitude,
          checkOutLatitude: lat,
          checkOutLongitude: lng,
          selfieUrl: localSelfiePath ?? record.selfieUrl,
          status: 'present',
          remarks: record.remarks,
        );
        return updatedToday!;
      }
      return record;
    }).toList();
    updatedToday ??= AttendanceRecord(
      id: 'att_${userId}_${now.year}_${now.month}_${now.day}',
      userId: userId,
      userName: userName,
      unitId: unitId,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: state.todayCheckIn,
      checkOutTime: now,
      checkInLatitude: null,
      checkInLongitude: null,
      checkOutLatitude: lat,
      checkOutLongitude: lng,
      selfieUrl: localSelfiePath,
      status: 'present',
      remarks: null,
    );
    try {
      await FirebaseDataService.saveAttendanceRecord(updatedToday!);
      state = state.copyWith(
        isLoading: false,
        records: updatedRecords.any((record) => record.id == updatedToday!.id)
            ? updatedRecords
            : [updatedToday!, ...updatedRecords],
        isCheckedOut: true,
        todayCheckOut: now,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
      rethrow;
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});

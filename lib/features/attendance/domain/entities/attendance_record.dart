class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String unitId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? selfieUrl;
  final String status; // present, absent, holiday
  final String? remarks;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.unitId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.selfieUrl,
    required this.status,
    this.remarks,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isHoliday => status == 'holiday';

  Duration? get workingHours {
    if (checkInTime == null || checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime!);
  }
}

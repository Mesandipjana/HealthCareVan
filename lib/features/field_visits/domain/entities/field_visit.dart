class FieldVisit {
  final String id;
  final String unitId;
  final String unitName;
  final String officerId;
  final String officerName;
  final String villageName;
  final String district;
  final String state;
  final DateTime startTime;
  final DateTime? endTime;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String remarks;
  final String status;
  final int patientsServed;
  final String? photoUrl;

  const FieldVisit({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.officerId,
    required this.officerName,
    required this.villageName,
    required this.district,
    required this.state,
    required this.startTime,
    this.endTime,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    required this.remarks,
    required this.status,
    required this.patientsServed,
    this.photoUrl,
  });

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}

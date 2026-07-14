class MobileUnit {
  final String id;
  final String name;
  final String unitCode;
  final String status;
  final int teamSize;
  final List<String> teamMembers;
  final String district;
  final String state;
  final int villagesCovered;
  final DateTime lastActivityTime;
  final double? currentLatitude;
  final double? currentLongitude;
  final int patientsServedThisMonth;
  final int visitsThisMonth;
  final DateTime operationalSince;
  final String vehicleNumber;
  final String supervisorId;

  const MobileUnit({
    required this.id,
    required this.name,
    required this.unitCode,
    required this.status,
    required this.teamSize,
    required this.teamMembers,
    required this.district,
    required this.state,
    required this.villagesCovered,
    required this.lastActivityTime,
    this.currentLatitude,
    this.currentLongitude,
    required this.patientsServedThisMonth,
    required this.visitsThisMonth,
    required this.operationalSince,
    required this.vehicleNumber,
    required this.supervisorId,
  });

  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';
  bool get isUnderMaintenance => status == 'maintenance';

  String get location => '$district, $state';
}

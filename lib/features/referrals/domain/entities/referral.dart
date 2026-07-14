class Referral {
  final String id;
  final String unitId;
  final String unitName;
  final String officerId;
  final String officerName;
  final String patientCode;
  final int age;
  final String gender;
  final String reason;
  final String referredFacility;
  final String status; // pending, in_progress, closed
  final String priority; // Low, Medium, High, Critical
  final String followUpNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Referral({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.officerId,
    required this.officerName,
    required this.patientCode,
    required this.age,
    required this.gender,
    required this.reason,
    required this.referredFacility,
    required this.status,
    required this.priority,
    required this.followUpNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isClosed => status == 'closed';

  bool get isHighPriority => priority == 'High' || priority == 'Critical';
}

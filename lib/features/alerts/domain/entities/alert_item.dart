class AlertItem {
  final String id;
  final String type;
  final String severity; // critical, warning, info
  final String title;
  final String message;
  final String? unitId;
  final String? unitName;
  final bool isRead;
  final DateTime createdAt;

  const AlertItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.unitId,
    this.unitName,
    required this.isRead,
    required this.createdAt,
  });

  bool get isCritical => severity == 'critical';
  bool get isWarning => severity == 'warning';
  bool get isInfo => severity == 'info';

  AlertItem copyWith({bool? isRead}) {
    return AlertItem(
      id: id,
      type: type,
      severity: severity,
      title: title,
      message: message,
      unitId: unitId,
      unitName: unitName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

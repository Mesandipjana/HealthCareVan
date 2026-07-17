class PrescribedInventoryItem {
  final String inventoryItemId;
  final String medicineName;
  final String unit;
  final int quantity;

  const PrescribedInventoryItem({
    required this.inventoryItemId,
    required this.medicineName,
    required this.unit,
    required this.quantity,
  });
}

class PatientEncounter {
  final String id;
  final String unitId;
  final String unitName;
  final String visitId;
  final String officerId;
  final String officerName;
  final DateTime visitDate;
  final String villageName;
  final String district;
  final String state;
  final String bloodPressure;
  final String oxygenSaturation;
  final String temperature;
  final String pulseRate;
  final List<String> serviceCategories;
  final List<PrescribedInventoryItem> prescribedInventory;
  final String diagnosisSummary;
  final String prescribedMedicines;
  final String recommendedTests;
  final String remarks;

  const PatientEncounter({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.visitId,
    required this.officerId,
    required this.officerName,
    required this.visitDate,
    required this.villageName,
    required this.district,
    required this.state,
    required this.bloodPressure,
    required this.oxygenSaturation,
    required this.temperature,
    required this.pulseRate,
    required this.serviceCategories,
    required this.prescribedInventory,
    required this.diagnosisSummary,
    required this.prescribedMedicines,
    required this.recommendedTests,
    required this.remarks,
  });
}

class PatientRecord {
  final String id;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PatientEncounter> encounters;

  const PatientRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.encounters,
  });

  PatientEncounter? get latestEncounter =>
      encounters.isEmpty ? null : encounters.first;
}

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/mobile_units/domain/entities/mobile_unit.dart';
import '../../features/field_visits/domain/entities/field_visit.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/service_reporting/domain/entities/service_report.dart';
import '../../features/referrals/domain/entities/referral.dart';
import '../../features/inventory/domain/entities/inventory_item.dart';
import '../../features/alerts/domain/entities/alert_item.dart';
import '../../features/analytics/domain/entities/analytics_data.dart';
import '../constants/app_constants.dart';

class DemoSeedDataService {
  DemoSeedDataService._();

  // ─── USERS ─────────────────────────────────────────────────────────────────

  static final List<AppUser> users = [
    AppUser(
      id: 'user_001',
      name: 'Dr. Ananya Sharma',
      email: 'admin@healthcare.org',
      password: 'Admin@123',
      role: AppConstants.roleAdmin,
      designation: 'Platform Administrator',
      phone: '+91-9876543210',
      unitId: null,
      district: 'All Districts',
      state: 'All States',
      avatarInitials: 'AS',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
      isActive: true,
    ),
    AppUser(
      id: 'user_002',
      name: 'Rajesh Kumar',
      email: 'coordinator@healthcare.org',
      password: 'Coord@123',
      role: AppConstants.roleCoordinator,
      designation: 'Program Coordinator',
      phone: '+91-9876543211',
      unitId: null,
      district: 'Multiple Districts',
      state: 'Rajasthan',
      avatarInitials: 'RK',
      createdAt: DateTime.now().subtract(const Duration(days: 300)),
      lastLogin: DateTime.now().subtract(const Duration(hours: 5)),
      isActive: true,
    ),
    AppUser(
      id: 'user_003',
      name: 'Priya Mehta',
      email: 'supervisor@healthcare.org',
      password: 'Super@123',
      role: AppConstants.roleSupervisor,
      designation: 'Field Supervisor',
      phone: '+91-9876543212',
      unitId: 'unit_001',
      district: 'Jaipur',
      state: 'Rajasthan',
      avatarInitials: 'PM',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
      isActive: true,
    ),
    AppUser(
      id: 'user_004',
      name: 'Dr. Suresh Nair',
      email: 'officer@healthcare.org',
      password: 'Officer@123',
      role: AppConstants.roleOfficer,
      designation: 'Doctor/Nurse',
      phone: '+91-9876543213',
      unitId: 'unit_002',
      district: 'Kozhikode',
      state: 'Kerala',
      avatarInitials: 'SN',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      lastLogin: DateTime.now().subtract(const Duration(minutes: 45)),
      isActive: true,
    ),
    AppUser(
      id: 'user_005',
      name: 'Dr. Kavita Singh',
      email: 'officer2@healthcare.org',
      password: 'Officer@123',
      role: AppConstants.roleOfficer,
      designation: 'Doctor/Nurse',
      phone: '+91-9876543214',
      unitId: 'unit_003',
      district: 'Patna',
      state: 'Bihar',
      avatarInitials: 'KS',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
      isActive: true,
    ),
  ];

  static AppUser? authenticateUser(String email, String password) {
    try {
      return users.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.toLowerCase() &&
            u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── MOBILE UNITS ─────────────────────────────────────────────────────────

  static final List<MobileUnit> mobileUnits = [
    MobileUnit(
      id: 'unit_001',
      name: 'Northern Plains Mobile Unit',
      unitCode: 'MHU-001',
      status: AppConstants.statusActive,
      teamSize: 6,
      teamMembers: ['Dr. Suresh Nair', 'Nurse Lalita Devi', 'Paramedic Mohan'],
      district: 'Jaipur',
      state: 'Rajasthan',
      villagesCovered: 28,
      lastActivityTime: DateTime.now().subtract(const Duration(hours: 2)),
      currentLatitude: 26.9124,
      currentLongitude: 75.7873,
      patientsServedThisMonth: 1240,
      visitsThisMonth: 18,
      operationalSince: DateTime.now().subtract(const Duration(days: 400)),
      vehicleNumber: 'RJ-14-CA-1234',
      supervisorId: 'user_003',
    ),
    MobileUnit(
      id: 'unit_002',
      name: 'Coastal Health Mobile Unit',
      unitCode: 'MHU-002',
      status: AppConstants.statusActive,
      teamSize: 5,
      teamMembers: ['Dr. Asha Pillai', 'Nurse Thomas', 'Paramedic Rajan'],
      district: 'Kozhikode',
      state: 'Kerala',
      villagesCovered: 22,
      lastActivityTime: DateTime.now().subtract(const Duration(hours: 1)),
      currentLatitude: 11.2588,
      currentLongitude: 75.7804,
      patientsServedThisMonth: 980,
      visitsThisMonth: 15,
      operationalSince: DateTime.now().subtract(const Duration(days: 350)),
      vehicleNumber: 'KL-12-AB-5678',
      supervisorId: 'user_003',
    ),
    MobileUnit(
      id: 'unit_003',
      name: 'Eastern Region Health Unit',
      unitCode: 'MHU-003',
      status: AppConstants.statusActive,
      teamSize: 7,
      teamMembers: ['Dr. Arun Kumar', 'Nurse Meena', 'Lab Tech Ravi'],
      district: 'Patna',
      state: 'Bihar',
      villagesCovered: 35,
      lastActivityTime: DateTime.now().subtract(const Duration(hours: 4)),
      currentLatitude: 25.5941,
      currentLongitude: 85.1376,
      patientsServedThisMonth: 1580,
      visitsThisMonth: 22,
      operationalSince: DateTime.now().subtract(const Duration(days: 500)),
      vehicleNumber: 'BR-01-CD-9012',
      supervisorId: 'user_003',
    ),
    MobileUnit(
      id: 'unit_004',
      name: 'Deccan Plateau Health Unit',
      unitCode: 'MHU-004',
      status: AppConstants.statusActive,
      teamSize: 5,
      teamMembers: ['Dr. Rekha Rao', 'Nurse Anita', 'Paramedic Shiva'],
      district: 'Mysuru',
      state: 'Karnataka',
      villagesCovered: 19,
      lastActivityTime: DateTime.now().subtract(const Duration(hours: 6)),
      currentLatitude: 12.2958,
      currentLongitude: 76.6394,
      patientsServedThisMonth: 820,
      visitsThisMonth: 12,
      operationalSince: DateTime.now().subtract(const Duration(days: 280)),
      vehicleNumber: 'KA-09-EF-3456',
      supervisorId: 'user_003',
    ),
    MobileUnit(
      id: 'unit_005',
      name: 'Tribal Outreach Mobile Unit',
      unitCode: 'MHU-005',
      status: AppConstants.statusActive,
      teamSize: 8,
      teamMembers: ['Dr. Pradeep Sahu', 'Nurse Sunita', 'CHW Ramesh'],
      district: 'Raipur',
      state: 'Chhattisgarh',
      villagesCovered: 42,
      lastActivityTime: DateTime.now().subtract(const Duration(hours: 3)),
      currentLatitude: 21.2514,
      currentLongitude: 81.6296,
      patientsServedThisMonth: 2100,
      visitsThisMonth: 28,
      operationalSince: DateTime.now().subtract(const Duration(days: 600)),
      vehicleNumber: 'CG-04-GH-7890',
      supervisorId: 'user_003',
    ),
    MobileUnit(
      id: 'unit_006',
      name: 'Hill District Mobile Unit',
      unitCode: 'MHU-006',
      status: AppConstants.statusActive,
      teamSize: 6,
      teamMembers: ['Dr. Sonam Dorji', 'Nurse Pema', 'Paramedic Tenzin'],
      district: 'Darjeeling',
      state: 'West Bengal',
      villagesCovered: 16,
      lastActivityTime: DateTime.now().subtract(const Duration(hours: 8)),
      currentLatitude: 27.0360,
      currentLongitude: 88.2627,
      patientsServedThisMonth: 640,
      visitsThisMonth: 10,
      operationalSince: DateTime.now().subtract(const Duration(days: 220)),
      vehicleNumber: 'WB-74-IJ-1234',
      supervisorId: 'user_003',
    ),
    MobileUnit(
      id: 'unit_007',
      name: 'Desert Health Mobile Unit',
      unitCode: 'MHU-007',
      status: AppConstants.statusMaintenance,
      teamSize: 5,
      teamMembers: ['Dr. Fatima Khan', 'Nurse Hamida', 'Paramedic Salim'],
      district: 'Barmer',
      state: 'Rajasthan',
      villagesCovered: 24,
      lastActivityTime: DateTime.now().subtract(const Duration(days: 3)),
      currentLatitude: 25.7521,
      currentLongitude: 71.3967,
      patientsServedThisMonth: 0,
      visitsThisMonth: 0,
      operationalSince: DateTime.now().subtract(const Duration(days: 450)),
      vehicleNumber: 'RJ-04-KL-5678',
      supervisorId: 'user_003',
    ),
    MobileUnit(
      id: 'unit_008',
      name: 'Mountain Health Access Unit',
      unitCode: 'MHU-008',
      status: AppConstants.statusInactive,
      teamSize: 4,
      teamMembers: ['Dr. Vikram Thakur', 'Nurse Geeta'],
      district: 'Shimla',
      state: 'Himachal Pradesh',
      villagesCovered: 12,
      lastActivityTime: DateTime.now().subtract(const Duration(days: 7)),
      currentLatitude: 31.1048,
      currentLongitude: 77.1734,
      patientsServedThisMonth: 180,
      visitsThisMonth: 3,
      operationalSince: DateTime.now().subtract(const Duration(days: 180)),
      vehicleNumber: 'HP-01-MN-9012',
      supervisorId: 'user_003',
    ),
  ];

  // ─── FIELD VISITS ────────────────────────────────────────────────────────

  static List<FieldVisit> fieldVisits = [
    FieldVisit(
      id: 'visit_001',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      officerId: 'user_004',
      officerName: 'Dr. Suresh Nair',
      villageName: 'Ramgarh Village',
      district: 'Jaipur',
      startTime: DateTime.now().subtract(const Duration(hours: 5)),
      endTime: DateTime.now().subtract(const Duration(hours: 2)),
      startLatitude: 26.9124,
      startLongitude: 75.7873,
      endLatitude: 26.9130,
      endLongitude: 75.7880,
      remarks: 'Camp conducted successfully. Good community participation.',
      status: AppConstants.visitCompleted,
      patientsServed: 87,
      photoUrl: null,
    ),
    FieldVisit(
      id: 'visit_002',
      unitId: 'unit_002',
      unitName: 'Coastal Health Mobile Unit',
      officerId: 'user_004',
      officerName: 'Dr. Asha Pillai',
      villageName: 'Beachside Colony',
      district: 'Kozhikode',
      startTime: DateTime.now().subtract(const Duration(hours: 8)),
      endTime: DateTime.now().subtract(const Duration(hours: 5)),
      startLatitude: 11.2588,
      startLongitude: 75.7804,
      endLatitude: 11.2595,
      endLongitude: 75.7810,
      remarks: 'Vaccination drive completed. 45 children vaccinated.',
      status: AppConstants.visitCompleted,
      patientsServed: 124,
      photoUrl: null,
    ),
    FieldVisit(
      id: 'visit_003',
      unitId: 'unit_003',
      unitName: 'Eastern Region Health Unit',
      officerId: 'user_005',
      officerName: 'Dr. Kavita Singh',
      villageName: 'Harpur Gram',
      district: 'Patna',
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      endTime: null,
      startLatitude: 25.5941,
      startLongitude: 85.1376,
      endLatitude: null,
      endLongitude: null,
      remarks: 'Camp in progress.',
      status: AppConstants.visitInProgress,
      patientsServed: 45,
      photoUrl: null,
    ),
    FieldVisit(
      id: 'visit_004',
      unitId: 'unit_005',
      unitName: 'Tribal Outreach Mobile Unit',
      officerId: 'user_004',
      officerName: 'Dr. Pradeep Sahu',
      villageName: 'Adivasi Tola',
      district: 'Raipur',
      startTime: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      endTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      startLatitude: 21.2514,
      startLongitude: 81.6296,
      endLatitude: 21.2520,
      endLongitude: 81.6302,
      remarks: 'Tribal health camp. Focused on malaria screening.',
      status: AppConstants.visitCompleted,
      patientsServed: 203,
      photoUrl: null,
    ),
    FieldVisit(
      id: 'visit_005',
      unitId: 'unit_004',
      unitName: 'Deccan Plateau Health Unit',
      officerId: 'user_004',
      officerName: 'Dr. Rekha Rao',
      villageName: 'Chamundi Hills Settlement',
      district: 'Mysuru',
      startTime: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      startLatitude: 12.2958,
      startLongitude: 76.6394,
      endLatitude: 12.2965,
      endLongitude: 76.6400,
      remarks: 'Diabetes and hypertension screening camp.',
      status: AppConstants.visitCompleted,
      patientsServed: 76,
      photoUrl: null,
    ),
  ];

  // ─── ATTENDANCE ──────────────────────────────────────────────────────────

  static List<AttendanceRecord> attendanceRecords = List.generate(30, (i) {
    final date = DateTime.now().subtract(Duration(days: 29 - i));
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isPresent = !isWeekend && i % 8 != 7;
    return AttendanceRecord(
      id: 'att_${i.toString().padLeft(3, '0')}',
      userId: 'user_004',
      userName: 'Dr. Suresh Nair',
      unitId: 'unit_001',
      date: date,
      checkInTime: isPresent
          ? DateTime(date.year, date.month, date.day, 8, 30 + i % 15)
          : null,
      checkOutTime: isPresent
          ? DateTime(date.year, date.month, date.day, 17, 15 + i % 30)
          : null,
      checkInLatitude: isPresent ? 26.9124 + (i * 0.0001) : null,
      checkInLongitude: isPresent ? 75.7873 + (i * 0.0001) : null,
      checkOutLatitude: isPresent ? 26.9130 + (i * 0.0001) : null,
      checkOutLongitude: isPresent ? 75.7880 + (i * 0.0001) : null,
      selfieUrl: null,
      status: isWeekend
          ? 'holiday'
          : isPresent
              ? 'present'
              : 'absent',
      remarks: isPresent ? null : (isWeekend ? 'Weekend' : 'Absent'),
    );
  });

  // ─── SERVICE REPORTS ────────────────────────────────────────────────────

  static final List<ServiceReport> serviceReports = List.generate(12, (i) {
    final date = DateTime.now().subtract(Duration(days: i * 5));
    return ServiceReport(
      id: 'report_${i.toString().padLeft(3, '0')}',
      unitId: 'unit_00${(i % 5) + 1}',
      unitName: _unitNames[i % 5],
      officerId: 'user_004',
      officerName: 'Dr. Suresh Nair',
      campDate: date,
      villageName: _villageNames[i % _villageNames.length],
      district: _districts[i % _districts.length],
      state: _states[i % _states.length],
      // Population served
      totalMale: 40 + i * 8,
      totalFemale: 50 + i * 10,
      totalChildren: 25 + i * 5,
      totalSeniorCitizens: 15 + i * 3,
      // Services
      generalConsultations: 60 + i * 12,
      diabetesScreening: 20 + i * 4,
      hypertensionScreening: 18 + i * 3,
      maternalHealthServices: 10 + i * 2,
      childHealthServices: 22 + i * 4,
      vaccinationSupport: 15 + i * 3,
      referralCases: 5 + i,
      remarks:
          'Camp conducted successfully at ${_villageNames[i % _villageNames.length]}.',
      submittedAt: date.add(const Duration(hours: 6)),
      isVerified: i > 3,
      verifiedBy: i > 3 ? 'user_003' : null,
    );
  });

  // ─── REFERRALS ───────────────────────────────────────────────────────────

  static final List<Referral> referrals = [
    Referral(
      id: 'ref_001',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      officerId: 'user_004',
      officerName: 'Dr. Suresh Nair',
      patientCode: 'PAT-2024-001',
      age: 58,
      gender: 'Male',
      reason: 'Suspected Diabetes Mellitus Type 2 — Fasting glucose 286 mg/dL',
      referredFacility: 'District Hospital, Jaipur',
      status: AppConstants.referralClosed,
      priority: 'High',
      followUpNotes:
          'Patient admitted, now on insulin therapy. Follow-up scheduled.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Referral(
      id: 'ref_002',
      unitId: 'unit_002',
      unitName: 'Coastal Health Mobile Unit',
      officerId: 'user_004',
      officerName: 'Dr. Asha Pillai',
      patientCode: 'PAT-2024-002',
      age: 34,
      gender: 'Female',
      reason: 'High-risk pregnancy — Gestational hypertension',
      referredFacility: 'Maternity Hospital, Kozhikode',
      status: AppConstants.referralInProgress,
      priority: 'Critical',
      followUpNotes: 'Patient under observation. Weekly BP monitoring.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      resolvedAt: null,
    ),
    Referral(
      id: 'ref_003',
      unitId: 'unit_003',
      unitName: 'Eastern Region Health Unit',
      officerId: 'user_005',
      officerName: 'Dr. Kavita Singh',
      patientCode: 'PAT-2024-003',
      age: 7,
      gender: 'Male',
      reason: 'Severe acute malnutrition (SAM) — MUAC < 11.5 cm',
      referredFacility: 'Nutritional Rehabilitation Centre, Patna',
      status: AppConstants.referralPending,
      priority: 'High',
      followUpNotes: '',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      resolvedAt: null,
    ),
    Referral(
      id: 'ref_004',
      unitId: 'unit_005',
      unitName: 'Tribal Outreach Mobile Unit',
      officerId: 'user_004',
      officerName: 'Dr. Pradeep Sahu',
      patientCode: 'PAT-2024-004',
      age: 45,
      gender: 'Female',
      reason: 'Breast lump — Requires further investigation',
      referredFacility: 'Cancer Screening Centre, Raipur',
      status: AppConstants.referralPending,
      priority: 'Medium',
      followUpNotes: '',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      resolvedAt: null,
    ),
    Referral(
      id: 'ref_005',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      officerId: 'user_004',
      officerName: 'Dr. Suresh Nair',
      patientCode: 'PAT-2024-005',
      age: 72,
      gender: 'Male',
      reason: 'Uncontrolled hypertension — BP 190/110 mmHg',
      referredFacility: 'Cardiology Unit, SMS Hospital',
      status: AppConstants.referralClosed,
      priority: 'High',
      followUpNotes: 'Medication adjusted. BP now controlled at 130/85.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Referral(
      id: 'ref_006',
      unitId: 'unit_004',
      unitName: 'Deccan Plateau Health Unit',
      officerId: 'user_004',
      officerName: 'Dr. Rekha Rao',
      patientCode: 'PAT-2024-006',
      age: 23,
      gender: 'Female',
      reason: 'Anaemia in pregnancy — Hb 7.2 g/dL',
      referredFacility: 'District Hospital, Mysuru',
      status: AppConstants.referralInProgress,
      priority: 'Medium',
      followUpNotes: 'On IV iron therapy. Follow-up in 2 weeks.',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      resolvedAt: null,
    ),
  ];

  // ─── INVENTORY ──────────────────────────────────────────────────────────

  static final List<InventoryItem> inventoryItems = [
    _inv(
        'inv_001', 'Paracetamol 500mg', 'Analgesics', 500, 320, 'Tablets', 100),
    _inv('inv_002', 'Amoxicillin 250mg', 'Antibiotics', 200, 145, 'Capsules',
        50),
    _inv('inv_003', 'ORS Sachets', 'Rehydration', 300, 85, 'Sachets', 75),
    _inv(
        'inv_004', 'Metformin 500mg', 'Antidiabetics', 150, 118, 'Tablets', 40),
    _inv('inv_005', 'Amlodipine 5mg', 'Antihypertensives', 200, 172, 'Tablets',
        50),
    _inv('inv_006', 'Iron Folic Acid', 'Nutritional Supplements', 400, 58,
        'Tablets', 100),
    _inv('inv_007', 'Albendazole 400mg', 'Anthelmintics', 250, 210, 'Tablets',
        60),
    _inv('inv_008', 'Chlorine Tablets', 'Water Purification', 500, 320,
        'Tablets', 100),
    _inv('inv_009', 'Zinc Sulphate', 'Nutritional Supplements', 180, 22,
        'Tablets', 50),
    _inv('inv_010', 'DPT Vaccine', 'Vaccines', 100, 68, 'Vials', 25),
    _inv('inv_011', 'Measles Vaccine', 'Vaccines', 80, 15, 'Vials', 25),
    _inv('inv_012', 'Gloves (Disposable)', 'PPE', 1000, 420, 'Pairs', 200),
    _inv('inv_013', 'Surgical Masks', 'PPE', 500, 380, 'Pieces', 100),
    _inv('inv_014', 'Glucometer Strips', 'Diagnostics', 200, 182, 'Strips', 50),
    _inv('inv_015', 'BP Cuffs', 'Equipment', 20, 2, 'Units', 5),
    _inv('inv_016', 'Thermometers', 'Equipment', 30, 24, 'Units', 8),
    _inv('inv_017', 'Vitamin A Capsules', 'Nutritional Supplements', 300, 265,
        'Capsules', 80),
    _inv('inv_018', 'Cotrimoxazole', 'Antibiotics', 160, 130, 'Tablets', 40),
    _inv('inv_019', 'Salbutamol Inhaler', 'Respiratory', 40, 8, 'Inhalers', 12),
    _inv('inv_020', 'Wound Dressing Kit', 'First Aid', 60, 42, 'Kits', 15),
  ];

  static InventoryItem _inv(
    String id,
    String name,
    String category,
    int initial,
    int consumed,
    String unit,
    int threshold,
  ) {
    final remaining = initial - consumed;
    return InventoryItem(
      id: id,
      medicineName: name,
      category: category,
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      availableStock: initial,
      consumed: consumed,
      remaining: remaining,
      unit: unit,
      lowStockThreshold: threshold,
      isLowStock: remaining <= threshold,
      lastUpdated: DateTime.now().subtract(Duration(hours: consumed % 48)),
    );
  }

  // ─── ALERTS ──────────────────────────────────────────────────────────────

  static final List<AlertItem> alerts = [
    AlertItem(
      id: 'alert_001',
      type: AppConstants.alertLowInventory,
      severity: AppConstants.severityCritical,
      title: 'Critical: BP Cuffs Running Out',
      message:
          'Unit MHU-001 has only 2 BP cuffs remaining (threshold: 5). Immediate resupply needed.',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AlertItem(
      id: 'alert_002',
      type: AppConstants.alertLowInventory,
      severity: AppConstants.severityCritical,
      title: 'Critical: Measles Vaccine Low Stock',
      message:
          'Unit MHU-001 has only 15 Measles vaccine vials (threshold: 25). Reorder immediately.',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AlertItem(
      id: 'alert_003',
      type: AppConstants.alertMissingAttendance,
      severity: AppConstants.severityWarning,
      title: 'Attendance Not Marked',
      message:
          '3 staff members in Unit MHU-006 have not marked attendance today.',
      unitId: 'unit_006',
      unitName: 'Hill District Mobile Unit',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AlertItem(
      id: 'alert_004',
      type: AppConstants.alertUnitInactivity,
      severity: AppConstants.severityWarning,
      title: 'Unit Inactivity Detected',
      message: 'Unit MHU-008 has had no field activity for 7 days.',
      unitId: 'unit_008',
      unitName: 'Mountain Health Access Unit',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AlertItem(
      id: 'alert_005',
      type: AppConstants.alertIncompleteReport,
      severity: AppConstants.severityWarning,
      title: 'Service Report Overdue',
      message: 'Unit MHU-004 has not submitted a service report in 5 days.',
      unitId: 'unit_004',
      unitName: 'Deccan Plateau Health Unit',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    AlertItem(
      id: 'alert_006',
      type: AppConstants.alertMissedVisit,
      severity: AppConstants.severityInfo,
      title: 'Scheduled Visit Missed',
      message:
          'Unit MHU-007 missed the scheduled visit to Barmer North Village.',
      unitId: 'unit_007',
      unitName: 'Desert Health Mobile Unit',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AlertItem(
      id: 'alert_007',
      type: AppConstants.alertLowInventory,
      severity: AppConstants.severityWarning,
      title: 'Low Stock: Iron Folic Acid',
      message:
          'Iron Folic Acid tablets running low in Unit MHU-001 (58 remaining, threshold: 100).',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    AlertItem(
      id: 'alert_008',
      type: AppConstants.alertLowInventory,
      severity: AppConstants.severityWarning,
      title: 'Low Stock: Zinc Sulphate',
      message:
          'Zinc Sulphate stock critically low in Unit MHU-001 (22 remaining, threshold: 50).',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
    AlertItem(
      id: 'alert_009',
      type: AppConstants.alertLowInventory,
      severity: AppConstants.severityWarning,
      title: 'Low Stock: Salbutamol Inhaler',
      message: 'Only 8 Salbutamol inhalers remain in MHU-001 (threshold: 12).',
      unitId: 'unit_001',
      unitName: 'Northern Plains Mobile Unit',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    AlertItem(
      id: 'alert_010',
      type: AppConstants.alertMissingAttendance,
      severity: AppConstants.severityInfo,
      title: 'Partial Attendance',
      message:
          '1 officer in Unit MHU-003 has checked in but not checked out after 10 hours.',
      unitId: 'unit_003',
      unitName: 'Eastern Region Health Unit',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
  ];

  // ─── ANALYTICS DATA ──────────────────────────────────────────────────────

  static AnalyticsData get analyticsData {
    return AnalyticsData(
      monthlyServiceTrends: _generateMonthlyTrends(),
      diseaseDistribution: _generateDiseaseDistribution(),
      regionPerformance: _generateRegionPerformance(),
      unitPerformance: _generateUnitPerformance(),
      referralAnalytics: _generateReferralAnalytics(),
      coverageTrends: _generateCoverageTrends(),
    );
  }

  static List<MonthlyTrend> _generateMonthlyTrends() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final values = [
      1200,
      1450,
      1380,
      1680,
      2100,
      1950,
      2340,
      2180,
      2560,
      2430,
      2780,
      3100
    ];
    return List.generate(
        12, (i) => MonthlyTrend(month: months[i], patientsServed: values[i]));
  }

  static List<DiseaseData> _generateDiseaseDistribution() {
    return [
      const DiseaseData(name: 'Hypertension', count: 2840, percentage: 28.4),
      const DiseaseData(name: 'Diabetes', count: 2100, percentage: 21.0),
      const DiseaseData(name: 'Respiratory', count: 1560, percentage: 15.6),
      const DiseaseData(name: 'Maternal Health', count: 1240, percentage: 12.4),
      const DiseaseData(name: 'Malnutrition', count: 980, percentage: 9.8),
      const DiseaseData(name: 'Skin Conditions', count: 720, percentage: 7.2),
      const DiseaseData(name: 'Others', count: 560, percentage: 5.6),
    ];
  }

  static List<RegionPerformance> _generateRegionPerformance() {
    return [
      const RegionPerformance(
          region: 'Chhattisgarh',
          units: 1,
          patients: 2100,
          villages: 42,
          visits: 28,
          score: 94),
      const RegionPerformance(
          region: 'Bihar',
          units: 1,
          patients: 1580,
          villages: 35,
          visits: 22,
          score: 88),
      const RegionPerformance(
          region: 'Rajasthan',
          units: 2,
          patients: 1240,
          villages: 28,
          visits: 18,
          score: 76),
      const RegionPerformance(
          region: 'Kerala',
          units: 1,
          patients: 980,
          villages: 22,
          visits: 15,
          score: 82),
      const RegionPerformance(
          region: 'Karnataka',
          units: 1,
          patients: 820,
          villages: 19,
          visits: 12,
          score: 71),
      const RegionPerformance(
          region: 'West Bengal',
          units: 1,
          patients: 640,
          villages: 16,
          visits: 10,
          score: 68),
      const RegionPerformance(
          region: 'Himachal Pradesh',
          units: 1,
          patients: 180,
          villages: 12,
          visits: 3,
          score: 42),
    ];
  }

  static List<UnitPerformance> _generateUnitPerformance() {
    return mobileUnits
        .map((u) => UnitPerformance(
              unitId: u.id,
              unitCode: u.unitCode,
              unitName: u.name,
              patientsServed: u.patientsServedThisMonth,
              visits: u.visitsThisMonth,
              villages: u.villagesCovered,
              status: u.status,
              score: u.patientsServedThisMonth > 0
                  ? (u.patientsServedThisMonth / 25).clamp(0, 100).toInt()
                  : 0,
            ))
        .toList()
      ..sort((a, b) => b.patientsServed.compareTo(a.patientsServed));
  }

  static List<ReferralCount> _generateReferralAnalytics() {
    return [
      const ReferralCount(status: 'Closed', count: 2, color: 0xFF10B981),
      const ReferralCount(status: 'In Progress', count: 2, color: 0xFFF59E0B),
      const ReferralCount(status: 'Pending', count: 2, color: 0xFF3B82F6),
    ];
  }

  static List<CoverageTrend> _generateCoverageTrends() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final villages = [85, 92, 98, 112, 128, 135, 148, 152, 158, 162, 170, 174];
    return List.generate(12,
        (i) => CoverageTrend(month: months[i], villagesCovered: villages[i]));
  }

  // ─── DASHBOARD SUMMARY ───────────────────────────────────────────────────

  static Map<String, dynamic> get dashboardSummary {
    final activeUnits =
        mobileUnits.where((u) => u.status == AppConstants.statusActive).length;
    final totalPatients =
        mobileUnits.fold<int>(0, (sum, u) => sum + u.patientsServedThisMonth);
    final totalVillages =
        mobileUnits.fold<int>(0, (sum, u) => sum + u.villagesCovered);
    final pendingReferrals =
        referrals.where((r) => r.status == AppConstants.referralPending).length;
    final unreadAlerts = alerts.where((a) => !a.isRead).length;

    return {
      'totalUnits': mobileUnits.length,
      'activeUnits': activeUnits,
      'unitsActiveToday': 5,
      'villagesCovered': totalVillages,
      'communitiesReached': 42,
      'patientsServed': totalPatients,
      'referralCases': referrals.length,
      'inventoryAlerts': inventoryItems.where((i) => i.isLowStock).length,
      'activeAlerts': unreadAlerts,
      'pendingReferrals': pendingReferrals,
    };
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  static const List<String> _unitNames = [
    'Northern Plains Mobile Unit',
    'Coastal Health Mobile Unit',
    'Eastern Region Health Unit',
    'Deccan Plateau Health Unit',
    'Tribal Outreach Mobile Unit',
  ];

  static const List<String> _villageNames = [
    'Ramgarh Village',
    'Beachside Colony',
    'Harpur Gram',
    'Adivasi Tola',
    'Chamundi Hills Settlement',
    'New Colony',
    'West Block',
    'Santoshi Nagar',
    'Green Valley',
    'River Bank Camp',
  ];

  static const List<String> _districts = [
    'Jaipur',
    'Kozhikode',
    'Patna',
    'Mysuru',
    'Raipur',
    'Darjeeling',
    'Barmer',
    'Shimla',
  ];

  static const List<String> _states = [
    'Rajasthan',
    'Kerala',
    'Bihar',
    'Karnataka',
    'Chhattisgarh',
    'West Bengal',
    'Himachal Pradesh',
  ];
}

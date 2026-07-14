class AppConstants {
  AppConstants._();

  // Firestore collections
  static const String usersCollection = 'users';
  static const String mobileUnitsCollection = 'mobile_units';
  static const String fieldVisitsCollection = 'field_visits';
  static const String attendanceCollection = 'attendance';
  static const String serviceReportsCollection = 'service_reports';
  static const String inventoryCollection = 'inventory';
  static const String referralsCollection = 'referrals';
  static const String alertsCollection = 'alerts';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleCoordinator = 'coordinator';
  static const String roleSupervisor = 'supervisor';
  static const String roleOfficer = 'officer';

  static const Map<String, String> roleLabels = {
    roleAdmin: 'Platform Administrator',
    roleCoordinator: 'Program Coordinator',
    roleOfficer: 'Doctor/Nurse',
  };

  // Unit Statuses
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusMaintenance = 'maintenance';

  // Visit Statuses
  static const String visitInProgress = 'in_progress';
  static const String visitCompleted = 'completed';

  // Referral Statuses
  static const String referralPending = 'pending';
  static const String referralInProgress = 'in_progress';
  static const String referralClosed = 'closed';

  // Alert Types
  static const String alertMissingAttendance = 'missing_attendance';
  static const String alertLowInventory = 'low_inventory';
  static const String alertMissedVisit = 'missed_visit';
  static const String alertUnitInactivity = 'unit_inactivity';
  static const String alertIncompleteReport = 'incomplete_report';

  // Alert Severities
  static const String severityCritical = 'critical';
  static const String severityWarning = 'warning';
  static const String severityInfo = 'info';

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1280;

  // Sidebar
  static const double sidebarWidth = 240;
  static const double sidebarCollapsedWidth = 70;

  // Layout
  static const double contentPadding = 24;
  static const double cardRadius = 12;
  static const double cardElevation = 0;

  // Low stock threshold percentage
  static const double lowStockThreshold = 20;
}

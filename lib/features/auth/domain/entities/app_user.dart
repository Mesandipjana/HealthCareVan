class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String designation;
  final String phone;
  final String? unitId;
  final String district;
  final String state;
  final String avatarInitials;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.designation,
    required this.phone,
    this.unitId,
    required this.district,
    required this.state,
    required this.avatarInitials,
    required this.createdAt,
    this.lastLogin,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';
  bool get isCoordinator => role == 'coordinator';
  bool get isSupervisor => role == 'supervisor';
  bool get isOfficer => role == 'officer';

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Platform Administrator';
      case 'coordinator':
        return 'Program Coordinator';
      case 'supervisor':
        return 'Field Supervisor';
      case 'officer':
        return 'Doctor/Nurse';
      default:
        return role;
    }
  }
}

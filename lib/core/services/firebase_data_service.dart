import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/alerts/domain/entities/alert_item.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/field_visits/domain/entities/field_visit.dart';
import '../../features/inventory/domain/entities/inventory_item.dart';
import '../../features/mobile_units/domain/entities/mobile_unit.dart';
import '../../features/referrals/domain/entities/referral.dart';
import '../../features/service_reporting/domain/entities/service_report.dart';
import '../constants/firebase_constants.dart';
import '../services/demo_seed_data_service.dart';

class FirebaseDataService {
  FirebaseDataService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: FirebaseConstants.firestoreDatabaseId,
      );

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseStorage get _storage => FirebaseStorage.instance;
  static const Duration _firebaseTimeout = Duration(seconds: 15);

  static User? get firebaseUser => _auth.currentUser;

  static String get debugTargetSummary {
    final app = Firebase.app();
    final user = _auth.currentUser;
    return 'project=${app.options.projectId}, '
        'appId=${app.options.appId}, '
        'database=${FirebaseConstants.firestoreDatabaseId}, '
        'authUid=${user?.uid ?? 'none'}, '
        'authEmail=${user?.email ?? 'none'}';
  }

  static Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final cred = await _withTimeout(
        _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
      return _ensureProfile(cred.user!, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        rethrow;
      }
      rethrow;
    }
  }

  static Future<AppUser> signInWithDemoAccount(
      String email, String password) async {
    final demo = DemoSeedDataService.users.cast<AppUser?>().firstWhere(
          (user) =>
              user?.email.toLowerCase() == email.toLowerCase() &&
              user?.password == password,
          orElse: () => null,
        );
    if (demo == null) {
      throw FirebaseAuthException(
        code: 'invalid-demo-account',
        message: 'This is not a configured demo account.',
      );
    }

    UserCredential cred;
    try {
      cred = await _withTimeout(
        _auth.signInWithEmailAndPassword(email: email, password: password),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found' &&
          e.code != 'invalid-credential' &&
          e.code != 'invalid-login-credentials') {
        rethrow;
      }
      try {
        cred = await _withTimeout(
          _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        );
      } on FirebaseAuthException {
        rethrow;
      }
    }

    await _withTimeout(cred.user!.updateDisplayName(demo.name));
    final profile = AppUser(
      id: cred.user!.uid,
      name: demo.name,
      email: demo.email,
      password: '',
      role: demo.role,
      designation: demo.designation,
      phone: demo.phone,
      unitId: demo.unitId,
      district: demo.district,
      state: demo.state,
      avatarInitials: demo.avatarInitials,
      createdAt: demo.createdAt,
      lastLogin: DateTime.now(),
      isActive: true,
    );
    await _safeWrite(
      _db.collection('users').doc(profile.id).set(_userToMap(profile)),
    );
    return profile;
  }

  static Future<AppUser> createUserWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
    required String designation,
    required String phone,
    String? unitId,
    required String district,
    required String state,
  }) async {
    final cred = await _withTimeout(
      _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    await _withTimeout(cred.user!.updateDisplayName(name));
    final profile = AppUser(
      id: cred.user!.uid,
      name: name,
      email: email,
      password: '',
      role: role,
      designation: designation,
      phone: phone,
      unitId: unitId?.trim().isEmpty ?? true ? null : unitId!.trim(),
      district: district,
      state: state,
      avatarInitials: _initials(name),
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
    );
    await _safeWrite(
      _db.collection('users').doc(profile.id).set(_userToMap(profile)),
    );
    return profile;
  }

  static Future<AppUser> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});
      await _auth.signOut();
      final cred = await _withTimeout(_auth.signInWithPopup(provider));
      return _ensureProfile(cred.user!);
    }

    final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _withTimeout(_auth.signInWithCredential(credential));
    return _ensureProfile(cred.user!);
  }

  static Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _withTimeout(_auth.signOut());
  }

  static Future<AppUser> updateCurrentProfile({
    required String name,
    required String designation,
    required String phone,
    String? unitId,
    required String district,
    required String state,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'No signed-in user is available.',
      );
    }
    final existing = await _ensureProfile(currentUser);
    final updated = AppUser(
      id: existing.id,
      name: name,
      email: existing.email,
      password: existing.password,
      role: existing.role,
      designation: designation,
      phone: phone,
      unitId: unitId?.trim().isEmpty ?? true ? null : unitId!.trim(),
      district: district,
      state: state,
      avatarInitials: _initials(name),
      createdAt: existing.createdAt,
      lastLogin: DateTime.now(),
      isActive: existing.isActive,
    );
    await _withTimeout(currentUser.updateDisplayName(name));
    await _safeWrite(
      _db.collection('users').doc(updated.id).set(_userToMap(updated)),
    );
    return updated;
  }

  static Future<void> clearSavedSession() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
      await _auth.signOut();
    } catch (_) {
      return;
    }
  }

  static Future<AppUser?> currentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _ensureProfile(user);
  }

  static Future<List<AppUser>> getUsers() async {
    return _getList('users', _userFromMap);
  }

  static Future<void> assignUserToUnit({
    required String userId,
    required String unitId,
  }) {
    return _safeWrite(
      _db.collection('users').doc(userId).update({'unitId': unitId}),
    );
  }

  static Future<AppUser> _ensureProfile(User user,
      {String password = ''}) async {
    try {
      final doc =
          await _withTimeout(_db.collection('users').doc(user.uid).get());
      if (doc.exists) {
        await _safeWrite(
          _db.collection('users').doc(user.uid).update({
            'lastLogin': Timestamp.fromDate(DateTime.now()),
          }),
        );
        return _userFromMap(doc.id, doc.data()!);
      }
    } catch (_) {}

    final profile = AppUser(
      id: user.uid,
      name:
          user.displayName ?? user.email?.split('@').first ?? 'Healthcare User',
      email: user.email ?? '',
      password: password,
      role: 'officer',
      designation: 'Doctor/Nurse',
      phone: user.phoneNumber ?? '',
      unitId: null,
      district: '',
      state: '',
      avatarInitials: _initials(user.displayName ?? user.email ?? 'HU'),
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
    );
    await _safeWrite(
        _db.collection('users').doc(user.uid).set(_userToMap(profile)));
    return profile;
  }

  static Future<void> resetDemoData() async {
    await _withTimeout(_writeSeedData());
  }

  static Future<void> clearDemoData() async {
    await _withTimeout(_deleteSeedData());
  }

  static Future<void> _writeSeedData() async {
    final metaRef = _db.collection('_metadata').doc('seed');
    final batch = _db.batch();
    for (final user in DemoSeedDataService.users) {
      batch.set(_db.collection('users').doc(user.id), _userToMap(user));
    }
    for (final unit in DemoSeedDataService.mobileUnits) {
      batch.set(
          _db.collection('mobile_units').doc(unit.id), _mobileUnitToMap(unit));
    }
    for (final visit in DemoSeedDataService.fieldVisits) {
      batch.set(_db.collection('field_visits').doc(visit.id),
          _fieldVisitToMap(visit));
    }
    for (final record in DemoSeedDataService.attendanceRecords) {
      batch.set(_db.collection('attendance').doc(record.id),
          _attendanceToMap(record));
    }
    for (final report in DemoSeedDataService.serviceReports) {
      batch.set(_db.collection('service_reports').doc(report.id),
          _serviceReportToMap(report));
    }
    for (final item in DemoSeedDataService.inventoryItems) {
      batch.set(
          _db.collection('inventory').doc(item.id), _inventoryToMap(item));
    }
    for (final referral in DemoSeedDataService.referrals) {
      batch.set(_db.collection('referrals').doc(referral.id),
          _referralToMap(referral));
    }
    for (final alert in DemoSeedDataService.alerts) {
      batch.set(_db.collection('alerts').doc(alert.id), _alertToMap(alert));
    }
    batch.set(metaRef, {
      'completed': true,
      'seededAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<void> _deleteSeedData() async {
    final batch = _db.batch();
    for (final user in DemoSeedDataService.users) {
      batch.delete(_db.collection('users').doc(user.id));
    }
    for (final unit in DemoSeedDataService.mobileUnits) {
      batch.delete(_db.collection('mobile_units').doc(unit.id));
    }
    for (final visit in DemoSeedDataService.fieldVisits) {
      batch.delete(_db.collection('field_visits').doc(visit.id));
    }
    for (final record in DemoSeedDataService.attendanceRecords) {
      batch.delete(_db.collection('attendance').doc(record.id));
    }
    for (final report in DemoSeedDataService.serviceReports) {
      batch.delete(_db.collection('service_reports').doc(report.id));
    }
    for (final item in DemoSeedDataService.inventoryItems) {
      batch.delete(_db.collection('inventory').doc(item.id));
    }
    for (final referral in DemoSeedDataService.referrals) {
      batch.delete(_db.collection('referrals').doc(referral.id));
    }
    for (final alert in DemoSeedDataService.alerts) {
      batch.delete(_db.collection('alerts').doc(alert.id));
    }
    batch.delete(_db.collection('_metadata').doc('seed'));
    await batch.commit();
  }

  static Future<List<MobileUnit>> getMobileUnits() async {
    return _getList('mobile_units', _mobileUnitFromMap);
  }

  static Future<void> saveMobileUnit(MobileUnit unit) {
    return _safeWrite(
      _db.collection('mobile_units').doc(unit.id).set(_mobileUnitToMap(unit)),
    );
  }

  static Future<List<InventoryItem>> getInventoryItems() async {
    return _getList('inventory', _inventoryFromMap);
  }

  static Future<List<FieldVisit>> getFieldVisits() async {
    return _getList('field_visits', _fieldVisitFromMap);
  }

  static Future<List<AttendanceRecord>> getAttendanceRecords() async {
    return _getList('attendance', _attendanceFromMap);
  }

  static Future<List<ServiceReport>> getServiceReports() async {
    return _getList('service_reports', _serviceReportFromMap);
  }

  static Future<List<Referral>> getReferrals() async {
    return _getList('referrals', _referralFromMap);
  }

  static Future<List<AlertItem>> getAlerts() async {
    return _getList('alerts', _alertFromMap);
  }

  static Future<void> saveFieldVisit(FieldVisit visit) {
    return _safeWrite(
      _db.collection('field_visits').doc(visit.id).set(_fieldVisitToMap(visit)),
    );
  }

  static Future<void> saveAttendanceRecord(AttendanceRecord record) {
    return _safeWrite(
      _db.collection('attendance').doc(record.id).set(_attendanceToMap(record)),
    );
  }

  static Future<void> saveServiceReport(ServiceReport report) async {
    await _safeWrite(
      _db
          .collection('service_reports')
          .doc(report.id)
          .set(_serviceReportToMap(report)),
    );
    await _updateUnitAfterReport(report);
  }

  static Future<void> verifyServiceReport(String id, String verifiedBy) {
    return _safeWrite(
      _db.collection('service_reports').doc(id).update({
        'isVerified': true,
        'verifiedBy': verifiedBy,
      }),
    );
  }

  static Future<void> saveInventoryItem(InventoryItem item) {
    return _safeWrite(
      _db.collection('inventory').doc(item.id).set(_inventoryToMap(item)),
    );
  }

  static Future<void> consumeInventory({
    required InventoryItem item,
    required int additionalConsumed,
  }) {
    final consumed = item.consumed + additionalConsumed;
    final remaining =
        (item.availableStock - consumed).clamp(0, item.availableStock).toInt();
    final updated = InventoryItem(
      id: item.id,
      medicineName: item.medicineName,
      category: item.category,
      unitId: item.unitId,
      unitName: item.unitName,
      availableStock: item.availableStock,
      consumed: consumed,
      remaining: remaining,
      unit: item.unit,
      lowStockThreshold: item.lowStockThreshold,
      isLowStock: remaining <= item.lowStockThreshold,
      lastUpdated: DateTime.now(),
    );
    return saveInventoryItem(updated).then((_) async {
      if (updated.isLowStock) {
        await saveAlert(
          AlertItem(
            id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
            type: 'low_inventory',
            severity: updated.isCriticallyLow ? 'critical' : 'warning',
            title: 'Low Stock: ${updated.medicineName}',
            message:
                '${updated.medicineName} has ${updated.remaining} ${updated.unit} remaining in ${updated.unitName}.',
            unitId: updated.unitId,
            unitName: updated.unitName,
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );
      }
    });
  }

  static Future<void> saveAlert(AlertItem alert) {
    return _safeWrite(
      _db.collection('alerts').doc(alert.id).set(_alertToMap(alert)),
    );
  }

  static Future<String?> uploadEvidence({
    required XFile file,
    required String folder,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final extension = file.name.split('.').last.toLowerCase();
      final safeExtension = extension.length <= 5 ? extension : 'jpg';
      final path =
          '$folder/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
      final ref = _storage.ref(path);
      final task = await _withTimeout(
        ref.putData(
          bytes,
          SettableMetadata(
            contentType: file.mimeType ?? 'image/$safeExtension',
          ),
        ),
      );
      return _withTimeout(task.ref.getDownloadURL());
    } catch (_) {
      return null;
    }
  }

  static Future<void> _updateUnitAfterReport(ServiceReport report) {
    return _bestEffortWrite(
      _db.collection('mobile_units').doc(report.unitId).set({
        'patientsServedThisMonth':
            FieldValue.increment(report.totalPopulationServed),
        'visitsThisMonth': FieldValue.increment(1),
        'villagesCovered': FieldValue.increment(1),
        'lastActivityTime': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true)),
    );
  }

  static Future<void> updateUnitAfterVisit(FieldVisit visit) {
    if (!visit.isCompleted) return Future.value();
    return _bestEffortWrite(
      _db.collection('mobile_units').doc(visit.unitId).set({
        'patientsServedThisMonth': FieldValue.increment(visit.patientsServed),
        'visitsThisMonth': FieldValue.increment(1),
        'lastActivityTime': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true)),
    );
  }

  static Future<void> saveReferral(Referral referral) {
    return _safeWrite(
      _db
          .collection('referrals')
          .doc(referral.id)
          .set(_referralToMap(referral)),
    );
  }

  static Future<void> updateReferralStatus(String id, String status) {
    return _safeWrite(
      _db.collection('referrals').doc(id).update({
        'status': status,
        'resolvedAt':
            status == 'closed' ? Timestamp.fromDate(DateTime.now()) : null,
      }),
    );
  }

  static Future<void> markAlertRead(String id, bool isRead) {
    return _safeWrite(
      _db.collection('alerts').doc(id).update({'isRead': isRead}),
    );
  }

  static Future<void> markAllAlertsRead() async {
    try {
      final snapshot = await _withTimeout(
        _db.collection('alerts').where('isRead', isEqualTo: false).get(),
      );
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await _withTimeout(batch.commit());
    } catch (_) {
      return;
    }
  }

  static Future<void> _safeWrite(Future<void> write) async {
    try {
      await _withTimeout(write);
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Could not save data to Firestore. $debugTargetSummary. '
            'Check Firestore rules, App Check enforcement, selected database, and network connection. Original error: $e',
      );
    }
  }

  static Future<void> _bestEffortWrite(Future<void> write) async {
    try {
      await _withTimeout(write);
    } catch (_) {
      return;
    }
  }

  static Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(
      _firebaseTimeout,
      onTimeout: () => throw TimeoutException(
        'Firebase request timed out. Check Firebase console configuration and network access.',
      ),
    );
  }

  static Future<List<T>> _getList<T>(
    String collection,
    T Function(String id, Map<String, dynamic> data) fromMap,
  ) async {
    try {
      final snapshot = await _withTimeout(_db.collection(collection).get());
      return snapshot.docs.map((doc) => fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Could not read $collection from Firestore. '
            '$debugTargetSummary. Original error: $e',
      );
    }
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    return _date(value);
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'HU';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static Map<String, dynamic> _userToMap(AppUser user) => {
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'role': user.role,
        'designation': user.designation,
        'phone': user.phone,
        'unitId': user.unitId,
        'district': user.district,
        'state': user.state,
        'avatarInitials': user.avatarInitials,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLogin':
            user.lastLogin == null ? null : Timestamp.fromDate(user.lastLogin!),
        'isActive': user.isActive,
      };

  static AppUser _userFromMap(String id, Map<String, dynamic> data) => AppUser(
        id: id,
        name: data['name'] ?? 'Healthcare User',
        email: data['email'] ?? '',
        password: data['password'] ?? '',
        role: data['role'] ?? 'officer',
        designation: data['designation'] ?? 'Doctor/Nurse',
        phone: data['phone'] ?? '',
        unitId: data['unitId'],
        district: data['district'] ?? '',
        state: data['state'] ?? '',
        avatarInitials: data['avatarInitials'] ?? 'HU',
        createdAt: _date(data['createdAt']),
        lastLogin: _nullableDate(data['lastLogin']),
        isActive: data['isActive'] ?? true,
      );

  static Map<String, dynamic> _mobileUnitToMap(MobileUnit unit) => {
        'name': unit.name,
        'unitCode': unit.unitCode,
        'status': unit.status,
        'teamSize': unit.teamSize,
        'teamMembers': unit.teamMembers,
        'district': unit.district,
        'state': unit.state,
        'villagesCovered': unit.villagesCovered,
        'lastActivityTime': Timestamp.fromDate(unit.lastActivityTime),
        'currentLatitude': unit.currentLatitude,
        'currentLongitude': unit.currentLongitude,
        'patientsServedThisMonth': unit.patientsServedThisMonth,
        'visitsThisMonth': unit.visitsThisMonth,
        'operationalSince': Timestamp.fromDate(unit.operationalSince),
        'vehicleNumber': unit.vehicleNumber,
        'supervisorId': unit.supervisorId,
      };

  static MobileUnit _mobileUnitFromMap(String id, Map<String, dynamic> data) =>
      MobileUnit(
        id: id,
        name: data['name'] ?? '',
        unitCode: data['unitCode'] ?? '',
        status: data['status'] ?? 'inactive',
        teamSize: data['teamSize'] ?? 0,
        teamMembers: List<String>.from(data['teamMembers'] ?? const []),
        district: data['district'] ?? '',
        state: data['state'] ?? '',
        villagesCovered: data['villagesCovered'] ?? 0,
        lastActivityTime: _date(data['lastActivityTime']),
        currentLatitude: (data['currentLatitude'] as num?)?.toDouble(),
        currentLongitude: (data['currentLongitude'] as num?)?.toDouble(),
        patientsServedThisMonth: data['patientsServedThisMonth'] ?? 0,
        visitsThisMonth: data['visitsThisMonth'] ?? 0,
        operationalSince: _date(data['operationalSince']),
        vehicleNumber: data['vehicleNumber'] ?? '',
        supervisorId: data['supervisorId'] ?? '',
      );

  static Map<String, dynamic> _fieldVisitToMap(FieldVisit visit) => {
        'unitId': visit.unitId,
        'unitName': visit.unitName,
        'officerId': visit.officerId,
        'officerName': visit.officerName,
        'villageName': visit.villageName,
        'district': visit.district,
        'startTime': Timestamp.fromDate(visit.startTime),
        'endTime':
            visit.endTime == null ? null : Timestamp.fromDate(visit.endTime!),
        'startLatitude': visit.startLatitude,
        'startLongitude': visit.startLongitude,
        'endLatitude': visit.endLatitude,
        'endLongitude': visit.endLongitude,
        'remarks': visit.remarks,
        'status': visit.status,
        'patientsServed': visit.patientsServed,
        'photoUrl': visit.photoUrl,
      };

  static FieldVisit _fieldVisitFromMap(String id, Map<String, dynamic> data) =>
      FieldVisit(
        id: id,
        unitId: data['unitId'] ?? '',
        unitName: data['unitName'] ?? '',
        officerId: data['officerId'] ?? '',
        officerName: data['officerName'] ?? '',
        villageName: data['villageName'] ?? '',
        district: data['district'] ?? '',
        startTime: _date(data['startTime']),
        endTime: _nullableDate(data['endTime']),
        startLatitude: (data['startLatitude'] as num?)?.toDouble(),
        startLongitude: (data['startLongitude'] as num?)?.toDouble(),
        endLatitude: (data['endLatitude'] as num?)?.toDouble(),
        endLongitude: (data['endLongitude'] as num?)?.toDouble(),
        remarks: data['remarks'] ?? '',
        status: data['status'] ?? 'in_progress',
        patientsServed: data['patientsServed'] ?? 0,
        photoUrl: data['photoUrl'],
      );

  static Map<String, dynamic> _attendanceToMap(AttendanceRecord record) => {
        'userId': record.userId,
        'userName': record.userName,
        'unitId': record.unitId,
        'date': Timestamp.fromDate(record.date),
        'checkInTime': record.checkInTime == null
            ? null
            : Timestamp.fromDate(record.checkInTime!),
        'checkOutTime': record.checkOutTime == null
            ? null
            : Timestamp.fromDate(record.checkOutTime!),
        'checkInLatitude': record.checkInLatitude,
        'checkInLongitude': record.checkInLongitude,
        'checkOutLatitude': record.checkOutLatitude,
        'checkOutLongitude': record.checkOutLongitude,
        'status': record.status,
        'remarks': record.remarks,
      };

  static AttendanceRecord _attendanceFromMap(
          String id, Map<String, dynamic> data) =>
      AttendanceRecord(
        id: id,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        unitId: data['unitId'] ?? '',
        date: _date(data['date']),
        checkInTime: _nullableDate(data['checkInTime']),
        checkOutTime: _nullableDate(data['checkOutTime']),
        checkInLatitude: (data['checkInLatitude'] as num?)?.toDouble(),
        checkInLongitude: (data['checkInLongitude'] as num?)?.toDouble(),
        checkOutLatitude: (data['checkOutLatitude'] as num?)?.toDouble(),
        checkOutLongitude: (data['checkOutLongitude'] as num?)?.toDouble(),
        selfieUrl: data['selfieUrl'],
        status: data['status'] ?? 'present',
        remarks: data['remarks'],
      );

  static Map<String, dynamic> _serviceReportToMap(ServiceReport report) => {
        'unitId': report.unitId,
        'unitName': report.unitName,
        'officerId': report.officerId,
        'officerName': report.officerName,
        'campDate': Timestamp.fromDate(report.campDate),
        'villageName': report.villageName,
        'district': report.district,
        'state': report.state,
        'totalMale': report.totalMale,
        'totalFemale': report.totalFemale,
        'totalChildren': report.totalChildren,
        'totalSeniorCitizens': report.totalSeniorCitizens,
        'generalConsultations': report.generalConsultations,
        'diabetesScreening': report.diabetesScreening,
        'hypertensionScreening': report.hypertensionScreening,
        'maternalHealthServices': report.maternalHealthServices,
        'childHealthServices': report.childHealthServices,
        'vaccinationSupport': report.vaccinationSupport,
        'referralCases': report.referralCases,
        'remarks': report.remarks,
        'submittedAt': Timestamp.fromDate(report.submittedAt),
        'isVerified': report.isVerified,
        'verifiedBy': report.verifiedBy,
      };

  static ServiceReport _serviceReportFromMap(
          String id, Map<String, dynamic> data) =>
      ServiceReport(
        id: id,
        unitId: data['unitId'] ?? '',
        unitName: data['unitName'] ?? '',
        officerId: data['officerId'] ?? '',
        officerName: data['officerName'] ?? '',
        campDate: _date(data['campDate']),
        villageName: data['villageName'] ?? '',
        district: data['district'] ?? '',
        state: data['state'] ?? '',
        totalMale: data['totalMale'] ?? 0,
        totalFemale: data['totalFemale'] ?? 0,
        totalChildren: data['totalChildren'] ?? 0,
        totalSeniorCitizens: data['totalSeniorCitizens'] ?? 0,
        generalConsultations: data['generalConsultations'] ?? 0,
        diabetesScreening: data['diabetesScreening'] ?? 0,
        hypertensionScreening: data['hypertensionScreening'] ?? 0,
        maternalHealthServices: data['maternalHealthServices'] ?? 0,
        childHealthServices: data['childHealthServices'] ?? 0,
        vaccinationSupport: data['vaccinationSupport'] ?? 0,
        referralCases: data['referralCases'] ?? 0,
        remarks: data['remarks'] ?? '',
        submittedAt: _date(data['submittedAt']),
        isVerified: data['isVerified'] ?? false,
        verifiedBy: data['verifiedBy'],
      );

  static Map<String, dynamic> _referralToMap(Referral referral) => {
        'unitId': referral.unitId,
        'unitName': referral.unitName,
        'officerId': referral.officerId,
        'officerName': referral.officerName,
        'patientCode': referral.patientCode,
        'age': referral.age,
        'gender': referral.gender,
        'reason': referral.reason,
        'referredFacility': referral.referredFacility,
        'status': referral.status,
        'priority': referral.priority,
        'followUpNotes': referral.followUpNotes,
        'createdAt': Timestamp.fromDate(referral.createdAt),
        'resolvedAt': referral.resolvedAt == null
            ? null
            : Timestamp.fromDate(referral.resolvedAt!),
      };

  static Referral _referralFromMap(String id, Map<String, dynamic> data) =>
      Referral(
        id: id,
        unitId: data['unitId'] ?? '',
        unitName: data['unitName'] ?? '',
        officerId: data['officerId'] ?? '',
        officerName: data['officerName'] ?? '',
        patientCode: data['patientCode'] ?? '',
        age: data['age'] ?? 0,
        gender: data['gender'] ?? '',
        reason: data['reason'] ?? '',
        referredFacility: data['referredFacility'] ?? '',
        status: data['status'] ?? 'pending',
        priority: data['priority'] ?? 'Medium',
        followUpNotes: data['followUpNotes'] ?? '',
        createdAt: _date(data['createdAt']),
        resolvedAt: _nullableDate(data['resolvedAt']),
      );

  static Map<String, dynamic> _inventoryToMap(InventoryItem item) => {
        'medicineName': item.medicineName,
        'category': item.category,
        'unitId': item.unitId,
        'unitName': item.unitName,
        'availableStock': item.availableStock,
        'consumed': item.consumed,
        'remaining': item.remaining,
        'unit': item.unit,
        'lowStockThreshold': item.lowStockThreshold,
        'isLowStock': item.isLowStock,
        'lastUpdated': Timestamp.fromDate(item.lastUpdated),
      };

  static InventoryItem _inventoryFromMap(
          String id, Map<String, dynamic> data) =>
      InventoryItem(
        id: id,
        medicineName: data['medicineName'] ?? '',
        category: data['category'] ?? '',
        unitId: data['unitId'] ?? '',
        unitName: data['unitName'] ?? '',
        availableStock: data['availableStock'] ?? 0,
        consumed: data['consumed'] ?? 0,
        remaining: data['remaining'] ?? 0,
        unit: data['unit'] ?? '',
        lowStockThreshold: data['lowStockThreshold'] ?? 0,
        isLowStock: data['isLowStock'] ?? false,
        lastUpdated: _date(data['lastUpdated']),
      );

  static Map<String, dynamic> _alertToMap(AlertItem alert) => {
        'type': alert.type,
        'severity': alert.severity,
        'title': alert.title,
        'message': alert.message,
        'unitId': alert.unitId,
        'unitName': alert.unitName,
        'isRead': alert.isRead,
        'createdAt': Timestamp.fromDate(alert.createdAt),
      };

  static AlertItem _alertFromMap(String id, Map<String, dynamic> data) =>
      AlertItem(
        id: id,
        type: data['type'] ?? '',
        severity: data['severity'] ?? 'info',
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        unitId: data['unitId'],
        unitName: data['unitName'],
        isRead: data['isRead'] ?? false,
        createdAt: _date(data['createdAt']),
      );
}

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _db = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  // ── Auth ────────────────────────────────────────────────────────
  Future<String?> sendOtp(
      String phoneNumber,
      Function(String verificationId) onCodeSent,
      Function(String error) onError) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> verifyOtp(String verificationId, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async => _auth.signOut();

  // ── Patients ────────────────────────────────────────────────────
  Future<void> savePatient(String patientId, Map<String, dynamic> data) async {
    await _db.ref('patients/$patientId').set({
      ...data,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    final snap = await _db.ref('patients/$patientId').get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  Future<bool> patientExists(String phone) async {
    final snap1 = await _db.ref('patients').orderByChild('phone').equalTo(phone).limitToFirst(1).get();
    if (snap1.exists) return true;
    final snap2 = await _db.ref('users').orderByChild('phone').equalTo(phone).limitToFirst(1).get();
    if (snap2.exists) return true;
    // Check workers node
    final snap3 = await _db.ref('workers').orderByChild('phone').equalTo(phone).limitToFirst(1).get();
    return snap3.exists;
  }

  /// Migrate old 'users' node entries into 'patients' (call once on login)
  Future<void> migrateUserToPatient(String phone) async {
    final snap = await _db.ref('users').orderByChild('phone').equalTo(phone).limitToFirst(1).get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    for (final entry in data.entries) {
      final patientData = Map<String, dynamic>.from(entry.value as Map);
      final patientId = patientData['patientId'] ?? entry.key;
      await _db.ref('patients/$patientId').set({...patientData, 'migratedAt': ServerValue.timestamp});
      await _db.ref('users/${entry.key}').remove();
    }
  }

  // ── Consultations ───────────────────────────────────────────────
  Future<String> saveConsultation(
      String patientId, Map<String, dynamic> data) async {
    final id = _uuid.v4();
    await _db.ref('consultations/$id').set({
      ...data,
      'id': id,
      'patientId': patientId,
      'status': 'Pending',
      'createdAt': ServerValue.timestamp,
    });
    // Also add to patient's consultations list
    await _db.ref('patients/$patientId/consultations/$id').set(true);
    return id;
  }

  Stream<List<Map<String, dynamic>>> watchConsultations(String patientId) {
    return _db
        .ref('consultations')
        .orderByChild('patientId')
        .equalTo(patientId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList()
        ..sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
    });
  }

  Future<void> updateConsultationStatus(String consultationId, String status,
      {String? notes}) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': ServerValue.timestamp
    };
    if (notes != null) updates['workerNotes'] = notes;
    await _db.ref('consultations/$consultationId').update(updates);
  }

  // ── Medicine Requests ───────────────────────────────────────────
  Future<String> saveMedicineRequest(
      String patientId, Map<String, dynamic> data) async {
    final id = _uuid.v4();
    await _db.ref('medicineRequests/$id').set({
      ...data,
      'id': id,
      'patientId': patientId,
      'status': 'Pending',
      'createdAt': ServerValue.timestamp,
    });
    await _db.ref('patients/$patientId/medicineRequests/$id').set(true);
    return id;
  }

  Stream<List<Map<String, dynamic>>> watchMedicineRequests(String patientId) {
    return _db
        .ref('medicineRequests')
        .orderByChild('patientId')
        .equalTo(patientId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList()
        ..sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
    });
  }

  // ── Messages ────────────────────────────────────────────────────
  Future<void> saveMessage(String patientId, Map<String, dynamic> data) async {
    final id = _uuid.v4();
    await _db.ref('messages/$patientId/$id').set({
      ...data,
      'id': id,
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String patientId) {
    return _db
        .ref('messages/$patientId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    });
  }

  // ── Health Tips ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getHealthTips() async {
    final snap = await _db.ref('healthTips').limitToLast(20).get();
    if (!snap.exists) return [];
    final data = Map<String, dynamic>.from(snap.value as Map);
    return data.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  // ── Announcements ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final snap = await _db.ref('announcements').limitToLast(10).get();
    if (!snap.exists) return [];
    final data = Map<String, dynamic>.from(snap.value as Map);
    return data.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  // ── Workers ─────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchWorkerConsultations(String barangay) {
    return _db
        .ref('consultations')
        .orderByChild('barangay')
        .equalTo(barangay)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    });
  }
}

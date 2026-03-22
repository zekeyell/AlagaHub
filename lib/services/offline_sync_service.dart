import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alagahub/services/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Handles offline→online sync of consultations and medicine requests.
/// Call [syncPendingOffline] whenever the app detects it is back online.
class OfflineSyncService {
  static final OfflineSyncService _i = OfflineSyncService._();
  factory OfflineSyncService() => _i;
  OfflineSyncService._();

  final _db = FirebaseDatabase.instance;

  Future<bool> isOnline() async {
    try {
      final r = await Connectivity().checkConnectivity();
      return !r.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Syncs all local offline-pending consultations to Firebase.
  /// Three-way merge: patient SQLite + offlineCases worker decision + existing Firebase.
  Future<SyncResult> syncPendingOffline() async {
    if (!await isOnline()) return SyncResult(synced: 0, errors: 0);

    final db = await DatabaseService().database;
    final prefs = await SharedPreferences.getInstance();
    final myPatientId = prefs.getString('patient_id') ?? '';
    final now = DateTime.now().toIso8601String();

    // Reset any records accidentally marked synced before patient tapped Sync Now
    await db.update('consultations', {'synced': 0},
      where: "offline_source = 1 AND "
          "(status = 'Offline-Pending' OR status = 'Offline-pending')",
    ).catchError((_) => 0);

    final rows = await db.query('consultations',
      where: "offline_source = 1 AND "
          "(status = 'Offline-Pending' OR status = 'Offline-pending')",
    );

    int synced = 0;
    int errors = 0;

    for (final row in rows) {
      final caseId = (row['case_id'] ?? row['id'] ?? '').toString();
      if (caseId.isEmpty) continue;
      try {
        // Layer 1: read existing Firebase record (may already have worker data)
        final existingSnap = await _db.ref('consultations/$caseId').get();
        final existing = existingSnap.exists && existingSnap.value != null
            ? Map<String, dynamic>.from(existingSnap.value as Map)
            : <String, dynamic>{};

        // Layer 2: read worker decision from offlineCases
        final workerSnap = await _db.ref('offlineCases/$caseId').get();
        final workerData = workerSnap.exists && workerSnap.value != null
            ? Map<String, dynamic>.from(workerSnap.value as Map)
            : <String, dynamic>{};

        // Resolve worker identity: offlineCases > existing Firebase > SQLite
        final workerUid = ((workerData['workerUid']
            ?? existing['workerUid']
            ?? row['worker_uid']) ?? '').toString();
        final workerName = ((workerData['workerName']
            ?? existing['workerName']
            ?? row['worker_name']) ?? '').toString();
        final workerPhone = ((workerData['workerPhone']
            ?? existing['workerPhone']
            ?? row['worker_phone']) ?? '').toString();

        // Resolve final status: offlineCases > existing Firebase > Pending
        final rawStatus = ((workerData['workerStatus']
            ?? existing['status']) ?? 'Pending').toString();
        final finalStatus = (rawStatus == 'Confirmed' || rawStatus == 'Cancelled')
            ? rawStatus : 'Pending';

        // Layer 3: build merged record
        final merged = <String, dynamic>{
          ...existing,
          'id':             caseId,
          'case_id':        caseId,
          'patient_id':     (row['patient_id'] ?? '').toString(),
          'patientId':      (row['patient_id'] ?? '').toString(),
          'patient_name':   ((row['patient_name'] ?? existing['patient_name']) ?? '').toString(),
          'patientName':    ((row['patient_name'] ?? existing['patientName']) ?? '').toString(),
          'barangay':       ((row['barangay'] ?? existing['barangay']) ?? '').toString(),
          'symptoms':       (row['symptoms'] ?? '').toString(),
          'temperature':    (row['temperature'] as num?)?.toDouble() ?? 36.5,
          'pain_level':     (row['pain_level'] as int?) ?? 1,
          'duration':       (row['duration'] ?? '').toString(),
          'notes':          (row['notes'] ?? '').toString(),
          'type':           (row['type'] ?? '').toString(),
          'preferred_date': (row['preferred_date'] ?? '').toString(),
          'preferred_time': (row['preferred_time'] ?? '').toString(),
          'health_center':  (row['health_center'] ?? '').toString(),
          'created_at':     (row['created_at'] ?? '').toString(),
          'createdAt':      (row['created_at'] ?? '').toString(),
          'workerUid':      workerUid,
          'workerName':     workerName,
          'workerPhone':    workerPhone,
          'status':         finalStatus,
          'source':         'offline-sms',
          'synced':         1,
          'syncedAt':       now,
          'matchedAt':      now,
        };

        // Write single merged record — both sides see the same data
        await _db.ref('consultations/$caseId').set(merged);

        // Notify patient if worker already decided (once only)
        if ((finalStatus == 'Confirmed' || finalStatus == 'Cancelled')
            && myPatientId.isNotEmpty) {
          final notifKey = 'offline_notif_$caseId';
          if (!(prefs.getBool(notifKey) ?? false)) {
            await _db.ref('messages/$myPatientId').push().set({
              'patient_id': myPatientId,
              'sender': 'system',
              'content': finalStatus == 'Confirmed'
                  ? 'Your offline consultation ($caseId) has been '
                    'confirmed by $workerName.'
                  : 'Your offline consultation ($caseId) was not '
                    'accepted. Please re-book online.',
              'sent_at': now,
              'is_system': 1,
            });
            await prefs.setBool(notifKey, true);
          }
        }

        // Update SQLite with final status
        await db.update('consultations',
          {'synced': 1, 'is_synced': 1, 'status': finalStatus},
          where: 'id = ? OR case_id = ?',
          whereArgs: [caseId, caseId],
        );
        synced++;
      } catch (e) {
        errors++;
      }
    }

    // Also sync unsynced medicine requests
    final medRows = await db.query('medicine_requests',
      where: "synced = 0 AND status = 'Offline-Pending'",
    );
    for (final row in medRows) {
      final reqId = (row['request_id'] ?? row['id'] ?? '').toString();
      if (reqId.isEmpty) continue;
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(row);
        data['status'] = 'Pending';
        data['synced'] = 1;
        data['syncedAt'] = now;
        await _db.ref('medicineRequests/$reqId').set(data);
        await db.update('medicine_requests',
          {'synced': 1, 'is_synced': 1, 'status': 'Pending'},
          where: 'id = ? OR request_id = ?',
          whereArgs: [reqId, reqId],
        );
        synced++;
      } catch (e) {
        errors++;
      }
    }

    return SyncResult(synced: synced, errors: errors);
  }
  /// Worker calls this to save a manually-entered offline case.
  /// Saves to offlineCases/ in Firebase so patient can match it on sync.
  Future<void> workerSaveOfflineCase({
    required String caseId,
    required String patientId,
    required String patientName,
    required String barangay,
    required String symptoms,
    required String workerUid,
    required String workerName,
    required String workerStatus, // 'Confirmed' or 'Cancelled'
    String notes = '',
    String type = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'caseId': caseId,
      'patientId': patientId,
      'patientName': patientName,
      'barangay': barangay,
      'symptoms': symptoms,
      'type': type,
      'notes': notes,
      'workerUid': workerUid,
      'workerName': workerName,
      'workerStatus': workerStatus,
      'createdAt': now,
      'source': 'offline-sms',
    };
    // Store under offlineCases/caseId so patient sync can find it
    await _db.ref('offlineCases/$caseId').set(data);
    // Also push to consultations/ immediately so it appears in worker bookings
    await _db.ref('consultations/$caseId').set({
      ...data,
      'status': workerStatus,
      'synced': 1,
    });
  }
}

class SyncResult {
  final int synced;
  final int errors;
  const SyncResult({required this.synced, required this.errors});
}

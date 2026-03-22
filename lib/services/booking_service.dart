
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/services/database_service.dart';

class BookingService {
  static final BookingService _i = BookingService._();
  factory BookingService() => _i;
  BookingService._();

  final _db = FirebaseDatabase.instance;

  /// Find the nearest available worker based on barangay/city match.
  /// Priority: same barangay > same city > same region > any worker
  Future<Map<String, dynamic>?> findNearestWorker({
    required String patientBarangay,
    required String patientCity,
    required String patientRegion,
  }) async {
    try {
      final snap = await _db.ref('workers').get();
      if (!snap.exists || snap.value == null) {
        return null;
      }

      final workers = Map<String, dynamic>.from(snap.value as Map)
          .entries
          .map((e) {
            final w = Map<String, dynamic>.from(e.value as Map);
            w['uid'] = e.key;
            return w;
          })
          .where((w) => (w['role'] ?? 'worker') == 'worker')
          .toList();

      if (workers.isEmpty) {
        return null;
      }

      // Priority matching
      final sameBarangay = workers.where((w) =>
          (w['barangay'] ?? '').toLowerCase() ==
          patientBarangay.toLowerCase()).toList();
      if (sameBarangay.isNotEmpty) {
        return sameBarangay.first;
      }

      final sameCity = workers.where((w) =>
          (w['city'] ?? '').toLowerCase() ==
          patientCity.toLowerCase()).toList();
      if (sameCity.isNotEmpty) {
        return sameCity.first;
      }

      final sameRegion = workers.where((w) =>
          (w['region'] ?? '').toLowerCase() ==
          patientRegion.toLowerCase()).toList();
      if (sameRegion.isNotEmpty) {
        return sameRegion.first;
      }

      return workers.first; // fallback: any worker
    } catch (e) {
      return null;
    }
  }


  /// Find nearest worker using local SQLite cache (offline fallback).
  Future<Map<String, dynamic>?> findNearestWorkerOffline({
    required String patientBarangay,
    required String patientCity,
    required String patientRegion,
  }) async {
    return DatabaseService().findNearestWorkerOffline(
      barangay: patientBarangay,
      city: patientCity,
      region: patientRegion,
    );
  }

  /// Refresh the local workers cache from Firebase.
  /// Call this whenever the app comes online.
  Future<void> refreshWorkerCache() async {
    try {
      final snap = await _db.ref('workers').get();
      if (!snap.exists || snap.value == null) {
        return;
      }
      final workers = Map<String, dynamic>.from(snap.value as Map)
          .entries
          .map((e) {
            final w = Map<String, dynamic>.from(e.value as Map);
            w['uid'] = e.key;
            return w;
          })
          .where((w) => (w['role'] ?? 'worker') == 'worker')
          .toList();
      await DatabaseService().cacheWorkers(workers);
    } catch (e) {
      // Silently fail — offline cache will serve stale data
    }
  }
  /// Create a booking in Firebase and SQLite
  Future<String> createBooking({
    required String type, // 'consultation' or 'medicine'
    required String referenceId, // caseId or reqId
    required Map<String, dynamic> patientData,
    required Map<String, dynamic> itemData,
  }) async {
    final bookingId = 'BKG-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    final patientBarangay = patientData['barangay'] ?? '';
    final patientCity = patientData['city'] ?? '';
    final patientRegion = patientData['region'] ?? '';

    // Find nearest worker
    final worker = await findNearestWorker(
      patientBarangay: patientBarangay,
      patientCity: patientCity,
      patientRegion: patientRegion,
    );

    final bookingData = <String, dynamic>{
      'bookingId': bookingId,
      'type': type,
      'referenceId': referenceId,
      'status': 'Pending',
      'patientId': patientData['patientId'] ?? '',
      'patientName': patientData['fullName'] ?? '',
      'patientBarangay': patientBarangay,
      'patientCity': patientCity,
      'patientPhone': patientData['phone'] ?? '',
      'workerUid': worker?['uid'] ?? '',
      'workerName': worker?['fullName'] ?? worker?['firstName'] ?? 'Unassigned',
      'workerBarangay': worker?['barangay'] ?? '',
      'workerPhone': worker?['phone'] ?? '',
      'createdAt': now,
      'updatedAt': now,
      'synced': 1,
    };

    // Save to Firebase
    try {
      await _db.ref('bookings/$bookingId').set(bookingData);
      // Notify the assigned worker
      if ((worker?['uid'] ?? '').isNotEmpty) {
        await _db.ref("workerNotifications/${worker!['uid'] ?? ''}").push().set({
          'bookingId': bookingId,
          'type': type,
          'patientName': patientData['fullName'] ?? '',
          'patientBarangay': patientBarangay,
          'referenceId': referenceId,
          'status': 'New',
          'createdAt': now,
        });
      }
    } catch (e) {
      // Offline - save locally only
    }

    // Save to SQLite for offline access
    try {
      final db = await DatabaseService().database;
      await db.insert('bookings', {
        'booking_id': bookingId,
        'type': type,
        'reference_id': referenceId,
        'status': 'Pending',
        'patient_id': patientData['patientId'] ?? '',
        'worker_uid': worker?['uid'] ?? '',
        'created_at': now,
        'synced': 1,
      });
    } catch (e) {
      // Table might not exist yet
    }

    return bookingId;
  }

  /// Update booking status
  Future<void> updateStatus(String bookingId, String status) async {
    final now = DateTime.now().toIso8601String();
    try {
      await _db.ref('bookings/$bookingId').update({
        'status': status,
        'updatedAt': now,
      });
    } catch (e) {
      // Offline
    }
  }

  /// Get bookings for a worker (stream)
  Stream<List<Map<String, dynamic>>> watchWorkerBookings(String workerUid) {
    return _db
        .ref('bookings')
        .orderByChild('workerUid')
        .equalTo(workerUid)
        .onValue
        .map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) {
        return [];
      }
      final data = Map<String, dynamic>.from(e.snapshot.value as Map);
      return data.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList()
        ..sort((a, b) =>
            (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
    });
  }

  /// Get worker's unread notifications
  Stream<List<Map<String, dynamic>>> watchWorkerNotifications(String workerUid) {
    return _db
        .ref('workerNotifications/$workerUid')
        .onValue
        .map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) {
        return [];
      }
      final data = Map<String, dynamic>.from(e.snapshot.value as Map);
      return data.entries.map((entry) {
        final n = Map<String, dynamic>.from(entry.value as Map);
        n['key'] = entry.key;
        return n;
      }).toList()
        ..sort((a, b) =>
            (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
    });
  }

  /// Generate offline SMS for booking (when no internet)
  String generateBookingSms({
    required String type,
    required String bookingId,
    required String referenceId,
    required Map<String, dynamic> patientData,
    required Map<String, dynamic> itemData,
  }) {
    final name = patientData['fullName'] ?? '';
    final pid = patientData['patientId'] ?? '';
    final barangay = patientData['barangay'] ?? '';
    final typeLabel = type == 'consultation' ? 'CONSULTATION' : 'MEDICINE REQUEST';

    final buf = StringBuffer();
    buf.writeln('[ALAGAHUB $typeLabel]');
    buf.writeln('Booking ID : $bookingId');
    buf.writeln('Patient    : $name');
    buf.writeln('Patient ID : $pid');
    buf.writeln('Barangay   : $barangay');
    buf.writeln('Ref ID     : $referenceId');
    if (type == 'consultation') {
      buf.writeln('Symptoms   : ${itemData["symptoms"] ?? ""}');
      buf.writeln('Date       : ${itemData["preferred_date"] ?? ""}');
      buf.writeln('Time       : ${itemData["preferred_time"] ?? ""}');
      buf.writeln('Type       : ${itemData["type"] ?? ""}');
    } else {
      buf.writeln('Medicine   : ${itemData["medicine_name"] ?? ""}');
      buf.writeln('Quantity   : ${itemData["quantity"]?.toString() ?? "1"}');
    }
    buf.writeln('---');
    buf.writeln('Reply ACCEPT $bookingId to accept');
    buf.write('Reply REJECT $bookingId to reject');
    return buf.toString();
  }
}

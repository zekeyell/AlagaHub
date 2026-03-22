import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/services/database_service.dart';

class SyncService {
  static final instance = SyncService._();
  SyncService._();

  bool _running = false;

  /// Call this whenever connectivity is restored.
  Future<void> runSync() async {
    if (_running) return;
    _running = true;
    try {
      await _syncConsultations();
      await _syncMedicineRequests();
    } finally {
      _running = false;
    }
  }

  Future<void> _syncConsultations() async {
    final list = await DatabaseService().getUnsyncedConsultations();
    for (final r in list) {
      final id = r['id'] as String?;
      if (id == null || id.isEmpty) continue;
      try {
        // Use UUID as Firebase key — merge by setting individual fields
        await FirebaseDatabase.instance
            .ref('consultations/$id')
            .update({
          'case_id': r['case_id'],
          'patient_id': r['patient_id'],
          'patient_name': r['patient_name'] ?? '',
          'barangay': r['barangay'] ?? '',
          'symptoms': r['symptoms'],
          'temperature': r['temperature'],
          'pain_level': r['pain_level'],
          'duration': r['duration'],
          'notes': r['notes'],
          'type': r['type'],
          'preferred_date': r['preferred_date'],
          'preferred_time': r['preferred_time'],
          'health_center': r['health_center'],
          'status': r['status'] ?? 'pending',
          'created_at': r['created_at'],
          'synced_from_device': true,
        });
        await DatabaseService().markConsultationSynced(id);
      } catch (e) {
        // Silently continue — will retry next sync
      }
    }
  }

  Future<void> _syncMedicineRequests() async {
    final list = await DatabaseService().getUnsyncedMedicineRequests();
    for (final r in list) {
      final id = r['id'] as String?;
      if (id == null || id.isEmpty) continue;
      try {
        await FirebaseDatabase.instance
            .ref('medicineRequests/$id')
            .update({
          'request_id': r['request_id'],
          'patient_id': r['patient_id'],
          'patient_name': r['patient_name'] ?? '',
          'barangay': r['barangay'] ?? '',
          'medicine_name': r['medicine_name'],
          'generic_name': r['generic_name'],
          'quantity': r['quantity'],
          'is_free': r['is_free'] ?? 0,
          'price': r['price'] ?? 0,
          'delivery_method': r['delivery_method'],
          'health_center': r['health_center'],
          'status': r['status'] ?? 'pending',
          'created_at': r['created_at'],
          'synced_from_device': true,
        });
        await DatabaseService().markMedicineRequestSynced(id);
      } catch (e) {
        // Silently continue — will retry next sync
      }
    }
  }
}

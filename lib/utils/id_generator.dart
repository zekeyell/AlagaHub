import 'package:uuid/uuid.dart';

class IdGenerator {
  static const _uuid = Uuid();

  /// Full UUID — used as SQLite primary key and Firestore doc ID.
  /// Generated entirely on-device, no internet needed, < 1ms.
  static String newUuid() => _uuid.v4();

  /// CASE-2024-F47AC-123
  /// Short human-readable display code derived from UUID.
  /// patientId last 3 chars make it unique per patient.
  static String caseId({required String patientId}) {
    final raw = _uuid.v4();
    final year = DateTime.now().year;
    final short = raw.substring(0, 5).toUpperCase();
    final suffix = patientId.length >= 3
        ? patientId.substring(patientId.length - 3)
        : patientId;
    return 'CASE-$year-$short-$suffix';
  }

  /// MED-2024-F47AC-123
  static String requestId({required String patientId}) {
    final raw = _uuid.v4();
    final year = DateTime.now().year;
    final short = raw.substring(0, 5).toUpperCase();
    final suffix = patientId.length >= 3
        ? patientId.substring(patientId.length - 3)
        : patientId;
    return 'MED-$year-$short-$suffix';
  }

  /// RHC-NCR-2024-00123 — generated at registration (requires internet once)
  static String patientId({String region = 'NCR'}) {
    final raw = _uuid.v4();
    final year = DateTime.now().year;
    final num = raw.substring(0, 5).toUpperCase();
    return 'RHC-$region-$year-$num';
  }
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Magandang umaga';
  if (hour < 18) return 'Magandang hapon';
  return 'Magandang gabi';
}

String formatPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0') && digits.length == 11) {
    return '+63${digits.substring(1)}';
  }
  if (digits.startsWith('63') && digits.length == 12) {
    return '+$digits';
  }
  return '+63$digits';
}

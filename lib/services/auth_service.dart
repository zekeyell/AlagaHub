import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alagahub/services/firebase_service.dart';

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
    if (user == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'patient';
    return AppUser(
      uid: user.uid,
      role: role,
      phoneNumber: user.phoneNumber ?? '',
    );
  });
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AppUser {
  final String uid;
  final String role;
  final String phoneNumber;
  AppUser({required this.uid, required this.role, required this.phoneNumber});
}

class AuthService {
  final _fb = FirebaseService();

  Future<void> signOut() async {
    await _fb.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Demo login for development
  Future<void> mockLogin({required String phone, required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', 'demo_$role');
    await prefs.setString('user_role', role);
    await prefs.setString('user_phone', phone);
    await prefs.setString(
        'patient_name', 'Demo ${role[0].toUpperCase()}${role.substring(1)}');
    await prefs.setString('patient_id', 'RHC-NCR-2025-00001');
    await prefs.setString('patient_barangay', 'Barangay Poblacion');
    await prefs.setString('patient_health_center', 'Poblacion Health Center');
    await prefs.setString('patient_blood_type', 'O+');
  }
}

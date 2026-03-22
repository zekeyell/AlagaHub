
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/id_generator.dart';
import 'package:alagahub/widgets/app_bar_widget.dart';
import 'package:alagahub/services/registration_provider.dart';
import 'package:alagahub/screens/patient/patient_shell.dart';
import 'package:alagahub/screens/worker/worker_shell.dart';

class RegReviewScreen extends ConsumerStatefulWidget {
  final String role;
  const RegReviewScreen({super.key, this.role = 'patient'});
  @override
  ConsumerState<RegReviewScreen> createState() => _RegReviewScreenState();
}

class _RegReviewScreenState extends ConsumerState<RegReviewScreen> {
  bool _agreed = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please agree to the terms to continue.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);

    final data = ref.read(registrationProvider);
    final regionCode = data.region.replaceAll('Region ', 'R').replaceAll(' ', '');
    final patientId = IdGenerator.patientId(region: regionCode);
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? patientId;
    final healthCenter = 'Barangay Health Center - ${data.barangay}';

    final patientData = <String, dynamic>{
      'patientId': patientId,
      'uid': uid,
      'phone': user?.phoneNumber ?? '',
      'firstName': data.firstName,
      'lastName': data.lastName,
      'middleName': data.middleName,
      'fullName': data.fullName,
      'birthdate': data.birthdate?.toIso8601String() ?? '',
      'age': data.age ?? 0,
      'sex': data.sex,
      'civilStatus': data.civilStatus,
      'houseStreet': data.houseStreet,
      'barangay': data.barangay,
      'city': data.city,
      'province': data.province,
      'region': data.region,
      'bloodType': data.bloodType,
      'allergies': data.allergies.join(','),
      'conditions': data.conditions.join(','),
      'hasSurgeries': data.hasSurgeries,
      'surgeriesDetail': data.surgeriesDetail,
      'currentMedications': data.currentMedications,
      'familyHistory': data.familyHistory.join(','),
      'emergencyName': data.emergencyName,
      'emergencyPhone': data.emergencyPhone,
      'emergencyRelation': data.emergencyRelation,
      'philhealthNumber': data.philhealthNumber,
      'hmoName': data.hmoName,
      'hmoId': data.hmoId,
      'healthCenter': healthCenter,
      'role': widget.role,
      'registeredAt': DateTime.now().toIso8601String(),
    };

    try {
      final db = FirebaseDatabase.instance;
      // Save to role-specific collection
      final collection = widget.role == 'worker' ? 'workers' : 'patients';
      await db.ref('$collection/$patientId').set(patientData);
      // Also save to users collection for login lookup
      await db.ref('users/$uid').set({
        'patientId': patientId,
        'role': widget.role,
        'phone': user?.phoneNumber ?? '',
        'fullName': data.fullName,
        'registeredAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firebase save error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', patientId);
    await prefs.setString('user_role', widget.role);
    await prefs.setString('patient_id', patientId);
    await prefs.setString('patient_name', data.fullName);
    await prefs.setString('patient_barangay', data.barangay);
    await prefs.setString('patient_city',     data.city);
    await prefs.setString('patient_region',   data.region);
    await prefs.setString('patient_health_center', healthCenter);
    await prefs.setString('patient_blood_type', data.bloodType);
    await prefs.setString('user_phone', user?.phoneNumber ?? '');
    await prefs.setString('firebase_uid', uid);

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    final dest = widget.role == 'worker' ? const WorkerShell() : const PatientShell();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dest),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(registrationProvider);
    return Scaffold(
      appBar: buildAppBar(context, 'Review Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Your Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Please make sure everything is correct before submitting.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _Section(title: 'Personal Information', rows: [
              _Row('Full Name', data.fullName.isEmpty ? '—' : data.fullName),
              if (data.birthdate != null)
                _Row('Date of Birth',
                    DateFormat('MMMM d, yyyy').format(data.birthdate!)),
              _Row('Sex', data.sex.isEmpty ? '—' : data.sex),
              _Row('Civil Status',
                  data.civilStatus.isEmpty ? '—' : data.civilStatus),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Address', rows: [
              _Row('Street',
                  data.houseStreet.isEmpty ? '—' : data.houseStreet),
              _Row('Barangay', data.barangay.isEmpty ? '—' : data.barangay),
              _Row('City', data.city.isEmpty ? '—' : data.city),
              _Row('Region', data.region.isEmpty ? '—' : data.region),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Health Profile', rows: [
              _Row('Blood Type',
                  data.bloodType.isEmpty ? 'Not specified' : data.bloodType),
              if (data.allergies.isNotEmpty)
                _Row('Allergies', data.allergies.join(', ')),
              if (data.conditions.isNotEmpty)
                _Row('Conditions', data.conditions.join(', ')),
              _Row(
                'Emergency Contact',
                data.emergencyName.isEmpty
                    ? '—'
                    : '${data.emergencyName} (${data.emergencyRelation})',
              ),
            ]),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  activeColor: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'I confirm that all the information I provided is correct.',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...'),
                      ],
                    )
                  : const Text('Create Account'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Row {
  final String label, value;
  const _Row(this.label, this.value);
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  // ignore: unused_element_parameter
  const _Section({required this.title, required this.rows, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const Divider(height: 1),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(r.label,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(r.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

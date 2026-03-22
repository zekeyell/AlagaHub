import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/services/firebase_service.dart';
import 'package:alagahub/screens/auth/registration/reg_step1_screen.dart';
import 'package:alagahub/screens/patient/patient_shell.dart';
import 'package:alagahub/screens/worker/worker_shell.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? verificationId;
  final String role;
  final bool isRegister;
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.verificationId,
    this.role = 'patient',
    this.isRegister = false,
  });
  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _otp = '';
  bool _loading = false;
  String? _error;
  int _seconds = 60;
  Timer? _timer;
  String? _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_seconds == 0) { t.cancel(); } else { setState(() => _seconds--); }
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });
    final s = S(ref.read(langProvider));

    // ── Step 1: verify OTP ───────────────────────────────────
    bool success = false;
    if (_currentVerificationId != null) {
      success = await FirebaseService().verifyOtp(_currentVerificationId!, _otp);
    } else {
      await Future.delayed(const Duration(seconds: 1));
      success = true; // dev/test mode
    }

    if (!mounted) {
      return;
    }
    if (!success) {
      setState(() { _loading = false; _error = s.wrongCode; });
      return;
    }

    // ── Step 2: check if account exists ─────────────────────
    bool accountExists = false;
    String? savedPatientId;
    String? savedName;
    String? savedBarangay;
    String? savedHealthCenter;
    String? savedBloodType;
    String? savedRole;
    String? savedCity;
    String? savedRegion;
    String? savedPhone;
    String? savedWorkerName;
    String? savedWorkerPhone;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
        if (snap.exists && snap.value != null) {
          final userData = Map<String, dynamic>.from(snap.value as Map);
          accountExists = true;
          savedPatientId = userData['patientId']?.toString();
          savedName = userData['fullName']?.toString();
          savedRole = userData['role']?.toString();
          if (savedPatientId != null) {
            // Load from correct node based on role
            final node = savedRole == 'worker' ? 'workers' : 'patients';
            final patSnap = await FirebaseDatabase.instance
                .ref('$node/$savedPatientId').get();
            if (patSnap.exists && patSnap.value != null) {
              final d = Map<String, dynamic>.from(patSnap.value as Map);
              savedBarangay     = d['barangay']?.toString();
              savedHealthCenter = d['healthCenter']?.toString() ??
                  d['health_center']?.toString();
              savedBloodType    = d['bloodType']?.toString();
              savedCity         = d['city']?.toString();
              savedRegion       = d['region']?.toString();
              savedPhone        = d['phone']?.toString();
              // Worker-specific fields
              if (savedRole == 'worker') {
                savedWorkerName  = d['fullName']?.toString() ??
                    savedName;
                savedWorkerPhone = d['phone']?.toString();
              }
            }
          }
        }
      }
      // Also check patients node by phone
      if (!accountExists) {
        accountExists = await FirebaseService().patientExists(widget.phoneNumber);
      }
    } catch (e) {
      debugPrint('Firebase check error: $e');
    }

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    // ── Step 3: enforce intent ───────────────────────────────
    if (widget.isRegister && accountExists) {
      setState(() => _error = s.alreadyRegisteredError);
      return;
    }
    if (!widget.isRegister && !accountExists) {
      setState(() => _error = s.noAccountError);
      return;
    }
    // If logging in as worker but registered account is a patient, deny
    if (!widget.isRegister && widget.role == 'worker' && savedRole == 'patient') {
      setState(() => _error = s.isEn
          ? 'This number is registered as a Patient account, not a Worker account.'
          : 'Ang numerong ito ay nakalista bilang Pasyente, hindi Worker.');
      return;
    }
    // If logging in as patient but registered account is a worker, deny
    if (!widget.isRegister && widget.role == 'patient' && savedRole == 'worker') {
      setState(() => _error = s.isEn
          ? 'This number is registered as a Worker account, not a Patient account.'
          : 'Ang numerong ito ay nakalista bilang Worker, hindi Pasyente.');
      return;
    }

    // ── Step 4: navigate ─────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();

    if (accountExists) {
      if (savedPatientId != null) {
        await prefs.setString('user_id', savedPatientId);
        await prefs.setString('patient_id', savedPatientId);
      }
      await prefs.setString('user_role', widget.role);
      await prefs.setString('patient_name', savedName ?? '');
      // Always save firebase_uid so InboxIcon works after re-login
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (firebaseUid.isNotEmpty) {
        await prefs.setString('firebase_uid', firebaseUid);
      }
      if (savedBarangay != null) {
        await prefs.setString('patient_barangay', savedBarangay);
      }
      if (savedHealthCenter != null) {
        await prefs.setString('patient_health_center', savedHealthCenter);
      }
      if (savedBloodType != null) {
        await prefs.setString('patient_blood_type', savedBloodType);
      }
      if (savedCity != null) {
        await prefs.setString('patient_city', savedCity);
      }
      if (savedRegion != null) {
        await prefs.setString('patient_region', savedRegion);
      }
      if (savedPhone != null) {
        await prefs.setString('user_phone', savedPhone);
      }
      if (savedWorkerName != null) {
        await prefs.setString('worker_name', savedWorkerName);
      }
      if (savedWorkerPhone != null) {
        await prefs.setString('worker_phone', savedWorkerPhone);
      }

      if (!mounted) {
        return;
      }
      // Show welcome-back card then navigate
      _showWelcomeBack(
        name: savedName ?? '',
        role: savedRole ?? widget.role,
      );
    } else {
      // New registration — go to step 1, carry role
      if (!mounted) {
        return;
      }
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => RegStep1Screen(role: widget.role)));
    }
  }


  void _showWelcomeBack({required String name, required String role}) {
    final isWorker = role == 'worker';
    final color = isWorker ? const Color(0xFF2563EB) : AppTheme.primary;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(
                isWorker
                    ? Icons.medical_services_rounded
                    : Icons.person_rounded,
                color: color, size: 34),
          ),
          const SizedBox(height: 16),
          Text('Welcome back!',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(name.isNotEmpty ? name : widget.phoneNumber,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
                isWorker ? 'Health Worker' : 'Patient',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (isWorker) {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(
                          builder: (_) => const WorkerShell()),
                      (r) => false);
                } else {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(
                          builder: (_) => const PatientShell()),
                      (r) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 52)),
              child: const Text('Continue',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    final s = S(ref.read(langProvider));
    await FirebaseService().sendOtp(
      widget.phoneNumber,
      (vid) {
        setState(() => _currentVerificationId = vid);
        _startTimer();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.newOtpSent),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating));
      },
      (err) => setState(() => _error = err),
    );
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    final roleColor = widget.role == 'worker'
        ? const Color(0xFF2563EB) : AppTheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppTheme.divider)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Container(width: 56, height: 56,
              decoration: BoxDecoration(color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.sms_rounded, color: AppTheme.primary, size: 28)),
          const SizedBox(height: 20),
          Text(s.verifyNumber,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(s.otpSentTo(widget.phoneNumber),
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 12),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.role == 'worker'
                  ? Icons.medical_services_rounded : Icons.person_rounded,
                  size: 14, color: roleColor),
              const SizedBox(width: 6),
              Text(widget.role == 'worker' ? s.worker : s.patient,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: roleColor)),
            ]),
          ),
          const SizedBox(height: 32),
          PinCodeTextField(
            appContext: context, length: 6,
            onChanged: (v) => setState(() { _otp = v; _error = null; }),
            onCompleted: (_) => _verify(),
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56, fieldWidth: 48,
              activeFillColor: Colors.white,
              selectedFillColor: AppTheme.primaryLight,
              inactiveFillColor: Colors.white,
              activeColor: AppTheme.primary,
              selectedColor: AppTheme.primary,
              inactiveColor: AppTheme.divider),
            enableActiveFill: true,
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          Center(child: _seconds > 0
              ? Text(s.resendIn(_seconds),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))
              : TextButton.icon(onPressed: _resend,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(s.resendOtp))),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: (_loading || _otp.length < 6) ? null : _verify,
            child: _loading
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text(s.verifying),
                  ])
                : Text(s.verify),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

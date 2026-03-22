import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/services/firebase_service.dart';
import 'package:alagahub/screens/auth/otp_verification_screen.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  final String role;
  final bool isRegister;
  const PhoneEntryScreen({
    super.key,
    this.role = 'patient',
    this.isRegister = false,
  });
  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  String _buildPhone() {
    final raw = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.startsWith('0') && raw.length == 11) return '+63${raw.substring(1)}';
    return '+63$raw';
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final phone = _buildPhone();
    String? verificationId;
    String? errorMsg;
    bool completed = false;

    await FirebaseService().sendOtp(
      phone,
      (vid) { verificationId = vid; completed = true; },
      (err) { errorMsg = err; completed = true; },
    );

    int waited = 0;
    while (!completed && waited < 30) {
      await Future.delayed(const Duration(seconds: 1));
      waited++;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (errorMsg != null) {
      setState(() => _error = 'Error: $errorMsg');
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OtpVerificationScreen(
        phoneNumber: phone,
        verificationId: verificationId,
        role: widget.role,
        isRegister: widget.isRegister,
      ),
    ));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
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
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.phone_android_rounded,
                    color: AppTheme.primary, size: 28)),
            const SizedBox(height: 20),
            Text(s.enterMobile, style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary, height: 1.2)),
            const SizedBox(height: 8),
            Text(s.phoneHint, style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 40),

            // Phone field with PH flag
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 2),
              decoration: InputDecoration(
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('\u{1F1F5}\u{1F1ED}',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('+63', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                    Container(width: 1, height: 24, color: AppTheme.divider,
                        margin: const EdgeInsets.symmetric(horizontal: 10)),
                  ]),
                ),
                hintText: '9XX XXX XXXX',
                labelText: s.phoneNumber,
                errorText: _error,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return s.required;
                final d = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (d.length < 10) return 'Invalid number (min 10 digits)';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.primaryDark, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(s.phoneExample,
                    style: const TextStyle(
                        color: AppTheme.primaryDark, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              child: _loading
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text(s.sending),
                    ])
                  : Text(s.sendOtp),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

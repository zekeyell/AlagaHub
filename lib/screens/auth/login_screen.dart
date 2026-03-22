import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/screens/auth/phone_entry_screen.dart';
import 'package:alagahub/screens/patient/patient_shell.dart';
import 'package:alagahub/screens/worker/worker_shell.dart';
import 'package:alagahub/screens/admin/admin_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _pickRole({required bool isRegister}) async {
    final s = S(ref.read(langProvider));
    final role = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _RoleSheet(isRegister: isRegister, s: s),
    );
    if (role == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => PhoneEntryScreen(role: role, isRegister: isRegister)));
  }

  // ⚠️ TEMPORARY — delete before release
  Future<void> _confirmWipeDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.error),
          SizedBox(width: 8),
          Text('Wipe Database',
              style: TextStyle(color: AppTheme.error,
                  fontWeight: FontWeight.w800)),
        ]),
        content: const Text(
            'This will permanently delete ALL data in the Realtime Database '
            '(users, consultations, messages, medicine, bookings).\n\n'
            'This cannot be undone. For testing only.',
            style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Wipe Everything',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await FirebaseDatabase.instance.ref().remove();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Database wiped — all data deleted.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _demoLogin(String role) async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', 'demo_$role');
    await prefs.setString('user_role', role);
    await prefs.setString('user_phone', '+639123456789');
    await prefs.setString('patient_name',
        role == 'patient' ? 'Juan dela Cruz'
        : role == 'worker' ? 'Dr. Maria Santos' : 'Admin User');
    await prefs.setString('patient_id', role == 'worker' ? 'WRK-NCR-2025-00001' : 'RHC-NCR-2025-00001');
    await prefs.setString('patient_barangay', 'Barangay Poblacion');
    await prefs.setString('patient_health_center', 'Poblacion Health Center');
    await prefs.setString('patient_blood_type', 'O+');
    if (!mounted) return;
    setState(() => _loading = false);
    Widget dest = role == 'worker' ? const WorkerShell()
        : role == 'admin' ? const AdminShell() : const PatientShell();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => dest));
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async { _fadeCtrl.reset(); await _fadeCtrl.forward(); },
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            // Top hero section
            Container(
              width: double.infinity,
              height: size.height * 0.38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        'assets/images/logo.png',
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('AlagaHub',
                      style: TextStyle(color: Colors.white, fontSize: 30,
                          fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Healthcare kahit saan',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14)),
                ]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
              child: Column(children: [
                const Align(alignment: Alignment.centerLeft,
                    child: Text('Welcome Back! 👋',
                        style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary))),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft,
                    child: Text(s.loginSubtitle,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary))),
                const SizedBox(height: 28),

                // Login
                ElevatedButton.icon(
                  onPressed: _loading ? null : () => _pickRole(isRegister: false),
                  icon: const Icon(Icons.phone_android_rounded, size: 20),
                  label: Text(s.login),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
                const SizedBox(height: 14),

                // Register
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pickRole(isRegister: true),
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: Text(s.createAccount),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
                const SizedBox(height: 20),

                // Lang toggle
                const Center(child: LangToggle()),
                const SizedBox(height: 28),

                // Divider
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(
                          color: AppTheme.textHint, fontSize: 13))),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),

                // Demo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: AppTheme.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(s.demoAccess, style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent, fontSize: 13)),
                    ]),
                    const SizedBox(height: 4),
                    Text(s.forTestingOnly, style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint)),
                    const SizedBox(height: 14),
                    if (_loading)
                      const CircularProgressIndicator()
                    else
                      IntrinsicHeight(child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DemoBtn(label: s.patient,
                              icon: Icons.person_rounded,
                              color: AppTheme.primary,
                              onTap: () => _demoLogin('patient')),
                          const SizedBox(width: 8),
                          _DemoBtn(label: 'Worker',
                              icon: Icons.medical_services_rounded,
                              color: const Color(0xFF2563EB),
                              onTap: () => _demoLogin('worker')),
                          const SizedBox(width: 8),
                          _DemoBtn(label: s.admin,
                              icon: Icons.admin_panel_settings_rounded,
                              color: const Color(0xFF7C3AED),
                              onTap: () => _demoLogin('admin')),
                        ],
                      )),
                  const SizedBox(height: 12),
                  // ⚠️ TEMPORARY — delete before release
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _confirmWipeDatabase,
                    icon: const Icon(Icons.delete_forever_rounded,
                        color: AppTheme.error, size: 18),
                    label: const Text('Wipe Database',
                        style: TextStyle(color: AppTheme.error,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                  ]),
                ),
                const SizedBox(height: 32),
                Text('AlagaHub v1.0  •  SDG 3 & 10',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                const SizedBox(height: 20),
              ]),
            ),
          ]),
        ),
        ),
      ),
    );
  }
}

class _RoleSheet extends StatefulWidget {
  final bool isRegister;
  final S s;
  const _RoleSheet({required this.isRegister, required this.s});
  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text(widget.isRegister ? s.registerAs : s.loginAs,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(s.chooseRole,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _RoleCard(icon: Icons.person_rounded, label: s.patient,
            subtitle: s.patientSubtitle, color: AppTheme.primary,
            selected: _selected == 'patient',
            onTap: () => setState(() => _selected = 'patient')),
        const SizedBox(height: 12),
        _RoleCard(icon: Icons.medical_services_rounded, label: s.worker,
            subtitle: s.workerSubtitle, color: const Color(0xFF2563EB),
            selected: _selected == 'worker',
            onTap: () => setState(() => _selected = 'worker')),
        const SizedBox(height: 28),
        AnimatedOpacity(
          opacity: _selected != null ? 1 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: _selected == null
                ? null : () => Navigator.pop(context, _selected),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: Text(widget.isRegister ? '${s.proceed} \u2192' : '${s.login} \u2192',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.label,
      required this.subtitle, required this.color,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? color : AppTheme.divider,
            width: selected ? 2 : 1),
        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.12),
            blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 15, color: selected ? color : AppTheme.textPrimary)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12,
              color: AppTheme.textSecondary, height: 1.3)),
        ])),
        Icon(selected ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
            color: selected ? color : AppTheme.textHint, size: 22),
      ]),
    ),
  );
}

class _DemoBtn extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final VoidCallback onTap;
  const _DemoBtn({required this.label, required this.icon,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 5),
        FittedBox(fit: BoxFit.scaleDown,
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: color,
                  fontWeight: FontWeight.w600, fontSize: 11))),
      ]),
    )),
  );
}

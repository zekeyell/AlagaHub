import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/screens/auth/onboarding_screen.dart';
import 'package:alagahub/screens/auth/login_screen.dart';
import 'package:alagahub/screens/admin/admin_shell.dart';
import 'package:alagahub/screens/worker/worker_shell.dart';
import 'package:alagahub/screens/patient/patient_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn);
    _textFade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _scaleCtrl.forward().then((_) => _fadeCtrl.forward());
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;
    final userId = prefs.getString('user_id');
    final role = prefs.getString('user_role') ?? 'patient';
    if (!mounted) return;

    if (userId != null && userId.isNotEmpty) {
      switch (role) {
        case 'worker':
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const WorkerShell()));
          break;
        case 'admin':
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminShell()));
          break;
        default:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const PatientShell()));
      }
    } else if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30, offset: const Offset(0, 12))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/images/logo.png',
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeTransition(
            opacity: _textFade,
            child: Column(children: [
              const Text('AlagaHub',
                  style: TextStyle(color: Colors.white, fontSize: 38,
                      fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(height: 6),
              Text('Healthcare kahit saan',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 72),
          FadeTransition(
            opacity: _textFade,
            child: SizedBox(width: 28, height: 28,
              child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.6),
                  strokeWidth: 2.5)),
          ),
        ]),
      ),
    );
  }
}

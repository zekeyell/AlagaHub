import 'package:flutter/material.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;

  final _slides = const [
    _SlideData(
      icon: Icons.medical_information_rounded,
      iconBg: Color(0xFFD1FAE5),
      iconColor: AppTheme.primary,
      tag: 'HEALTH RECORDS',
      title: 'Track Your\nHealth Anywhere',
      subtitle: 'I-record ang iyong mga sintomas at health history kahit walang internet.',
    ),
    _SlideData(
      icon: Icons.calendar_month_rounded,
      iconBg: Color(0xFFDBEAFE),
      iconColor: Color(0xFF2563EB),
      tag: 'CONSULTATIONS',
      title: 'Schedule\nConsultations Easily',
      subtitle: 'Mag-iskedyul ng konsultasyon sa inyong health center nang walang kahirap-hirap.',
    ),
    _SlideData(
      icon: Icons.medication_rounded,
      iconBg: Color(0xFFFEF3C7),
      iconColor: AppTheme.accent,
      tag: 'MEDICINE',
      title: 'Request Medicine\nAt Your Doorstep',
      subtitle: 'Humingi ng gamot nang hindi kailangang lumayo sa inyong tahanan.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // Skip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              const Spacer(),
              TextButton(
                onPressed: _finish,
                child: Text('Skip',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) {
                setState(() => _page = i);
                _animCtrl.reset();
                _animCtrl.forward();
              },
              itemCount: _slides.length,
              itemBuilder: (_, i) => _SlidePage(
                slide: _slides[i],
                anim: _slideAnim,
                screenSize: size,
              ),
            ),
          ),

          // Dots + button
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) =>
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? AppTheme.primary : AppTheme.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ))),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  key: ValueKey(_page),
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: Text(
                    _page < _slides.length - 1 ? 'Susunod  →' : 'Magsimula',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final Color iconBg, iconColor;
  final String tag, title, subtitle;
  const _SlideData({required this.icon, required this.iconBg,
      required this.iconColor, required this.tag,
      required this.title, required this.subtitle});
}

class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  final Animation<double> anim;
  final Size screenSize;
  const _SlidePage({required this.slide, required this.anim,
      required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
          .animate(anim),
      child: FadeTransition(
        opacity: anim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            // Illustration container
            Container(
              width: screenSize.width * 0.55,
              height: screenSize.width * 0.55,
              decoration: BoxDecoration(
                color: slide.iconBg,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(slide.icon, color: slide.iconColor,
                  size: screenSize.width * 0.28),
            ),
            const SizedBox(height: 40),
            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: slide.iconBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(slide.tag,
                  style: TextStyle(
                      color: slide.iconColor, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 16),
            Text(slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary, height: 1.2)),
            const SizedBox(height: 14),
            Text(slide.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15,
                    color: AppTheme.textSecondary, height: 1.6)),
          ]),
        ),
      ),
    );
  }
}

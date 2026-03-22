import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alagahub/screens/auth/splash_screen.dart';
import 'package:alagahub/screens/auth/onboarding_screen.dart';
import 'package:alagahub/screens/auth/phone_entry_screen.dart';
import 'package:alagahub/screens/auth/otp_verification_screen.dart';
import 'package:alagahub/screens/auth/login_screen.dart';
import 'package:alagahub/screens/auth/registration/reg_step1_screen.dart';
import 'package:alagahub/screens/auth/registration/reg_step2_screen.dart';
import 'package:alagahub/screens/auth/registration/reg_step3_screen.dart';
import 'package:alagahub/screens/auth/registration/reg_step4_screen.dart';
import 'package:alagahub/screens/auth/registration/reg_review_screen.dart';
import 'package:alagahub/screens/patient/patient_shell.dart';
import 'package:alagahub/screens/worker/worker_shell.dart';
import 'package:alagahub/screens/admin/admin_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/auth',
        redirect: (_, __) => '/auth/login',
        routes: [
          GoRoute(path: 'login', builder: (_, __) => const LoginScreen()),
          GoRoute(path: 'phone', builder: (_, __) => const PhoneEntryScreen()),
          GoRoute(
              path: 'otp',
              builder: (_, state) {
                final phone = state.uri.queryParameters['phone'] ?? '';
                return OtpVerificationScreen(phoneNumber: phone);
              }),
          GoRoute(
              path: 'register/1', builder: (_, __) => const RegStep1Screen()),
          GoRoute(
              path: 'register/2', builder: (_, __) => const RegStep2Screen()),
          GoRoute(
              path: 'register/3', builder: (_, __) => const RegStep3Screen()),
          GoRoute(
              path: 'register/4', builder: (_, __) => const RegStep4Screen()),
          GoRoute(
              path: 'register/review',
              builder: (_, __) => const RegReviewScreen()),
        ],
      ),
      GoRoute(path: '/patient/home', builder: (_, __) => const PatientShell()),
      GoRoute(path: '/worker', builder: (_, __) => const WorkerShell()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
    ],
  );
});

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/screens/patient/home_tab.dart';
import 'package:alagahub/screens/patient/consultations_tab.dart';
import 'package:alagahub/screens/patient/medicine_tab.dart';
import 'package:alagahub/screens/patient/messages_tab.dart';
import 'package:alagahub/screens/patient/account_tab.dart';
import 'package:alagahub/widgets/connectivity_banner.dart';

const int kTabHome         = 0;
const int kTabConsultation = 1;
const int kTabMedicine     = 2;
const int kTabMessages     = 3;
const int kTabAccount      = 4;

// Always starts at 0
final patientTabIndexProvider = StateProvider<int>((ref) => 0);

class PatientShell extends ConsumerStatefulWidget {
  const PatientShell({super.key});
  @override
  ConsumerState<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends ConsumerState<PatientShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientTabIndexProvider.notifier).state = kTabHome;
      // Invalidate cached prefs so fresh login data shows correctly
      ref.invalidate(patientPrefsProvider);
    });
    _setPresence(true);
  }

  @override
  void dispose() {
    _setPresence(false);
    super.dispose();
  }

  Future<void> _setPresence(bool online) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final ref = FirebaseDatabase.instance.ref('presence/$uid');
      await ref.update({'online': online, 'lastSeen': DateTime.now().toIso8601String(), 'role': 'patient'});
      if (online) await ref.child('online').onDisconnect().set(false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(patientTabIndexProvider);
    final s = S(ref.watch(langProvider));

    final tabs = [
      const HomeTab(),
      const ConsultationsTab(),
      const MedicineTab(),
      const MessagesTab(),
      const AccountTab(),
    ];

    return Scaffold(
      body: Column(children: [
        const ConnectivityBanner(),
        Expanded(child: tabs[idx]),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => ref.read(patientTabIndexProvider.notifier).state = i,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 11),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_rounded),
              label: s.mgaKonsultasyon),
          BottomNavigationBarItem(
              icon: const Icon(Icons.medication_rounded), label: s.gamot),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_rounded), label: s.mensahe),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Account'),
        ],
      ),
    );
  }
}

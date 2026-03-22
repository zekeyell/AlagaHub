import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/id_generator.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/services/database_service.dart';
import 'package:alagahub/screens/patient/patient_shell.dart';
import 'package:alagahub/widgets/inbox_icon.dart';

final patientPrefsProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name': prefs.getString('patient_name') ?? 'Pasyente',
    'patient_id': prefs.getString('patient_id') ?? '\u2014',
    'barangay': prefs.getString('patient_barangay') ?? '\u2014',
    'health_center': prefs.getString('patient_health_center') ?? '\u2014',
    'blood_type': prefs.getString('patient_blood_type') ?? '\u2014',
  };
});

final healthTipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DatabaseService().getCachedHealthTips();
});

final announcementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DatabaseService().getCachedAnnouncements();
});

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  void _switchTab(WidgetRef ref, int tab) =>
      ref.read(patientTabIndexProvider.notifier).state = tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(patientPrefsProvider);
    final s = S(ref.watch(langProvider));

    return prefsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (prefs) => CustomScrollView(slivers: [
        // ── App Bar ──────────────────────────────────────────────────────
        SliverAppBar(
          floating: true, snap: true, pinned: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, elevation: 0,
          title: Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/images/logo.png',
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                )),
            const SizedBox(width: 10),
            const Text('AlagaHub', style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          ]),
          actions: [
            InboxIcon(userId: prefs['patient_id'] ?? ''),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.divider)),
        ),

        SliverToBoxAdapter(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header greeting + patient card ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${greeting()},',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(prefs['name']!.split(' ').first,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.person_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text('Pasyente',
                          style: TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ])),
                GestureDetector(
                  onTap: () => _switchTab(ref, kTabAccount),
                  child: Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Center(child: Text(
                      prefs['name']!.isNotEmpty
                          ? prefs['name']![0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.w700),
                    )),
                  ),
                ),
              ]),
            ]),
          ),

          // ── Patient ID card floating over header ─────────────────────
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('Patient ID',
                          style: TextStyle(color: AppTheme.primaryDark,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Verified',
                            style: TextStyle(color: AppTheme.primaryDark,
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: prefs['patient_id']!));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Patient ID na-kopya!'),
                        backgroundColor: AppTheme.primaryDark,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ));
                    },
                    child: Row(children: [
                      Text(prefs['patient_id']!,
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5)),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded,
                          size: 14, color: AppTheme.textSecondary),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(children: [
                    _InfoChip(Icons.bloodtype_rounded, prefs['blood_type']!,
                        AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoChip(Icons.location_on_rounded,
                        prefs['barangay']!, AppTheme.primary)),
                  ]),
                ]),
              ),
            ),
          ),

          // ── Quick Actions ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(s.mgaAksyon, style: const TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _ActionTile(
                  icon: Icons.medical_information_rounded,
                  label: s.recordSymptoms,
                  color: AppTheme.primary,
                  bgColor: AppTheme.primaryLight,
                  onTap: () => _switchTab(ref, kTabConsultation),
                ),
                const SizedBox(width: 12),
                _ActionTile(
                  icon: Icons.calendar_month_rounded,
                  label: s.scheduleConsult,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFDBEAFE),
                  onTap: () => _switchTab(ref, kTabConsultation),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _ActionTile(
                  icon: Icons.medication_rounded,
                  label: s.requestMeds,
                  color: AppTheme.accent,
                  bgColor: AppTheme.accentLight,
                  onTap: () => _switchTab(ref, kTabMedicine),
                ),
                const SizedBox(width: 12),
                _ActionTile(
                  icon: Icons.folder_open_rounded,
                  label: s.myRecords,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFEDE9FE),
                  onTap: () => _switchTab(ref, kTabAccount),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 28),

          // ── Health Center Info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Health Center',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    prefs['health_center']!.length > 30
                        ? '${prefs['health_center']!.substring(0, 30)}...'
                        : prefs['health_center']!,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 28),

          // ── Announcements ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text(s.mgaAnunsyo, style: const TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const Spacer(),
              GestureDetector(onTap: () {},
                  child: Text(s.viewAll, style: const TextStyle(
                      fontSize: 13, color: AppTheme.primary,
                      fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _EmptyCard(s.noAnnouncements, Icons.campaign_rounded),
          ),
          const SizedBox(height: 28),

          // ── Health Tips ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(s.healthTips, style: const TextStyle(fontSize: 17,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _EmptyCard(s.noHealthTips, Icons.tips_and_updates_rounded),
          ),
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 12, color: color),
    ),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary)),
  ]);
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bgColor;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
      required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary, fontSize: 13, height: 1.3)),
        ]),
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final String msg;
  final IconData icon;
  const _EmptyCard(this.msg, this.icon);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Center(child: Column(children: [
        Icon(icon, color: AppTheme.textHint, size: 36),
        const SizedBox(height: 10),
        Text(msg, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13)),
      ])));
}

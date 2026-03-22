import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/screens/auth/login_screen.dart';
import 'package:alagahub/widgets/inbox_icon.dart';
import 'package:intl/intl.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/widgets/connectivity_banner.dart';
import 'package:alagahub/services/booking_service.dart';
import 'package:alagahub/widgets/logout_dialog.dart';
import 'package:alagahub/services/database_service.dart';
import 'package:alagahub/services/offline_sync_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────
final workerPatientIdProvider = StateProvider<String>((ref) => '');

// ── Blue palette for worker ──────────────────────────────────────────────
const _blue     = Color(0xFF2563EB);
const _blueDark = Color(0xFF1D4ED8);
const _blueLight = Color(0xFFDBEAFE);
const _blueSoft = Color(0xFFEFF6FF);

// ── Providers ────────────────────────────────────────────────────────────
// Family provider — only shows patients assigned to this specific worker
final workerPatientsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, workerPatientId) async* {
  if (workerPatientId.isEmpty) { yield []; return; }

  // Derive patients directly from consultations — avoids firebase_uid
  // vs patient_id mismatch when looking up /patients node.
  await for (final event in FirebaseDatabase.instance
      .ref('consultations')
      .orderByChild('workerUid')
      .equalTo(workerPatientId)
      .onValue) {
    if (!event.snapshot.exists || event.snapshot.value == null) {
      yield []; continue;
    }
    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    // Build unique patient entries keyed by patient_id
    final Map<String, Map<String, dynamic>> byPatient = {};
    for (final entry in data.entries) {
      final c = Map<String, dynamic>.from(entry.value as Map);
      final pid = (c['patient_id'] ?? c['patientId'] ?? '').toString().trim();
      if (pid.isEmpty) continue;
      final name = (c['patient_name'] ?? c['patientName'] ?? '').toString().trim();
      // Skip offline-sms placeholder entries with no patient name
      if (name.isEmpty && (c['source'] ?? '').toString() == 'offline-sms') continue;
      // Prefer the richest record: update if current entry has a name and stored doesn't
      if (!byPatient.containsKey(pid) ||
          ((byPatient[pid]!['firstName'] as String? ?? '').isEmpty && name.isNotEmpty)) {
        final parts = name.isNotEmpty ? name.split(' ') : [pid];
        byPatient[pid] = {
          'id': pid,
          'patientId': pid,
          'patient_id': pid,
          'firstName': parts.first,
          'lastName': parts.length > 1 ? parts.skip(1).join(' ') : '',
          'barangay': c['barangay'] ?? c['patient_barangay'] ?? '',
          'health_center': c['health_center'] ?? c['healthCenter'] ?? '',
          'registeredAt': c['createdAt'] ?? c['created_at'] ?? '',
        };
      }
    }
    final list = byPatient.values.toList()
      ..sort((a, b) =>
          (b['registeredAt'] ?? '').compareTo(a['registeredAt'] ?? ''));
    yield list;
  }
});

final workerMedicineProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, workerPatientId) {
  if (workerPatientId.isEmpty) return const Stream.empty();
  return FirebaseDatabase.instance
      .ref('medicineRequests')
      .orderByChild('workerUid')
      .equalTo(workerPatientId)
      .onValue
      .map((e) {
    if (!e.snapshot.exists || e.snapshot.value == null) return [];
    final data = Map<String, dynamic>.from(e.snapshot.value as Map);
    return data.entries.map((e2) {
      final v = Map<String, dynamic>.from(e2.value as Map);
      v['firebase_key'] ??= e2.key;
      return v;
    }).toList()
      ..sort((a, b) =>
          (b['createdAt'] ?? b['created_at'] ?? '')
          .compareTo(a['createdAt'] ?? a['created_at'] ?? ''));
  });
});

final workerBookingsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, workerUid) {
  return BookingService().watchWorkerBookings(workerUid);
});

final workerNotifProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, workerUid) {
  return BookingService().watchWorkerNotifications(workerUid);
});

// ══════════════════════════════════════════════════════════════════════════
// Shell
// ══════════════════════════════════════════════════════════════════════════
class WorkerShell extends ConsumerStatefulWidget {
  const WorkerShell({super.key});
  @override
  ConsumerState<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends ConsumerState<WorkerShell> {
  int _tab = 0;
  String _workerPatientId = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final id = p.getString('patient_id') ?? '';
      if (id.isNotEmpty && mounted) {
        setState(() => _workerPatientId = id);
        ref.read(workerPatientIdProvider.notifier).state = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    final wid = _workerPatientId;
    final tabs = [
      _WorkerDashboard(workerPatientId: wid),
      _WorkerPatients(workerPatientId: wid),
      _WorkerBookings(workerPatientId: wid),
      _WorkerMessages(workerPatientId: wid),
      const _WorkerProfile(),
    ];

    return Scaffold(
      body: Column(children: [
        const ConnectivityBanner(),
        Expanded(child: tabs[_tab]),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _blue,
        unselectedItemColor: AppTheme.textHint,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: s.dashboard),
          BottomNavigationBarItem(
              icon: const Icon(Icons.people_rounded),
              label: s.mgaPasyente),
          BottomNavigationBarItem(
              icon: const Icon(Icons.book_online_rounded),
              label: s.isEn ? 'Bookings' : 'Bookings'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_rounded),
              label: s.mensahe),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: s.isEn ? 'Profile' : 'Profile'),
        ],
      ),
    );
  }

  void switchTab(int index) {
    setState(() => _tab = index);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Dashboard
// ══════════════════════════════════════════════════════════════════════════
class _WorkerDashboard extends ConsumerWidget {
  final String workerPatientId;
  const _WorkerDashboard({this.workerPatientId = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S(ref.watch(langProvider));
    final patientsAsync = ref.watch(workerPatientsProvider(workerPatientId));
    final patientCount =
        patientsAsync.whenOrNull(data: (d) => d.length) ?? 0;

    return Scaffold(
      backgroundColor: _blueSoft,
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (_, snap) {
          final name =
              snap.data?.getString('patient_name') ?? 'Health Worker';
          final barangay =
              snap.data?.getString('patient_barangay') ?? 'Barangay';

          return CustomScrollView(slivers: [
            // ── White App Bar (matches patient) ──────────────────────
            SliverAppBar(
              floating: true, snap: true, pinned: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent, elevation: 0,
              title: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      'assets/images/logo.png',
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('AlagaHub', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B))),
              ]),
              actions: [
                InboxIcon(userId: snap.data?.getString('firebase_uid') ?? ''),
                const SizedBox(width: 4),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0xFFE2E8F0)),
              ),
            ),

            // ── Blue gradient greeting header ─────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue, _blueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Greeting
                  Row(children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(s.isEn ? 'Good day,' : 'Kumusta,',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(name, style: const TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min,
                            children: [
                          const Icon(Icons.medical_services_rounded,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(s.isEn ? 'Healthcare Worker' : 'Health Worker',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ])),
                    GestureDetector(
                      onTap: () {
                        context
                            .findAncestorStateOfType<_WorkerShellState>()
                            ?.switchTab(4);
                      },
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2),
                        ),
                        child: Center(child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'W',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 22, fontWeight: FontWeight.w700),
                        )),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(barangay, style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                  ]),
                ]),
              ),
            ),

            // ── Stats card below gradient ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    child: Row(children: [
                      _StatPill(
                        label: s.isEn ? 'Patients' : 'Pasyente',
                        value: '$patientCount',
                        icon: Icons.people_rounded,
                        color: _blue,
                      ),
                      _Divider(),
                      _StatPill(
                        label: 'Pending',
                        value: '—',
                        icon: Icons.pending_rounded,
                        color: AppTheme.accent,
                      ),
                      _Divider(),
                      _StatPill(
                        label: s.mensahe,
                        value: '0',
                        icon: Icons.chat_bubble_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                    ]),
                  ),
              ),
            ),

            // ── Recent consultations ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  Text(s.isEn ? 'Recent Consultations' : 'Mga Kamakailang Konsultasyon',
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const Spacer(),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseDatabase.instance
                      .ref('consultations')
                      .orderByChild('createdAt')
                      .limitToLast(3)
                      .onValue
                      .map((e) {
                        if (!e.snapshot.exists || e.snapshot.value == null) {
                          return <Map<String, dynamic>>[];
                        }
                        final data = Map<String, dynamic>.from(e.snapshot.value as Map);
                        // Load worker's own patientId for filter
                        // (done sync via snap since FutureBuilder already loaded prefs)
                        final wId = snap.data?.getString('patient_id') ?? '';
                        final all = data.entries.map((en) {
                          final v = Map<String, dynamic>.from(en.value as Map);
                          v['id'] ??= en.key;
                          v['case_id'] ??= en.key;
                          return v;
                        }).toList();
                        if (wId.isEmpty) return [];
                        return all.where((v) {
                          final wu = (v['workerUid'] ?? '').toString().trim();
                          return wu == wId;
                        }).toList();
                      }),
                  builder: (_, snap) {
                    final items = (snap.data ?? []).take(3).toList();
                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.divider)),
                        child: Center(child: Column(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 40, color: AppTheme.textHint),
                          const SizedBox(height: 8),
                          Text(s.noConsultations,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary)),
                        ])),
                      );
                    }
                    return Column(children: items.map((c) =>
                        _ConsultationListItem(data: c,
                            onStatusChanged: () {})).toList());
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ]);
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatPill({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 20,
          fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11,
          color: AppTheme.textSecondary)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 50, color: AppTheme.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ══════════════════════════════════════════════════════════════════════════
// Patients
// ══════════════════════════════════════════════════════════════════════════
class _WorkerPatients extends ConsumerStatefulWidget {
  final String workerPatientId;
  const _WorkerPatients({this.workerPatientId = ''});
  @override
  ConsumerState<_WorkerPatients> createState() => _WorkerPatientsState();
}

class _WorkerPatientsState extends ConsumerState<_WorkerPatients> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    final patientsAsync = ref.watch(workerPatientsProvider(widget.workerPatientId));

    return Scaffold(
      backgroundColor: _blueSoft,
      appBar: _BlueAppBar(title: s.mgaPasyente),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: s.searchPatient,
              prefixIcon:
                  const Icon(Icons.search_rounded, color: _blue),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        Expanded(child: patientsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: _blue)),
          error: (e, _) => Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.textHint),
              const SizedBox(height: 12),
              const Text('Permission denied.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                'Please update Firebase Realtime Database rules to allow reads.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Go to Firebase Console > Realtime Database > Rules and set .read to true', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ]),
          )),
          data: (patients) {
            final filtered = _search.isEmpty
                ? patients
                : patients.where((p) =>
                    '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'
                        .toLowerCase()
                        .contains(_search)).toList();
            if (filtered.isEmpty) { return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              const Icon(Icons.people_outline_rounded,
                  size: 56, color: AppTheme.textHint),
              const SizedBox(height: 12),
              Text(s.noPatients,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ])); }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = filtered[i];
                final name =
                    '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'
                        .trim();
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: _blueLight,
                          radius: 22,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _blue, fontSize: 17),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: PresenceBadge(
                              userId: p['patientId'] ?? p['id'] ?? ''),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name.isEmpty ? '(No name)' : name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                          p['patientId'] ?? p['id'] ?? '—',
                          style: const TextStyle(fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontFamily: 'monospace')),
                      if ((p['barangay'] ?? '').isNotEmpty)
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              size: 11, color: AppTheme.textHint),
                          const SizedBox(width: 2),
                          Text(p['barangay'],
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textHint)),
                        ]),
                    ])),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textHint),
                  ]),
                );
              },
            );
          },
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Consultations — clickable, with Accept/Reject/Complete actions
// ══════════════════════════════════════════════════════════════════════════

class _ConsultationTabBody extends ConsumerWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onRefresh;
  const _ConsultationTabBody(
      {required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S(ref.watch(langProvider));
    if (items.isEmpty) { return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.calendar_today_outlined,
          size: 56, color: AppTheme.textHint),
      const SizedBox(height: 12),
      Text(s.noConsultations,
          style: const TextStyle(color: AppTheme.textSecondary)),
    ])); }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(
            child: Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 56, color: AppTheme.textHint),
                const SizedBox(height: 16),
                const Text('No consultations here',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                const Text(
                    'Only consultations assigned to you appear here.\n'
                    'Pull down to refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textHint, height: 1.5)),
              ]),
            )),
          )],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ConsultationListItem(
            data: items[i], onStatusChanged: onRefresh),
      ),
    );
  }
}

class _ConsultationListItem extends ConsumerWidget {
  final Map<String, dynamic> data;
  final VoidCallback onStatusChanged;
  const _ConsultationListItem(
      {required this.data, required this.onStatusChanged});

  Color _statusColor(String status) => switch (status) {
        'Confirmed' => AppTheme.primary,
        'Completed' => const Color(0xFF7C3AED),
        'Cancelled' => AppTheme.error,
        _ => AppTheme.accent,
      };

  void _showDetail(BuildContext context) {
    final status = data['status'] ?? 'Pending';
    final isPending = status == 'Pending';
    final isConfirmed = status == 'Confirmed';
    final isOfflineSms = (data['source'] ?? '').toString() == 'offline-sms';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              Expanded(child: Text('Consultation Details',
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800))),
              if (isOfflineSms)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.sms_rounded, size: 11, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text('Offline SMS', style: TextStyle(
                        fontSize: 10, color: Color(0xFFD97706),
                        fontWeight: FontWeight.w700)),
                  ]),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(
                    color: _statusColor(status), fontSize: 12,
                    fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _DetailRow('Case ID', data['case_id'] ?? '—'),
              _DetailRow('Patient ID', data['patient_id'] ?? '—'),
              _DetailRow('Type', data['type'] ?? '—'),
              _DetailRow('Symptoms', data['symptoms'] ?? '—'),
              _DetailRow('Temperature',
                  '${data['temperature'] ?? '—'}°C'),
              _DetailRow('Pain Level',
                  '${data['pain_level'] ?? '—'}/10'),
              _DetailRow('Duration', data['duration'] ?? '—'),
              if ((data['notes'] ?? '').isNotEmpty)
                _DetailRow('Notes', data['notes']),
              _DetailRow('Preferred Date',
                  data['preferred_date'] ?? '—'),
              _DetailRow('Preferred Time',
                  data['preferred_time'] ?? '—'),
              _DetailRow('Health Center',
                  data['health_center'] ?? '—'),
              const SizedBox(height: 20),

              // Action buttons
              if (isPending) ...[
                SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final id = data['id'] ?? data['case_id'] ?? '';
                      final patId = data['patient_id'] ?? data['patientId'] ?? '';
                      await DatabaseService()
                          .updateConsultationStatus(id, 'Confirmed');
                      try {
                        await FirebaseDatabase.instance
                            .ref("consultations/$id")
                            .update({'status': 'Confirmed'});
                      } catch (e) { debugPrint(e.toString()); }
                      // Write conversation + inbox notifications
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final wName  = prefs.getString('worker_name') ??
                            prefs.getString('patient_name') ?? 'Health Worker';
                        final wPhone = prefs.getString('user_phone') ?? '';
                        final wUid   = prefs.getString('patient_id') ??
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        final patientName = data['patient_name'] ??
                            data['patientName'] ?? patId;
                        final convId = id;
                        final now = DateTime.now().toIso8601String();
                        final db = FirebaseDatabase.instance;
                        // Conversation node
                        await db.ref("conversations/$convId").set({
                          'caseId': convId,
                          'patientId': patId,
                          'patientName': patientName,
                          'workerUid': wUid,
                          'workerName': wName,
                          'workerPhone': wPhone,
                          'type': 'consultation',
                          'status': 'Confirmed',
                          'createdAt': now,
                        });
                        await db.ref("conversations/$convId/messages").push().set({
                          'sender': 'system',
                          'content': 'Consultation confirmed! '
                              'Your health worker: $wName'
                              '${wPhone.isNotEmpty ? " — $wPhone" : ""}.',
                          'sent_at': now, 'is_system': 1,
                        });
                        // Inbox: patient gets notified
                        if (patId.isNotEmpty) {
                          await db.ref("inbox/$patId/$convId").set({
                            'title': 'Consultation Confirmed',
                            'body': "Your health worker $wName has accepted your consultation.",
                            'convId': convId,
                            'type': 'consultation',
                            'read': false,
                            'createdAt': now,
                          });
                        }
                        // Inbox: worker gets a copy
                        if (wUid.isNotEmpty) {
                          await db.ref("inbox/$wUid/$convId").set({
                            'title': 'Consultation Accepted',
                            'body': "You confirmed the consultation for $patientName.",
                            'convId': convId,
                            'type': 'consultation',
                            'read': false,
                            'createdAt': now,
                          });
                        }
                      } catch (e) { debugPrint('Conversation/inbox error: ${e.toString()}'); }
                      if (!sheetCtx.mounted) {
                        return;
                      }
                      Navigator.pop(sheetCtx);
                      onStatusChanged();
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                        const SnackBar(
                          content: Text('Consultation confirmed! Patient notified.'),
                          backgroundColor: AppTheme.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Accept / Confirm'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size(double.infinity, 50)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final id = data['id'] ?? data['case_id'] ?? '';
                      await DatabaseService()
                          .updateConsultationStatus(id, 'Cancelled');
                      try {
                        await FirebaseDatabase.instance
                            .ref("consultations/$id")
                            .update({'status': 'Cancelled'});
                      } catch (e) { debugPrint(e.toString()); }
                      if (!sheetCtx.mounted) return;
                      Navigator.pop(sheetCtx);
                      onStatusChanged();
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                        const SnackBar(
                          content: Text('Consultation cancelled.'),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined,
                        color: AppTheme.error),
                    label: const Text('Reject',
                        style: TextStyle(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        minimumSize: const Size(double.infinity, 50)),
                  ),
                ),
              ],
              if (isConfirmed)
                SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final id = data['id'] ?? data['case_id'] ?? '';
                      await DatabaseService()
                          .updateConsultationStatus(id, 'Completed');
                      try {
                        await FirebaseDatabase.instance
                            .ref("consultations/$id")
                            .update({'status': 'Completed'});
                      } catch (e) { debugPrint(e.toString()); }
                      // ignore: use_build_context_synchronously
                      // ignore: use_build_context_synchronously
                      Navigator.pop(sheetCtx);
                      onStatusChanged();
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                        const SnackBar(
                          content: Text('Marked as completed!'),
                          backgroundColor: Color(0xFF7C3AED),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        minimumSize: const Size(double.infinity, 50)),
                  ),
                ),
              const SizedBox(height: 24),
            ]),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = data['status'] ?? 'Pending';
    final sc = _statusColor(status);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.calendar_month_rounded, color: sc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['case_id'] ?? '—',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
                '${data['type'] ?? '—'} · ${data['patient_id'] ?? '—'}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(data['preferred_date'] ?? '—',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textHint)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(status,
                  style: TextStyle(color: sc, fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 18),
          ]),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120,
          child: Text(label, style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary))),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// Medicine
// ══════════════════════════════════════════════════════════════════════════

class _MedList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(String id, String status)? onAction;
  const _MedList({required this.items, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) { return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.medication_outlined, size: 48, color: AppTheme.textHint),
      const SizedBox(height: 12),
      const Text('No requests', style: TextStyle(color: AppTheme.textSecondary)),
    ])); }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = items[i];
        final status = r['status'] ?? 'Pending';
        final statusColor = status == 'Approved' || status == 'Completed'
            ? AppTheme.primary
            : status == 'Cancelled'
                ? AppTheme.error
                : AppTheme.accent;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.medication_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['medicine_name'] ?? r['medicineName'] ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text("ID: ${r['id'] ?? '—'}",
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary,
                        fontFamily: 'monospace')),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(
                    color: statusColor, fontSize: 11,
                    fontWeight: FontWeight.w700)),
              ),
            ]),
            Text("Patient: ${r['patient_id'] ?? r['patientId'] ?? '—'}",
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            Text("Qty: ${r['quantity']?.toString() ?? '1'}  •  ${r['type'] ?? '—'}",
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            if (onAction != null && status == 'Approved') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onAction!(
                      r['firebase_key'] ?? r['request_id'] ?? r['id'] ?? '',
                      'Completed'),
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      elevation: 0),
                ),
              ),
            ],
            if (onAction != null && status == 'Pending') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onAction!(r['firebase_key'] ?? r['request_id'] ?? r['id'] ?? '', 'Approved'),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Approve Request'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      elevation: 0),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onAction!(r['firebase_key'] ?? r['request_id'] ?? r['id'] ?? '', 'Cancelled'),
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppTheme.error, size: 18),
                  label: const Text('Reject',
                      style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size(double.infinity, 46)),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════
// Bookings -- outer screen with Consultations + Medicine inner tabs
// ══════════════════════════════════════════════════════════════════════
class _WorkerBookings extends ConsumerStatefulWidget {
  final String workerPatientId;
  const _WorkerBookings({this.workerPatientId = ''});
  @override
  ConsumerState<_WorkerBookings> createState() => _WorkerBookingsState();
}

class _WorkerBookingsState extends ConsumerState<_WorkerBookings>
    with SingleTickerProviderStateMixin {
  late TabController _outerTabs;
  List<Map<String, dynamic>> _consultations = [];
  bool _consultLoading = true;


  @override
  void initState() {
    super.initState();
    _outerTabs = TabController(length: 2, vsync: this);
    SharedPreferences.getInstance().then((p) {
      _loadConsultations();
    });
  }

  @override
  void dispose() { _bookingConsultSub?.cancel(); _outerTabs.dispose(); super.dispose(); }

  StreamSubscription<DatabaseEvent>? _bookingConsultSub;

  void _loadConsultations() {
    _bookingConsultSub?.cancel();
    _bookingConsultSub = FirebaseDatabase.instance
        .ref('consultations')
        .onValue
        .listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        if (mounted) setState(() { _consultations = []; _consultLoading = false; });
        return;
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final list = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map);
        v['id'] ??= e.key;
        v['case_id'] ??= e.key;
        return v;
      })
      .where((v) {
        final wid = widget.workerPatientId;
        if (wid.isEmpty) return false;
        final assigned = (v['workerUid'] ?? '').toString().trim();
        return assigned == wid;
      }).toList()
        ..sort((a, b) =>
            (b['createdAt'] ?? b['created_at'] ?? '')
            .compareTo(a['createdAt'] ?? a['created_at'] ?? ''));
      if (mounted) setState(() { _consultations = list; _consultLoading = false; });
    }, onError: (e) {
      debugPrint('Bookings consultation stream error: $e');
      if (mounted) setState(() { _consultLoading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    final medAsync = ref.watch(workerMedicineProvider(widget.workerPatientId));
    final cPending   = _consultations.where((c) {
      final st = (c['status'] ?? '').toString();
      return st == 'Pending' || st.toLowerCase() == 'offline-pending';
    }).toList();
    final cConfirmed = _consultations.where((c) => c['status'] == 'Confirmed').toList();
    final cCompleted = _consultations.where((c) => c['status'] == 'Completed').toList();
    final cCancelled = _consultations.where((c) => c['status'] == 'Cancelled').toList();
    return Scaffold(
      backgroundColor: _blueSoft,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(s.isEn ? 'Bookings' : 'Bookings',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadConsultations();
              ref.invalidate(workerMedicineProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _outerTabs,
          labelColor: _blue,
          indicatorColor: _blue,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(icon: const Icon(Icons.calendar_month_rounded, size: 18),
                text: s.isEn ? 'Consultations' : 'Konsultasyon'),
            Tab(icon: const Icon(Icons.medication_rounded, size: 18),
                text: s.isEn ? 'Medicine' : 'Gamot'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _outerTabs,
        children: [
          _BookingsConsultationPane(
            loading: _consultLoading,
            pending: cPending, confirmed: cConfirmed,
            completed: cCompleted, cancelled: cCancelled,
            onRefresh: _loadConsultations,
          ),
          medAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _blue)),
            error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
            data: (all) {
              final mPending   = all.where((r) => r['status'] == 'Pending').toList();
              final mApproved  = all.where((r) =>
                  r['status'] == 'Approved' || r['status'] == 'Completed').toList();
              final mCancelled = all.where((r) => r['status'] == 'Cancelled').toList();
              return _BookingsMedicinePane(
                pending: mPending, approved: mApproved, cancelled: mCancelled,
                onAction: (id, status) async {
                  try {
                    await FirebaseDatabase.instance
                        .ref('medicineRequests/$id')
                        .update({'status': status});
                  } catch (e) { debugPrint(e.toString()); }
                  ref.invalidate(workerMedicineProvider);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// -- Consultations pane (Pending / Confirmed / Completed / Cancelled) ---------
class _BookingsConsultationPane extends ConsumerStatefulWidget {
  final bool loading;
  final List<Map<String, dynamic>> pending, confirmed, completed, cancelled;
  final VoidCallback onRefresh;
  const _BookingsConsultationPane({
    required this.loading, required this.pending, required this.confirmed,
    required this.completed, required this.cancelled, required this.onRefresh,
  });
  @override
  ConsumerState<_BookingsConsultationPane> createState() =>
      _BookingsConsultationPaneState();
}

class _BookingsConsultationPaneState
    extends ConsumerState<_BookingsConsultationPane>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _showAddOfflineCaseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _OfflineCaseInputSheet(
          workerPatientId: ref.read(workerPatientIdProvider),
          onSaved: widget.onRefresh),
    );
  }
  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    return Stack(children: [
      Column(children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: _blue, indicatorColor: _blue,
            unselectedLabelColor: AppTheme.textSecondary,
            isScrollable: true, tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Pending (${widget.pending.length.toString()})'),
              Tab(text: s.isEn ? 'Confirmed' : 'Kumpirmado'),
              Tab(text: s.isEn ? 'Completed' : 'Tapos'),
              Tab(text: s.isEn ? 'Cancelled' : 'Kanselado'),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _ConsultationTabBody(items: widget.pending,   onRefresh: widget.onRefresh),
          _ConsultationTabBody(items: widget.confirmed, onRefresh: widget.onRefresh),
          _ConsultationTabBody(items: widget.completed, onRefresh: widget.onRefresh),
          _ConsultationTabBody(items: widget.cancelled, onRefresh: widget.onRefresh),
        ])),
      ]),
      // FAB: add offline case from SMS
      Positioned(
        right: 16, bottom: 16,
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFD97706),
          heroTag: 'offline_case_fab',
          icon: const Icon(Icons.sms_rounded, color: Colors.white),
          label: const Text('Add Offline Case',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          onPressed: () => _showAddOfflineCaseSheet(context),
        ),
      ),
    ]);
  }
}

// -- Medicine pane (Pending / Approved / Cancelled) ---------------------------
class _BookingsMedicinePane extends StatefulWidget {
  final List<Map<String, dynamic>> pending, approved, cancelled;
  final Future<void> Function(String id, String status) onAction;
  const _BookingsMedicinePane({
    required this.pending, required this.approved,
    required this.cancelled, required this.onAction,
  });
  @override
  State<_BookingsMedicinePane> createState() => _BookingsMedicinePaneState();
}

class _BookingsMedicinePaneState extends State<_BookingsMedicinePane>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabs,
          labelColor: _blue, indicatorColor: _blue,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: 'Pending (${widget.pending.length.toString()})'),
            const Tab(text: 'Approved'),
            const Tab(text: 'Cancelled'),
          ],
        ),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _MedList(items: widget.pending,   onAction: widget.onAction),
        _MedList(items: widget.approved,  onAction: widget.onAction),
        _MedList(items: widget.cancelled, onAction: null),
      ])),
    ]);
  }
}

// ── Offline Case Input Sheet ──────────────────────────────────────────────
class _OfflineCaseInputSheet extends ConsumerStatefulWidget {
  final String workerPatientId;
  final VoidCallback onSaved;
  const _OfflineCaseInputSheet({
      required this.workerPatientId, required this.onSaved});
  @override
  ConsumerState<_OfflineCaseInputSheet> createState() =>
      _OfflineCaseInputSheetState();
}

class _OfflineCaseInputSheetState
    extends ConsumerState<_OfflineCaseInputSheet> {
  final _caseIdCtrl   = TextEditingController();
  final _patientIdCtrl= TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _barangayCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  String _decision = 'Confirmed';
  bool _saving = false;

  @override
  void dispose() {
    _caseIdCtrl.dispose(); _patientIdCtrl.dispose();
    _nameCtrl.dispose(); _barangayCtrl.dispose();
    _symptomsCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext ctx) async {
    final caseId = _caseIdCtrl.text.trim();
    if (caseId.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Case ID is required.'),
          backgroundColor: AppTheme.error));
      return;
    }
    if (!caseId.startsWith('CASE-') || caseId.length < 10) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Invalid Case ID. Must start with CASE- (copy from patient SMS).'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final workerName = prefs.getString('patient_name') ?? 'Health Worker';
      final workerUid  = widget.workerPatientId.isNotEmpty
          ? widget.workerPatientId
          : prefs.getString('patient_id') ?? '';
      final now = DateTime.now().toIso8601String();
      // Store worker decision in offlineCases/ for patient sync
      await OfflineSyncService().workerSaveOfflineCase(
        caseId:       caseId,
        patientId:    _patientIdCtrl.text.trim(),
        patientName:  _nameCtrl.text.trim(),
        barangay:     _barangayCtrl.text.trim(),
        symptoms:     _symptomsCtrl.text.trim(),
        workerUid:    workerUid,
        workerName:   workerName,
        workerStatus: _decision,
        notes:        _notesCtrl.text.trim(),
      );
      // Write to consultations/ as Pending so it shows in worker pending tab
      await FirebaseDatabase.instance.ref('consultations/$caseId').set({
        'id': caseId,
        'case_id': caseId,
        'patient_id': _patientIdCtrl.text.trim(),
        'patientId': _patientIdCtrl.text.trim(),
        'patient_name': _nameCtrl.text.trim(),
        'patientName': _nameCtrl.text.trim(),
        'barangay': _barangayCtrl.text.trim(),
        'symptoms': _symptomsCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'workerUid': workerUid,
        'workerName': workerName,
        'status': 'Pending',
        'source': 'offline-sms',
        'createdAt': now,
        'created_at': now,
        'synced': 1,
      });
      if (!ctx.mounted) return;
      Navigator.pop(ctx);
      widget.onSaved();
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(
            'Offline case added — $caseId\n'
            'Check your Pending tab to Accept or Reject it.'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)))),
          // Title
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.sms_rounded,
                  color: Color(0xFFD97706), size: 20)),
            const SizedBox(width: 12),
            const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Offline SMS Case',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Enter details from patient SMS',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 20),
          // Case ID (required)
          TextField(
            controller: _caseIdCtrl,
            decoration: InputDecoration(
              labelText: 'Case ID *',
              hintText: 'e.g. CASE-1234567890-001',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.tag_rounded)),
          ),
          const SizedBox(height: 12),
          // Patient ID
          TextField(
            controller: _patientIdCtrl,
            decoration: InputDecoration(
              labelText: 'Patient ID',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.badge_rounded)),
          ),
          const SizedBox(height: 12),
          // Patient name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Patient Name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.person_rounded)),
          ),
          const SizedBox(height: 12),
          // Barangay
          TextField(
            controller: _barangayCtrl,
            decoration: InputDecoration(
              labelText: 'Barangay',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.location_on_rounded)),
          ),
          const SizedBox(height: 12),
          // Symptoms
          TextField(
            controller: _symptomsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Symptoms (from SMS)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.sick_rounded)),
          ),
          const SizedBox(height: 12),
          // Worker notes
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Worker Notes (optional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.note_rounded)),
          ),
          const SizedBox(height: 16),
          // Decision
          Text('Decision', style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _decision = 'Confirmed'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _decision == 'Confirmed'
                      ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _decision == 'Confirmed'
                      ? AppTheme.primary : AppTheme.divider)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.check_circle_rounded, size: 18,
                      color: _decision == 'Confirmed'
                          ? Colors.white : AppTheme.textHint),
                  const SizedBox(width: 6),
                  Text('Accept', style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _decision == 'Confirmed'
                          ? Colors.white : AppTheme.textHint)),
                ]),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _decision = 'Cancelled'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _decision == 'Cancelled'
                      ? AppTheme.error : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _decision == 'Cancelled'
                      ? AppTheme.error : AppTheme.divider)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.cancel_rounded, size: 18,
                      color: _decision == 'Cancelled'
                          ? Colors.white : AppTheme.textHint),
                  const SizedBox(width: 6),
                  Text('Decline', style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _decision == 'Cancelled'
                          ? Colors.white : AppTheme.textHint)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 8),
          // Reminder to send reply SMS
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _decision == 'Confirmed'
                    ? 'Remember to SMS the patient:\n'
                      'ACCEPTED [Case ID] - [your name/number]'
                    : 'Remember to SMS the patient:\n'
                      'REJECTED [Case ID] - [reason]',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFD97706)))),
            ]),
          ),
          const SizedBox(height: 20),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _save(context),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: _decision == 'Confirmed'
                      ? AppTheme.primary : AppTheme.error),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _decision == 'Confirmed'
                          ? 'Save & Accept Case'
                          : 'Save & Decline Case',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}

// Messages - real-time Firebase inbox
// ══════════════════════════════════════════════════════════════════════════
class _WorkerMessages extends ConsumerStatefulWidget {
  final String workerPatientId;
  const _WorkerMessages({this.workerPatientId = ''});
  @override
  ConsumerState<_WorkerMessages> createState() => _WorkerMessagesState();
}

class _WorkerMessagesState extends ConsumerState<_WorkerMessages> {
  Map<String, Map<String, dynamic>> _threads = {};
  String? _openThread;
  List<Map<String, dynamic>> _threadMessages = [];
  final _scrollCtrl = ScrollController();
  final _replyCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenToAllThreads();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  void _listenToAllThreads() {
    // Listen to conversations/ node — threads only created on confirmation
    FirebaseDatabase.instance.ref('conversations').onValue.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        if (mounted) setState(() { _threads = {}; _loading = false; });
        return;
      }
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      final newThreads = <String, Map<String, dynamic>>{};
      final myId = widget.workerPatientId;
      raw.forEach((convId, convData) {
        if (convData is Map) {
          final conv = Map<String, dynamic>.from(convData);
          if (myId.isNotEmpty &&
              (conv['workerUid'] ?? '').toString().trim() != myId) { return; }
          final msgsRaw = conv['messages'];
          final allMsgs = msgsRaw is Map
              ? (msgsRaw.values
                    .map((m) => Map<String, dynamic>.from(m as Map? ?? {}))
                    .toList()
                  ..sort((a, b) => (a['sent_at'] ?? '').compareTo(b['sent_at'] ?? '')))
              : <Map<String, dynamic>>[];
          final latest = allMsgs.isNotEmpty ? allMsgs.last : <String, dynamic>{};
          newThreads[convId] = {
            'convId': convId,
            'patientId': conv['patientId'] ?? '',
            'patientName': conv['patientName'] ?? conv['patientId'] ?? 'Patient',
            'workerName': conv['workerName'] ?? 'Worker',
            'type': conv['type'] ?? 'consultation',
            'latestMessage': latest['content'] ?? '',
            'latestTime': latest['sent_at'] ?? conv['createdAt'] ?? '',
            'allMessages': allMsgs,
          };
        }
      });
      if (mounted) {
        setState(() {
          _threads = newThreads;
          _loading = false;
          if (_openThread != null && newThreads.containsKey(_openThread)) {
            _threadMessages = List<Map<String, dynamic>>
                .from(newThreads[_openThread]!['allMessages'] as List);
            Future.delayed(const Duration(milliseconds: 200), () {
              if (_scrollCtrl.hasClients) {
                _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            });
          }
        });
      }
    });
  }

  Future<void> _sendReply(String convId) async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }
    final msgRef = FirebaseDatabase.instance
        .ref('conversations/$convId/messages').push();
    await msgRef.set({
      'id': msgRef.key,
      'sender': 'worker',
      'content': text,
      'sent_at': DateTime.now().toIso8601String(),
      'is_system': 0,
    });
    _replyCtrl.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    if (_openThread != null) {
      return _buildChat(s);
    }

    return Scaffold(
      backgroundColor: _blueSoft,
      appBar: _BlueAppBar(title: s.mensahe),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _threads.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppTheme.textHint),
                  const SizedBox(height: 12),
                  Text(s.isEn ? 'No messages yet' : 'Wala pang mensahe',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text(s.isEn ? 'Patient messages will appear here.' : 'Makikita dito ang mga mensahe ng mga pasyente.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = _threads.values.toList()[i];
                    String timeStr = '';
                    try { timeStr = DateFormat('MMM d, h:mm a').format(DateTime.parse(t['latestTime'] as String)); } catch (_) {}
                    return GestureDetector(
                      onTap: () => setState(() {
                        _openThread = t['convId'] as String;
                        _threadMessages = List<Map<String, dynamic>>.from(t['allMessages'] as List);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.divider),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Row(children: [
                          CircleAvatar(backgroundColor: _blueLight, radius: 22,
                              child: Text(
                                (t['patientName'] as String).isNotEmpty
                                    ? (t['patientName'] as String)[0].toUpperCase() : 'P',
                                style: const TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 17))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(t['patientName'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: (t['type'] == 'medicine' ? Colors.purple : _blue).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(t['type'] == 'medicine' ? 'Medicine' : 'Consult',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                        color: t['type'] == 'medicine' ? Colors.purple : _blue)),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            Text(t['latestMessage'] as String,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(timeStr, style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
                            const SizedBox(height: 4),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 18),
                          ]),
                        ]),
                      ),
                    );
                  }),
    );
  }

  Widget _buildChat(S s) {
    final thread = _threads[_openThread];
    final name = thread?['patientName'] as String? ?? _openThread ?? 'Patient';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _blue),
          onPressed: () => setState(() { _openThread = null; _threadMessages = []; }),
        ),
        title: Row(children: [
          CircleAvatar(backgroundColor: _blueLight, radius: 16,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: const TextStyle(color: _blue, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(_openThread ?? '', style: const TextStyle(fontSize: 10,
                color: AppTheme.textSecondary, fontFamily: 'monospace')),
          ])),
        ]),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppTheme.divider)),
      ),
      body: Column(children: [
        Expanded(child: _threadMessages.isEmpty
            ? Center(child: Text(s.isEn ? 'No messages' : 'Walang mensahe'))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _threadMessages.length,
                itemBuilder: (_, i) {
                  final m = _threadMessages[i];
                  final isWorker = m['sender'] == 'worker';
                  final isSystem = (m['is_system'] ?? 0) == 1;
                  String time = '';
                  try { time = DateFormat('h:mm a').format(DateTime.parse(m['sent_at'] ?? '')); } catch (_) {}
                  if (isSystem) { return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(20)),
                      child: Text(m['content'] ?? '', textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)))));}
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isWorker ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isWorker) ...[
                          CircleAvatar(backgroundColor: AppTheme.primaryLight, radius: 14,
                              child: const Icon(Icons.person_rounded, size: 14, color: AppTheme.primary)),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: Column(
                          crossAxisAlignment: isWorker ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isWorker ? _blue : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isWorker ? 16 : 4),
                                  bottomRight: Radius.circular(isWorker ? 4 : 16),
                                ),
                                border: isWorker ? null : Border.all(color: AppTheme.divider),
                              ),
                              child: Text(m['content'] ?? '',
                                  style: TextStyle(color: isWorker ? Colors.white : AppTheme.textPrimary,
                                      fontSize: 14, height: 1.4)),
                            ),
                            const SizedBox(height: 2),
                            Text(time, style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
                          ],
                        )),
                      ],
                    ),
                  );
                })),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: _replyCtrl, maxLines: 3, minLines: 1,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: s.isEn ? 'Reply to patient...' : 'Sumagot sa pasyente...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _blue, width: 2)),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendReply(_openThread!),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: _blue, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ])),
        ),
      ]),
    );
  }
}


class _WorkerProfile extends ConsumerStatefulWidget {
  const _WorkerProfile();
  @override
  ConsumerState<_WorkerProfile> createState() => _WorkerProfileState();
}

class _WorkerProfileState extends ConsumerState<_WorkerProfile> {
  Map<String, String> _info = {};
  String? _photoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _info = {
        'name':          p.getString('patient_name')          ?? 'Health Worker',
        'phone':         p.getString('user_phone')            ?? '—',
        'barangay':      p.getString('patient_barangay')      ?? '—',
        'city':          p.getString('patient_city')          ?? '—',
        'health_center': p.getString('patient_health_center') ?? '—',
        'patient_id':    p.getString('patient_id')            ?? '—',
        'firebase_uid':  p.getString('firebase_uid')          ?? '',
      };
      _photoUrl = p.getString('profile_photo_url');
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
    if (picked == null) {
      return;
    }
    setState(() => _uploadingPhoto = true);
    try {
      final uid = _info['firebase_uid'] ?? '';
      final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_url', url);
      try {
        await FirebaseDatabase.instance
            .ref('workers/${_info['patient_id']}')
            .update({'photoUrl': url});
      } catch (_) {}
      if (mounted) setState(() { _photoUrl = url; _uploadingPhoto = false; });
    } catch (e) {
      if (mounted) setState(() => _uploadingPhoto = false);
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo upload failed. Try again.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _editProfile() async {
    final s            = S(ref.read(langProvider));
    final nameCtrl       = TextEditingController(text: _info['name']);
    final phoneCtrl      = TextEditingController(text: _info['phone']);
    final barangayCtrl   = TextEditingController(text: _info['barangay']);
    final cityCtrl       = TextEditingController(text: _info['city']);
    final hcCtrl         = TextEditingController(text: _info['health_center']);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text(s.isEn ? 'Edit Profile' : 'I-edit ang Profile',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _WEditField(ctrl: nameCtrl,
                label: s.isEn ? 'Full Name' : 'Buong Pangalan',
                icon: Icons.person_rounded),
            const SizedBox(height: 12),
            _WEditField(ctrl: phoneCtrl,
                label: s.isEn ? 'Phone' : 'Telepono',
                icon: Icons.phone_rounded,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _WEditField(ctrl: barangayCtrl,
                label: 'Barangay',
                icon: Icons.location_on_rounded),
            const SizedBox(height: 12),
            _WEditField(ctrl: cityCtrl,
                label: s.isEn ? 'City / Municipality' : 'Lungsod / Bayan',
                icon: Icons.location_city_rounded),
            const SizedBox(height: 12),
            _WEditField(ctrl: hcCtrl,
                label: s.isEn ? 'Health Center' : 'Health Center',
                icon: Icons.local_hospital_rounded),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)),
              child: Text(s.isEn ? 'Save' : 'I-save'),
            ),
            const SizedBox(height: 28),
          ]),
        ),
      ),
    );

    if (saved != true) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patient_name',         nameCtrl.text.trim());
    await prefs.setString('user_phone',           phoneCtrl.text.trim());
    await prefs.setString('patient_barangay',     barangayCtrl.text.trim());
    await prefs.setString('patient_city',         cityCtrl.text.trim());
    await prefs.setString('patient_health_center', hcCtrl.text.trim());
    try {
      await FirebaseDatabase.instance
          .ref('workers/${_info['patient_id']}')
          .update({
        'fullName':     nameCtrl.text.trim(),
        'phone':        phoneCtrl.text.trim(),
        'barangay':     barangayCtrl.text.trim(),
        'city':         cityCtrl.text.trim(),
        'healthCenter': hcCtrl.text.trim(),
      });
    } catch (_) {}
    await _load();
    if (mounted) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.isEn
            ? 'Profile updated!' : 'Na-update ang profile!'),
        backgroundColor: _blue,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _logout() async => showLogoutDialog(context, ref);

  Future<void> _deleteAccount() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(width: 56, height: 56,
              decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_rounded,
                  color: AppTheme.error, size: 28)),
          const SizedBox(height: 16),
          const Text('Delete Account?',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
              'This will permanently delete your account and all your data. '
              'This cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(bCtx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Delete Account',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(bCtx, false),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppTheme.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600, fontSize: 16)),
            )),
        ]),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('patient_id') ?? '';
      final firebaseUid = prefs.getString('firebase_uid') ?? '';
      final db = FirebaseDatabase.instance;

      // Delete all data associated with this worker account
      final futures = <Future>[];
      if (patientId.isNotEmpty) {
        futures.addAll([
          db.ref('workers/$patientId').remove(),
          db.ref('presence/$patientId').remove(),
          db.ref('inbox/$patientId').remove(),
          db.ref('conversations').get().then((snap) {
            if (!snap.exists || snap.value == null) return;
            final data = Map<String, dynamic>.from(snap.value as Map);
            data.forEach((key, val) {
              if (val is Map &&
                  (val['workerUid'] ?? '') == patientId) {
                db.ref('conversations/$key').remove();
              }
            });
          }),
        ]);
      }
      if (firebaseUid.isNotEmpty) {
        futures.addAll([
          db.ref('users/$firebaseUid').remove(),
          db.ref('inbox/$firebaseUid').remove(),
          db.ref('presence/$firebaseUid').remove(),
        ]);
      }
      await Future.wait(futures);
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      debugPrint('Delete account error: $e');
    }

    // Sign out: clear prefs + navigate (matching logout_dialog pattern)
    final prefs2 = await SharedPreferences.getInstance();
    await prefs2.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s        = S(ref.watch(langProvider));
    final name     = _info['name'] ?? 'W';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: _blueSoft,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: _blue,
          expandedHeight: 250,
          pinned: true,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: s.isEn ? 'Edit Profile' : 'I-edit',
              onPressed: _editProfile,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_blue, _blueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              color: Colors.white.withValues(alpha: 0.2)),
                          child: ClipOval(
                            child: _uploadingPhoto
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : _photoUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: _photoUrl!,
                                        fit: BoxFit.cover)
                                    : Center(
                                        child: Text(initials,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 30,
                                                fontWeight:
                                                    FontWeight.w800))),
                          ),
                        ),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _blue, width: 2)),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: _blue),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          s.isEn ? 'Healthcare Worker' : 'Health Worker',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),

        SliverList(delegate: SliverChildListDelegate([
          const SizedBox(height: 20),
          // Info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))]),
            child: Column(children: [
              _PRow(Icons.phone_rounded,
                  s.isEn ? 'Phone' : 'Numero', _info['phone'] ?? '—'),
              const Divider(height: 1, indent: 52),
              _PRow(Icons.location_on_rounded,
                  s.barangay, _info['barangay'] ?? '—'),
              const Divider(height: 1, indent: 52),
              _PRow(Icons.location_city_rounded,
                  s.isEn ? 'City' : 'Lungsod', _info['city'] ?? '—'),
              const Divider(height: 1, indent: 52),
              _PRow(Icons.local_hospital_rounded,
                  s.healthCenter, _info['health_center'] ?? '—',
                  maxLines: 2),
            ]),
          ),
          const SizedBox(height: 16),

          // Language toggle card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))]),
            child: Row(children: [
              Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: _blueLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.language_rounded,
                      color: _blue, size: 20)),
              const SizedBox(width: 12),
              Text(s.language,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              const LangToggle(),
            ]),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: Text(s.logout),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52)),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever_rounded,
                  color: AppTheme.error),
              label: const Text('Delete Account',
                  style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }
}

class _WEditField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  const _WEditField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _blue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: _blueSoft,
    ),
  );
}

class _PRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final int maxLines;
  const _PRow(this.icon, this.label, this.value, {this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, color: _blue, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: maxLines, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}


// ── Shared blue app bar ───────────────────────────────────────────────────
class _BlueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _BlueAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    title: Text(title, style: const TextStyle(
        fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    iconTheme: const IconThemeData(color: _blue),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppTheme.divider),
    ),
  );
}

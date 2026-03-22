import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/services/auth_service.dart';
import 'package:alagahub/screens/auth/login_screen.dart';
import 'package:alagahub/widgets/connectivity_banner.dart';

final adminStatsProvider = StreamProvider<Map<String, int>>((ref) {
  // Poll Firebase every 30s for counts across key nodes
  final controller = StreamController<Map<String, int>>();

  Future<void> refresh() async {
    final db = FirebaseDatabase.instance;
    int cnt(DatabaseEvent e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return 0;
      try { return (e.snapshot.value as Map).length; } catch (_) { return 0; }
    }
    try {
      final results = await Future.wait([
        db.ref('patients').once(),
        db.ref('workers').once(),
        db.ref('consultations').once(),
        db.ref('medicineRequests').once(),
      ]);
      if (!controller.isClosed) {
        controller.add({
          'patients':      cnt(results[0]),
          'workers':       cnt(results[1]),
          'consultations': cnt(results[2]),
          'medicine':      cnt(results[3]),
        });
      }
    } catch (e) {
      debugPrint('Admin stats error: $e');
    }
  }

  refresh();
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  ref.onDispose(() { timer.cancel(); controller.close(); });
  return controller.stream;
});


final adminWorkerListProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseDatabase.instance.ref('workers').onValue.map((event) {
    if (!event.snapshot.exists || event.snapshot.value == null) {
      return <Map<String, dynamic>>[];
    }
    try {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        final w = Map<String, dynamic>.from(e.value as Map);
        w['id'] = e.key;
        return w;
      }).toList()
        ..sort((a, b) {
          final aTime = (a['registeredAt'] ?? a['createdAt'] ?? '').toString();
          final bTime = (b['registeredAt'] ?? b['createdAt'] ?? '').toString();
          return bTime.compareTo(aTime);
        });
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  });
});
final adminPatientListProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseDatabase.instance.ref('patients').onValue.map((event) {
    if (!event.snapshot.exists || event.snapshot.value == null) {
      return <Map<String, dynamic>>[];
    }
    try {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        final p = Map<String, dynamic>.from(e.value as Map);
        p['id'] = e.key;
        return p;
      }).toList()
        ..sort((a, b) {
          final aTime = (a['registeredAt'] ?? a['createdAt'] ?? '').toString();
          final bTime = (b['registeredAt'] ?? b['createdAt'] ?? '').toString();
          return bTime.compareTo(aTime);
        });
    } catch (e) {
      debugPrint('Patient list parse error: $e');
      return <Map<String, dynamic>>[];
    }
  }).handleError((e) {
    debugPrint('Patient list stream error: $e');
    return <Map<String, dynamic>>[];
  });
});

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selected = 0;
  final _drawerKey = GlobalKey<ScaffoldState>();

  final _screens = const [
    _AdminDashboard(), _AdminUsers(), _AdminRecords(), _AdminContent(), _AdminExport(),
  ];
  final _items = const [
    _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _DrawerItem(icon: Icons.manage_accounts_rounded, label: 'User Management'),
    _DrawerItem(icon: Icons.folder_open_rounded, label: 'Lahat ng Rekord'),
    _DrawerItem(icon: Icons.article_rounded, label: 'Health Tips & Anunsyo'),
    _DrawerItem(icon: Icons.download_rounded, label: 'I-export ang Data'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      backgroundColor: AppTheme.background,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.menu_rounded),
            onPressed: () => _drawerKey.currentState?.openDrawer()),
        title: Text(_items[_selected].label),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async {
          await ref.read(authServiceProvider).signOut();
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        })],
      ),
      body: Column(children: [
        const ConnectivityBanner(),
        Expanded(child: _screens[_selected]),
      ]),
    );
  }

  Widget _buildDrawer() => Drawer(
    child: Column(children: [
      Container(
        color: AppTheme.primary,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16,
            left: 20, right: 20, bottom: 20),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AlagaHub Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Text('System Administrator', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
      const SizedBox(height: 8),
      ..._items.asMap().entries.map((e) => ListTile(
        leading: Icon(e.value.icon, color: _selected == e.key ? AppTheme.primary : AppTheme.textSecondary),
        title: Text(e.value.label, style: TextStyle(
            color: _selected == e.key ? AppTheme.primary : AppTheme.textPrimary,
            fontWeight: _selected == e.key ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
        selected: _selected == e.key,
        selectedTileColor: AppTheme.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () { setState(() => _selected = e.key); Navigator.pop(context); },
      )),
    ]),
  );
}

class _DrawerItem {
  final IconData icon; final String label;
  const _DrawerItem({required this.icon, required this.label});
}

class _AdminDashboard extends ConsumerWidget {
  const _AdminDashboard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S(ref.watch(langProvider));
    final statsAsync = ref.watch(adminStatsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('System Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Column(children: [
            // Extract counts to avoid escaped-quote issues inside ${}
            Builder(builder: (_) {
              final stats = statsAsync.whenOrNull(data: (d) => d);
              final pCount = '${stats?["patients"] ?? 0}';
              final wCount = '${stats?["workers"] ?? 0}';
              final cCount = '${stats?["consultations"] ?? 0}';
              final mCount = '${stats?["medicine"] ?? 0}';
              return Column(children: [
                Row(children: [
                  Expanded(child: _AdminStatCard(s.totalPatients, pCount, AppTheme.primary, Icons.people_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _AdminStatCard(s.healthcareWorkers, wCount, const Color(0xFF2563EB), Icons.medical_services_rounded)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _AdminStatCard('Consultations', cCount, AppTheme.accent, Icons.calendar_month_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _AdminStatCard('Medicine\nRequests', mCount, const Color(0xFF7C3AED), Icons.medication_rounded)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: _AdminStatCard('Health\nCenters', '—', Color(0xFF059669), Icons.local_hospital_rounded)),
                  const SizedBox(width: 12),
                  const Expanded(child: _AdminStatCard('Offline\nQueue', '—', AppTheme.error, Icons.sync_problem_rounded)),
                ]),
              ]);
            }),
        ]),
      ]),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _AdminStatCard(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    height: 110,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 12),
      Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3)),
    ]),
  );
}

class _AdminUsers extends ConsumerStatefulWidget {
  const _AdminUsers();
  @override
  ConsumerState<_AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends ConsumerState<_AdminUsers> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _search = '';
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(adminPatientListProvider);
    return Column(children: [
      TabBar(controller: _tabs,
          tabs: const [Tab(text: 'Mga Pasyente'), Tab(text: 'Mga Worker'), Tab(text: 'Mga Admin')],
          labelColor: AppTheme.primary, indicatorColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary),
      Expanded(child: TabBarView(controller: _tabs, children: [
        Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Hanapin ang pasyente...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
                  contentPadding: EdgeInsets.symmetric(vertical: 10)),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            )),
          Expanded(child: patientsAsync.when(
            loading: () => const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Naglo-load ng mga pasyente...',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 4),
                Text('Check Firebase Rules if this persists.',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ])),
            error: (e, _) => Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.textHint),
                const SizedBox(height: 12),
                const Text('Permission denied.', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Set Firebase Realtime Database rules to allow admin reads.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            )),
            data: (patients) {
              final filtered = _search.isEmpty ? patients : patients.where((p) =>
                '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.toLowerCase().contains(_search)
                || (p['id'] ?? '').toString().toLowerCase().contains(_search)).toList();
              if (filtered.isEmpty) {
                return const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.people_outline, size: 48, color: AppTheme.textHint),
                  SizedBox(height: 12),
                  Text('Walang mga pasyente', style: TextStyle(color: AppTheme.textSecondary)),
                ]));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final name = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider)),
                    child: Row(children: [
                      CircleAvatar(backgroundColor: AppTheme.primaryLight,
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryDark))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name.isEmpty ? '(No name)' : name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(p['patientId'] ?? p['id'] ?? '—',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace')),
                        Text(p['barangay'] ?? '—',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                      ])),
                    ]),
                  );
                },
              );
            },
          )),
        ]),
        _AdminWorkerList(ref: ref),
        const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.admin_panel_settings_outlined, size: 48, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Walang mga admin', style: TextStyle(color: AppTheme.textSecondary)),
        ])),
      ])),
    ]);
  }
}


class _AdminWorkerList extends StatelessWidget {
  final WidgetRef ref;
  const _AdminWorkerList({required this.ref});

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(adminWorkerListProvider);
    return workersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Error loading workers')),
      data: (workers) {
        if (workers.isEmpty) {
          return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.medical_services_outlined, size: 48, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text('Walang mga worker', style: TextStyle(color: AppTheme.textSecondary)),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final w = workers[i];
            final name = (w['fullName'] as String? ??
                '${w['firstName'] ?? ''} ${w['lastName'] ?? ''}'.trim());
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider)),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8)))),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name.isEmpty ? '(No name)' : name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(w['id'] ?? '—',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace')),
                  Text(w['barangay'] ?? '—',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint)),
                ])),
              ]),
            );
          },
        );
      },
    );
  }
}
class _AdminRecords extends StatelessWidget {
  const _AdminRecords();
  @override
  Widget build(BuildContext context) => const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.folder_open_outlined, size: 56, color: AppTheme.textHint),
    SizedBox(height: 12),
    Text('Walang mga rekord', style: TextStyle(color: AppTheme.textSecondary)),
  ]));
}

class _AdminContent extends StatelessWidget {
  const _AdminContent();
  @override
  Widget build(BuildContext context) => const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.article_outlined, size: 56, color: AppTheme.textHint),
    SizedBox(height: 12),
    Text('Walang mga health tips o anunsyo', style: TextStyle(color: AppTheme.textSecondary)),
  ]));
}

class _AdminExport extends StatelessWidget {
  const _AdminExport();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Mga Pasyente', Icons.people_rounded),
      ('Mga Konsultasyon', Icons.calendar_month_rounded),
      ('Medicine Requests', Icons.medication_rounded),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('I-export ang Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('I-download ang mga rekord bilang CSV file.',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        ...items.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider)),
          child: Row(children: [
            Icon(e.$2, color: AppTheme.primary, size: 24), const SizedBox(width: 12),
            Expanded(child: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600))),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nag-eexport ng ${e.$1}...'))),
              icon: const Icon(Icons.download_rounded, size: 16), label: const Text('CSV'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ]),
        )),
      ]),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/utils/id_generator.dart';
import 'package:alagahub/services/database_service.dart';
import 'package:alagahub/services/booking_service.dart';

// ── Medicine catalogue ─────────────────────────────────────────────────────
// type: 'FREE' = libre, 'PAID' = may bayad (shows price in PHP)
final _medicines = [
  // ── Analgesics / Antipyretics
  {'name': 'Paracetamol', 'generic': 'Paracetamol 500mg', 'category': 'Pain Relief', 'type': 'FREE', 'available': true},
  {'name': 'Ibuprofen', 'generic': 'Ibuprofen 200mg', 'category': 'Pain Relief', 'type': 'FREE', 'available': true},
  {'name': 'Mefenamic Acid', 'generic': 'Mefenamic Acid 500mg', 'category': 'Pain Relief', 'type': 'FREE', 'available': false},
  {'name': 'Aspirin', 'generic': 'Aspirin 325mg', 'category': 'Pain Relief', 'type': 'FREE', 'available': true},

  // ── Antibiotics
  {'name': 'Amoxicillin', 'generic': 'Amoxicillin 500mg', 'category': 'Antibiotic', 'type': 'FREE', 'available': true},
  {'name': 'Cotrimoxazole', 'generic': 'Cotrimoxazole 480mg', 'category': 'Antibiotic', 'type': 'FREE', 'available': true},
  {'name': 'Azithromycin', 'generic': 'Azithromycin 500mg', 'category': 'Antibiotic', 'type': 'PAID', 'price': 45.0, 'available': true},
  {'name': 'Cefalexin', 'generic': 'Cefalexin 500mg', 'category': 'Antibiotic', 'type': 'PAID', 'price': 20.0, 'available': true},

  // ── Hypertension
  {'name': 'Amlodipine', 'generic': 'Amlodipine 5mg', 'category': 'Hypertension', 'type': 'FREE', 'available': true},
  {'name': 'Losartan', 'generic': 'Losartan 50mg', 'category': 'Hypertension', 'type': 'PAID', 'price': 12.0, 'available': true},
  {'name': 'Enalapril', 'generic': 'Enalapril 5mg', 'category': 'Hypertension', 'type': 'FREE', 'available': true},
  {'name': 'Atenolol', 'generic': 'Atenolol 50mg', 'category': 'Hypertension', 'type': 'FREE', 'available': false},

  // ── Diabetes
  {'name': 'Metformin', 'generic': 'Metformin 500mg', 'category': 'Diabetes', 'type': 'FREE', 'available': true},
  {'name': 'Glibenclamide', 'generic': 'Glibenclamide 5mg', 'category': 'Diabetes', 'type': 'FREE', 'available': true},
  {'name': 'Glimepiride', 'generic': 'Glimepiride 2mg', 'category': 'Diabetes', 'type': 'PAID', 'price': 18.0, 'available': true},

  // ── GI / Stomach
  {'name': 'Omeprazole', 'generic': 'Omeprazole 20mg', 'category': 'Stomach', 'type': 'PAID', 'price': 15.0, 'available': true},
  {'name': 'Ranitidine', 'generic': 'Ranitidine 150mg', 'category': 'Stomach', 'type': 'FREE', 'available': true},
  {'name': 'Loperamide', 'generic': 'Loperamide 2mg', 'category': 'Stomach', 'type': 'FREE', 'available': true},
  {'name': 'Domperidone', 'generic': 'Domperidone 10mg', 'category': 'Stomach', 'type': 'PAID', 'price': 8.0, 'available': true},

  // ── Allergy / Respiratory
  {'name': 'Cetirizine', 'generic': 'Cetirizine 10mg', 'category': 'Allergy', 'type': 'PAID', 'price': 8.0, 'available': true},
  {'name': 'Loratadine', 'generic': 'Loratadine 10mg', 'category': 'Allergy', 'type': 'FREE', 'available': true},
  {'name': 'Salbutamol', 'generic': 'Salbutamol 2mg', 'category': 'Respiratory', 'type': 'FREE', 'available': true},
  {'name': 'Budesonide', 'generic': 'Budesonide Inhaler 100mcg', 'category': 'Respiratory', 'type': 'PAID', 'price': 180.0, 'available': true},

  // ── Vitamins / Supplements
  {'name': 'Vitamin C', 'generic': 'Ascorbic Acid 500mg', 'category': 'Vitamins', 'type': 'FREE', 'available': true},
  {'name': 'Vitamin B Complex', 'generic': 'B-Complex (B1+B6+B12)', 'category': 'Vitamins', 'type': 'FREE', 'available': true},
  {'name': 'Zinc Sulfate', 'generic': 'Zinc Sulfate 20mg', 'category': 'Vitamins', 'type': 'FREE', 'available': true},
  {'name': 'Iron + Folic Acid', 'generic': 'Ferrous Sulfate + Folic Acid', 'category': 'Vitamins', 'type': 'FREE', 'available': true},

  // ── Others
  {'name': 'Clofazimil', 'generic': 'Clofazimine 100mg', 'category': 'Others', 'type': 'FREE', 'available': false},
  {'name': 'Betamethasone', 'generic': 'Betamethasone 0.5mg', 'category': 'Others', 'type': 'PAID', 'price': 22.0, 'available': true},
  {'name': 'Dexamethasone', 'generic': 'Dexamethasone 4mg', 'category': 'Others', 'type': 'FREE', 'available': true},
];

class MedicineTab extends ConsumerStatefulWidget {
  const MedicineTab({super.key});
  @override
  ConsumerState<MedicineTab> createState() => _MedicineTabState();
}

class _MedicineTabState extends ConsumerState<MedicineTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
        title: Text(s.isEn ? 'Request Medicine' : 'Humiling ng Gamot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _refreshKey++),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.isEn ? 'New Request' : 'Bagong Hiling'),
            Tab(text: s.isEn ? 'Status' : 'Katayuan'),
            Tab(text: s.isEn ? 'Completed' : 'Natapos'),
            Tab(text: s.isEn ? 'Cancelled' : 'Nakansel'),
          ],
          labelColor: AppTheme.primary,
          indicatorColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _MedicineSearch(onSubmit: () {
          _tabs.animateTo(1);
          setState(() => _refreshKey++);
        }),
        _MyRequests(statusFilter: 'Pending',   refreshKey: _refreshKey),
        _MyRequests(statusFilter: 'Approved',  refreshKey: _refreshKey),
        _MyRequests(statusFilter: 'Cancelled', refreshKey: _refreshKey),
      ]),
    );
  }
}

class _MedicineSearch extends ConsumerStatefulWidget {
  final VoidCallback onSubmit;
  const _MedicineSearch({required this.onSubmit});
  @override
  ConsumerState<_MedicineSearch> createState() => _MedicineSearchState();
}

class _MedicineSearchState extends ConsumerState<_MedicineSearch> {
  String _query = '';
  String _selectedCategory = 'All';
  Map<String, dynamic>? _selected;
  int _qty = 1;

  List<String> get _categories {
    final cats = <String>{'All'};
    for (final m in _medicines) {
      cats.add(m['category'] as String);
    }
    return cats.toList();
  }

  List<Map<String, dynamic>> get _filtered {
    return _medicines.where((m) {
      final matchQ = _query.isEmpty ||
          m['name'].toString().toLowerCase().contains(_query.toLowerCase()) ||
          m['generic'].toString().toLowerCase().contains(_query.toLowerCase());
      final matchCat = _selectedCategory == 'All' ||
          m['category'] == _selectedCategory;
      return matchQ && matchCat;
    }).toList();
  }

  void _submit() async {
    if (_selected == null) {
      return;
    }
    final s = S(ref.read(langProvider));
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getString('patient_id') ?? '';
    final name = prefs.getString('patient_name') ?? '';
    final healthCenter = prefs.getString('patient_health_center') ?? '';
    final price = _selected!['type'] == 'PAID'
        ? (_selected!['price'] as double? ?? 0.0) * _qty : 0.0;
    final pid2 = prefs.getString('patient_id') ?? '';
    final reqId = IdGenerator.requestId(patientId: pid2);
    final reqUuid = IdGenerator.newUuid();
    final now = DateTime.now().toIso8601String();

    final summary = '''[ALAGAHUB MEDICINE REQUEST]
----------------------------
Request ID    : $reqId
Patient name  : $name
Patient ID    : $patientId
Date          : $now
----------------------------
Medicine      : ${_selected!['name']}
Generic       : ${_selected!['generic']}
Category      : ${_selected!['category']}
Quantity      : $_qty
Type          : ${_selected!['type'] == 'FREE' ? (s.isEn ? 'FREE' : 'Libre') : 'PHP ${price.toStringAsFixed(2)}'}
Health center : $healthCenter
----------------------------''';

    final medData = {
      'id': reqUuid,
      'request_id': reqId,
      'patient_id': patientId,
      'patient_name': prefs.getString('patient_name') ?? '',
      'barangay': prefs.getString('patient_barangay') ?? '',
      'patientId': patientId,
      'medicine_name': _selected!['name'],
      'generic_name': _selected!['generic'],
      'quantity': _qty,
      'type': _selected!['type'],
      'price': price,
      'status': 'Pending',
      'created_at': now,
      'createdAt': now,
      'synced': 1,
    };
    // Save to Firebase for worker to see
    try {
      await FirebaseDatabase.instance
          .ref('medicineRequests/$reqId')
          .set(medData);
    } catch (e) { debugPrint('Firebase medicine save error: ${e.toString()}'); }
    try {
      await DatabaseService().insertMedicineRequest({
        'id': reqUuid,
      'request_id': reqId,
        'patient_id': patientId,
      'patient_name': prefs.getString('patient_name') ?? '',
      'barangay': prefs.getString('patient_barangay') ?? '',
        'medicine_name': _selected!['name'],
        'generic_name': _selected!['generic'],
        'quantity': _qty,
        'type': _selected!['type'],
        'price': price,
        'status': 'Pending',
        'created_at': now,
        'synced': 1,
      });
    } catch (e) { debugPrint('SQLite medicine error: ${e.toString()}'); }

    final mBrgy   = prefs.getString('patient_barangay') ?? '';
    final mCity   = prefs.getString('patient_city')     ?? '';
    final mRegion = prefs.getString('patient_region')   ?? '';
    Map<String, dynamic>? mWorker;
    try {
      mWorker = await BookingService().findNearestWorker(
          patientBarangay: mBrgy, patientCity: mCity, patientRegion: mRegion);
    } catch (_) {}
    mWorker ??= await BookingService().findNearestWorkerOffline(
        patientBarangay: mBrgy, patientCity: mCity, patientRegion: mRegion);
    final mWUid   = mWorker?['uid']        ?? '';
    final mWName  = mWorker?['fullName'] ?? mWorker?['full_name'] ?? 'Unassigned';
    final mWPhone = mWorker?['phone'] ?? '';
    if (mWUid.isNotEmpty) {
      try {
        await FirebaseDatabase.instance
            .ref('medicineRequests/$reqId')
            .update({'workerUid': mWUid, 'workerName': mWName, 'workerPhone': mWPhone});
        await FirebaseDatabase.instance
            .ref('workerNotifications/$mWUid')
            .push().set({'bookingId': reqId, 'type': 'medicine',
              'patientName': name, 'patientBarangay': mBrgy,
              'referenceId': reqId, 'status': 'New', 'createdAt': now});
        await FirebaseDatabase.instance
            .ref('messages/$patientId')
            .push().set({'patient_id': patientId, 'sender': 'system',
              'content': 'Medicine request submitted. Assigned: $mWName — Contact: $mWPhone',
              'sent_at': now, 'is_system': 1});
      } catch (_) {}
    }
    if (!mounted) {
      return;
    }
    _showSummary(summary, s);
  }

  void _showSummary(String summary, S s, {String offlineSms = ''}) {
    // Show clean success confirmation bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle bar
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          // Success icon
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: AppTheme.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.medication_rounded,
                color: AppTheme.primary, size: 36)),
          const SizedBox(height: 16),
          Text(s.isEn ? 'Request Submitted!' : 'Na-sumite ang Hiling!',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(s.isEn
              ? 'Your medicine request has been sent to your health center worker.'
              : 'Naipadala na ang iyong hiling ng gamot sa iyong health worker.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, height: 1.5, fontSize: 14)),
          const SizedBox(height: 28),
          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() { _selected = null; _qty = 1; });
                widget.onSubmit();
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(s.isEn ? 'Done' : 'Tapos na',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          if (offlineSms.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () async {
                final encoded = Uri.encodeComponent(offlineSms);
                final smsNum = await SharedPreferences.getInstance()
                    .then((p) => p.getString('health_center_sms') ?? '');
                final uri = Uri.parse('sms:$smsNum?body=$encoded');
                try {
                  await launchUrl(uri);
                } catch (e) {
                  Clipboard.setData(ClipboardData(text: offlineSms));
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(s.isEn
                        ? 'SMS app not available. Booking copied!'
                        : 'Hindi mabuksan ang SMS. Na-kopya ang booking!'),
                    backgroundColor: AppTheme.accent,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              icon: const Icon(Icons.sms_rounded),
              label: Text(s.isEn
                  ? 'Send as SMS (Offline)'
                  : 'Ipadala bilang SMS (Offline)'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),

        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    final filtered = _filtered;

    return Column(children: [
      // Search + filter
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(children: [
          TextField(
            decoration: InputDecoration(
              hintText: s.isEn ? 'Search medicine...' : 'Maghanap ng gamot...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.primary),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (ignored, __) => const SizedBox(width: 8),
              itemBuilder: (ignored, i) {
                final cat = _categories[i];
                final sel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppTheme.primary : AppTheme.divider),
                    ),
                    child: Text(cat, style: TextStyle(
                        color: sel ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
        ]),
      ),

      // Medicine list
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (ignored, __) => const SizedBox(height: 8),
        itemBuilder: (ignored, i) {
          final m = filtered[i];
          final isFree = m['type'] == 'FREE';
          final available = m['available'] as bool;
          final isSelected = _selected == m;

          return GestureDetector(
            onTap: available
                ? () => setState(() => _selected = isSelected ? null : m)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryLight
                    : available ? Colors.white : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.divider,
                    width: isSelected ? 2 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: available
                        ? (isFree
                            ? AppTheme.primaryLight
                            : AppTheme.accentLight)
                        : AppTheme.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication_rounded,
                      color: available
                          ? (isFree ? AppTheme.primary : AppTheme.accent)
                          : AppTheme.textHint,
                      size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(m['name'] as String,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: available
                                ? AppTheme.textPrimary
                                : AppTheme.textHint))),
                    // Price or Free badge
                    if (!available)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.divider,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(s.isEn ? 'Unavailable' : 'Wala',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textHint,
                                fontWeight: FontWeight.w600)),
                      )
                    else if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(s.isEn ? 'FREE' : 'LIBRE',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w700)),
                      )
                    else
                      Text(
                        'PHP ${(m['price'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppTheme.accent),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(m['generic'] as String,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(m['category'] as String,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ])),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primary, size: 22),
              ]),
            ),
          );
        },
      )),

      // Order panel
      if (_selected != null)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.divider)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_selected!['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  _selected!['type'] == 'FREE'
                      ? (s.isEn ? 'Free' : 'Libre')
                      : 'PHP ${((_selected!['price'] as double) * _qty).toStringAsFixed(2)}',
                  style: TextStyle(
                      color: _selected!['type'] == 'FREE'
                          ? AppTheme.primary : AppTheme.accent,
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ]),
              const Spacer(),
              // Qty
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    onPressed: _qty > 1
                        ? () => setState(() => _qty--)
                        : null,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  Text('$_qty', style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    onPressed: () => setState(() => _qty++),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                child: Text(s.isEn ? 'Request' : 'Humiling'),
              ),
            ]),
          ),
        ),
    ]);
  }
}

class _MyRequests extends ConsumerStatefulWidget {
  final String statusFilter;
  final int refreshKey;
  const _MyRequests({this.statusFilter = 'Pending', this.refreshKey = 0});
  @override
  ConsumerState<_MyRequests> createState() => _MyRequestsState();
}

class _MyRequestsState extends ConsumerState<_MyRequests> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_MyRequests old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) {
      _load();
    }
  }

  StreamSubscription<DatabaseEvent>? _medSub;

  @override
  void dispose() {
    _medSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('patient_id') ?? '';
    if (id.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Real-time Firebase stream so status updates (Approved) show immediately
    _medSub?.cancel();
    _medSub = FirebaseDatabase.instance
        .ref('medicineRequests')
        .orderByChild('patient_id')
        .equalTo(id)
        .onValue
        .listen((event) {
      if (!mounted) return;
      List<Map<String, dynamic>> all = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        all = data.entries.map((e) {
          final v = Map<String, dynamic>.from(e.value as Map);
          v['firebase_key'] ??= e.key;
          return v;
        }).toList();
      }
      final filtered = all.where((r) {
        final s = (r['status'] ?? 'Pending').toString();
        if (widget.statusFilter == 'Approved') {
          return s == 'Approved' || s == 'Completed';
        }
        return s == widget.statusFilter;
      }).toList();
      setState(() { _requests = filtered; _loading = false; });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medication_outlined,
                      size: 56, color: AppTheme.textHint),
                  const SizedBox(height: 12),
                  Text(s.noMedicineReqs,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    s.isEn ? 'Pull down to refresh' : 'I-pull pababa para i-refresh',
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (ignored, __) => const SizedBox(height: 8),
        itemBuilder: (ignored, i) => _MedicineRequestCard(
            data: _requests[i], onRefresh: _load),
      ),
    );
  }
}

// ── Clickable medicine request card ─────────────────────────────────────────
class _MedicineRequestCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;
  const _MedicineRequestCard({required this.data, required this.onRefresh});
  @override
  ConsumerState<_MedicineRequestCard> createState() =>
      _MedicineRequestCardState();
}

class _MedicineRequestCardState
    extends ConsumerState<_MedicineRequestCard> {

  Future<void> _openSheet(BuildContext ctx) async {
    final s   = S(ref.read(langProvider));
    final r   = widget.data;
    final id  = r['id']         ?? '';
    final rid = r['request_id'] ?? id;
    int qty   = (r['quantity'] as int?) ?? 1;

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.medication_rounded,
                      color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(r['medicine_name'] ?? '—',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(r['generic_name'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ])),
              ]),
            ),
            const SizedBox(height: 24),
            // Quantity stepper
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(s.isEn ? 'Quantity' : 'Dami',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  _QtyBtn(
                      icon: Icons.remove_rounded,
                      onTap: () { if (qty > 1) setSt(() => qty--); }),
                  const SizedBox(width: 28),
                  Text('$qty',
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 28),
                  _QtyBtn(
                      icon: Icons.add_rounded,
                      onTap: () { if (qty < 30) setSt(() => qty++); }),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final db = await DatabaseService().database;
                    await db.update(
                      'medicine_requests',
                      {'quantity': qty},
                      where: 'id = ? OR request_id = ?',
                      whereArgs: [id, rid],
                    );
                    await FirebaseDatabase.instance
                        .ref('medicineRequests/$rid')
                        .update({'quantity': qty});
                  } catch (e) { debugPrint(e.toString()); }
                  if (ctx2.mounted) {
                    Navigator.pop(ctx2);
                  }
                  widget.onRefresh();
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(s.isEn
                          ? 'Quantity updated!'
                          : 'Na-update ang dami!'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: Text(
                    s.isEn ? 'Save Changes' : 'I-save ang Pagbabago'),
              ),
            ),
            // Cancel button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showModalBottomSheet<bool>(
                    context: ctx2,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24))),
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
                            child: const Icon(Icons.cancel_rounded,
                                color: AppTheme.error, size: 28)),
                        const SizedBox(height: 16),
                        Text(s.isEn ? 'Cancel Request?' : 'Kanselahin ang Hiling?',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(s.isEn ? 'This cannot be undone.'
                            : 'Hindi na ito mababawi.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.textSecondary)),
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
                            child: Text(s.isEn ? 'Yes, Cancel' : 'Oo, Kanselahin',
                                style: const TextStyle(
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
                            child: Text(s.isEn ? 'No' : 'Hindi',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                          )),
                      ]),
                    ),
                  );
                  if (ok != true) {
                    return;
                  }
                  await DatabaseService()
                      .updateMedicineRequestStatus(id, 'Cancelled');
                  try {
                    await FirebaseDatabase.instance
                        .ref('medicineRequests/$rid')
                        .update({'status': 'Cancelled'});
                  } catch (_) {}
                  if (ctx2.mounted) {
                    Navigator.pop(ctx2);
                  }
                  widget.onRefresh();
                },
                icon: const Icon(Icons.cancel_outlined,
                    color: AppTheme.error),
                label: Text(
                  s.isEn ? 'Cancel Request' : 'Kanselahin ang Hiling',
                  style: const TextStyle(color: AppTheme.error),
                ),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    minimumSize: const Size(double.infinity, 50)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s       = S(ref.watch(langProvider));
    final r       = widget.data;
    final status  = r['status'] ?? 'Pending';
    final isPending = status == 'Pending';
    final statusColor = switch (status) {
      'Approved' || 'Completed' => AppTheme.primary,
      'Cancelled' || 'Rejected' => AppTheme.error,
      _ => AppTheme.accent,
    };
    final price = (r['price'] as num?)?.toDouble() ?? 0;
    final priceLabel = r['type'] == 'FREE'
        ? (s.isEn ? 'Free' : 'Libre')
        : 'PHP ${price.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: isPending ? () => _openSheet(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending
                ? AppTheme.primary.withValues(alpha: 0.35)
                : AppTheme.divider,
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.medication_rounded,
                color: statusColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(r['medicine_name'] ?? '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 3),
              Text(
                'Qty: ${r['quantity'] ?? 1}  ·  $priceLabel',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (isPending) ...[
                const SizedBox(height: 4),
                Text(
                  s.isEn
                      ? 'Tap to edit or cancel'
                      : 'I-tap para baguhin o kanselahin',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            if (isPending) ...[
              const SizedBox(height: 6),
              const Icon(Icons.edit_rounded,
                  size: 14, color: AppTheme.primary),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: AppTheme.primary, size: 22),
    ),
  );
}

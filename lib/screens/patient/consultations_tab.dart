import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/services/database_service.dart';
import 'package:alagahub/services/booking_service.dart';
import 'package:alagahub/services/offline_sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ── State ──────────────────────────────────────────────────────────────────
class ConsultationDraft {
  final List<String> symptoms;
  final double temperature;
  final int painLevel;
  final String duration;
  final String notes;
  final String type;
  final DateTime? preferredDate;
  final String preferredTime;
  final String healthCenter;
  const ConsultationDraft({
    this.symptoms = const [],
    this.temperature = 36.5,
    this.painLevel = 1,
    this.duration = '1 araw',
    this.notes = '',
    this.type = '',
    this.preferredDate,
    this.preferredTime = '',
    this.healthCenter = '',
  });
  ConsultationDraft copyWith({List<String>? symptoms, double? temperature,
      int? painLevel, String? duration, String? notes, String? type,
      DateTime? preferredDate, String? preferredTime, String? healthCenter}) =>
      ConsultationDraft(
        symptoms: symptoms ?? this.symptoms,
        temperature: temperature ?? this.temperature,
        painLevel: painLevel ?? this.painLevel,
        duration: duration ?? this.duration,
        notes: notes ?? this.notes,
        type: type ?? this.type,
        preferredDate: preferredDate ?? this.preferredDate,
        preferredTime: preferredTime ?? this.preferredTime,
        healthCenter: healthCenter ?? this.healthCenter,
      );
}

class ConsultationNotifier extends StateNotifier<ConsultationDraft> {
  ConsultationNotifier() : super(const ConsultationDraft());
  void update(ConsultationDraft Function(ConsultationDraft) fn) => state = fn(state);
  void reset() => state = const ConsultationDraft();
}

final consultationDraftProvider =
    StateNotifierProvider<ConsultationNotifier, ConsultationDraft>(
        (ref) => ConsultationNotifier());

final consultationListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, patientId) async {
  // Sync from Firebase first so online submissions always appear
  try {
    final snap = await FirebaseDatabase.instance
        .ref('consultations')
        .get()
        .timeout(const Duration(seconds: 3));
    if (snap.exists && snap.value != null) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      for (final entry in data.entries) {
        final chk = Map<String, dynamic>.from(entry.value as Map? ?? {});
        if ((chk['patient_id'] ?? chk['patientId'] ?? '') != patientId) {
          continue;
        }
        final c = Map<String, dynamic>.from(entry.value as Map);
        final id = c['id'] ?? c['case_id'] ?? entry.key;
        // Skip Firebase records written by the worker (source=offline-sms) —
        // patient will sync their own version via syncPendingOffline()
        if ((c['source'] ?? '').toString() == 'offline-sms') continue;
        // Don't overwrite records that are still offline-pending locally
        try {
          final existing = await DatabaseService().getConsultations(patientId)
              .then((list) => list.where((r) =>
                (r['id'] == id || r['case_id'] == id) &&
                (r['status'] ?? '').toString().toLowerCase().contains('offline')).isNotEmpty);
          if (existing) continue;
          await DatabaseService().insertConsultation({
            'id': id,
            'case_id': c['case_id'] ?? id,
            'patient_id': patientId,
            'symptoms': c['symptoms'] ?? '',
            'temperature': (c['temperature'] as num?)?.toDouble() ?? 36.5,
            'pain_level': (c['pain_level'] ?? c['painLevel'] ?? 1) as int,
            'duration': c['duration'] ?? '',
            'notes': c['notes'] ?? '',
            'type': c['type'] ?? '',
            'preferred_date': c['preferred_date'] ?? '',
            'preferred_time': c['preferred_time'] ?? '',
            'health_center': c['health_center'] ?? c['healthCenter'] ?? '',
            'status': () {
              final raw = (c['status'] ?? 'Pending').toString();
              if (raw.isEmpty) return 'Pending';
              if (raw.contains('-')) return raw; // preserve Offline-Pending etc.
              return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
            }(),
            'created_at': c['created_at'] ?? c['createdAt'] ?? '',
            'synced': 1,
          });
        } catch (_) {} // ConflictAlgorithm.replace handles duplicates
      }
    }
  } catch (_) {} // Offline — fall through to SQLite
  return DatabaseService().getConsultations(patientId);
});

// ── Main Tab ───────────────────────────────────────────────────────────────
class ConsultationsTab extends ConsumerStatefulWidget {
  const ConsultationsTab({super.key});
  @override
  ConsumerState<ConsultationsTab> createState() => _ConsultationsTabState();
}

class _ConsultationsTabState extends ConsumerState<ConsultationsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _patientId = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    SharedPreferences.getInstance().then(
        (p) => setState(() => _patientId = p.getString('patient_id') ?? ''));
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _refresh() => ref.invalidate(consultationListProvider(_patientId));

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(s.mgaKonsultasyon),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.isEn ? 'Pending' : 'Nakabinbin'),
            Tab(text: s.isEn ? 'Confirmed' : 'Kumpirmado'),
            Tab(text: s.isEn ? 'Completed' : 'Tapos na'),
            Tab(text: s.isEn ? 'Cancelled' : 'Nakansel'),
          ],
          labelColor: AppTheme.primary,
          indicatorColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: _patientId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(consultationListProvider(_patientId)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => TabBarView(controller: _tabs, children: [
                _ConsultationList(
                  items: list.where((c) {
                  final st = (c['status'] ?? '').toString();
                  return st == 'Pending' ||
                      st.toLowerCase() == 'offline-pending';
                }).toList(),
                  showActions: true,
                  onRefresh: _refresh,
                ),
                _ConsultationList(
                  items: list.where((c) => c['status'] == 'Confirmed').toList(),
                  showActions: true,
                  onRefresh: _refresh,
                ),
                _ConsultationList(
                  items: list.where((c) => c['status'] == 'Completed').toList(),
                  showActions: false,
                  onRefresh: _refresh,
                ),
                _ConsultationList(
                  items: list.where((c) => c['status'] == 'Cancelled').toList(),
                  showActions: false,
                  onRefresh: _refresh,
                ),
              ]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NewConsultationSheet()));
          _refresh();
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

// ── List ───────────────────────────────────────────────────────────────────
class _ConsultationList extends ConsumerWidget {
  final List<Map<String, dynamic>> items;
  final bool showActions;
  final VoidCallback onRefresh;
  const _ConsultationList(
      {required this.items,
      required this.showActions,
      required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S(ref.watch(langProvider));
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 56, color: AppTheme.textHint),
                  const SizedBox(height: 12),
                  Text(
                    s.isEn ? 'No consultations yet' : 'Wala pang konsultasyon',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15)),
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
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => _ConsultationCard(
            data: items[i], showActions: showActions, onRefresh: onRefresh),
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────
class _ConsultationCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final bool showActions;
  final VoidCallback onRefresh;
  const _ConsultationCard(
      {required this.data,
      required this.showActions,
      required this.onRefresh});

  Color get _statusColor => switch (data['status'] ?? 'Pending') {
        'Confirmed' => AppTheme.primary,
        'Cancelled' => AppTheme.error,
        'Completed' => const Color(0xFF7C3AED),
        'Offline-Pending' => const Color(0xFFD97706),
        _ => AppTheme.accent,
      };

  String _buildSummary() => '''[ALAGAHUB CONSULTATION SUMMARY]
------------------------------
Case ID       : ${data['case_id'] ?? data['id'] ?? '—'}
Status        : ${data['status'] ?? 'Pending'}
Date submitted: ${data['created_at'] ?? '—'}
------------------------------
SYMPTOMS      : ${data['symptoms'] ?? '—'}
Temperature   : ${data['temperature'] ?? '—'}
Pain level    : ${data['pain_level'] ?? '—'}/10
Duration      : ${data['duration'] ?? '—'}
Notes         : ${(data['notes'] ?? '').toString().isEmpty ? '—' : data['notes']}
------------------------------
TYPE          : ${data['type'] ?? '—'}
Preferred date: ${data['preferred_date'] ?? '—'}
Preferred time: ${data['preferred_time'] ?? '—'}
Health center : ${data['health_center'] ?? '—'}
------------------------------''';

  void _showSummary(BuildContext context) {
    final summary = _buildSummary();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('Consultation Summary',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(data['status'] ?? 'Pending',
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider)),
                child: SelectableText(summary,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.6)),
              ),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: summary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Na-kopya! I-paste sa SMS para ipadala.'),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy / Kopyahin para sa SMS'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          )),
        ]),
      ),
    );
  }

  Future<void> _cancelFlow(BuildContext context, bool isEn) async {
    final reasons = isEn ? [
      'No longer needed',
      'I am feeling better',
      'Switching health centers',
      'Have another appointment',
      'Other',
    ] : [
      'Hindi na kailangan',
      'Gumagaling na ako',
      'Magpapalit ng health center',
      'May ibang appointment',
      'Iba pa',
    ];
    String? selected;
    final textCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft,
                child: Text(isEn ? 'Reason for Cancellation' : 'Dahilan ng Pagkansela',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            ...reasons.map((r) => RadioListTile<String>(
              value: r,
              // ignore: deprecated_member_use
              groupValue: selected,
              activeColor: AppTheme.primary,
              title: Text(r, style: const TextStyle(fontSize: 14)),
              // ignore: deprecated_member_use
              onChanged: (v) => setSt(() => selected = v),
            )),
            if (selected == 'Iba pa' || selected == 'Other')
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: TextField(
                  controller: textCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang dahilan...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50)),
                child: Text(isEn ? 'Cancel Consultation' : 'Kanselahin ang Konsultasyon',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final id = data['id'] ?? data['case_id'] ?? '';
      await DatabaseService().updateConsultationStatus(id, 'Cancelled');
      try {
        await FirebaseDatabase.instance
            .ref('consultations/$id')
            .update({'status': 'Cancelled'});
      } catch (e) { debugPrint('Firebase cancel error: \$e'); }
      onRefresh();
      if (context.mounted) {
        // Success dialog
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text(isEn ? 'Consultation\nCancelled!' : 'Nakansel ang\nKonsultasyon!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                const SizedBox(height: 12),
                Text(
                  isEn
                    ? 'Cancellation complete. You can schedule a new consultation anytime.'
                    : 'Naisagawa na ang pagkansela. Maaari kang mag-schedule ng bagong konsultasyon anumang oras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text('OK'),
                  ),
                ),
              ]),
            ),
          ),
        );
      }
    }
  }

  Future<void> _rescheduleFlow(BuildContext context, bool isEn) async {
    final reasons = [
      'May schedule clash',
      'Hindi available sa napiling araw',
      'May aktibidad na hindi maiwasan',
      'Ayaw sabihin',
      'Iba pa',
    ];
    String? selectedReason;
    DateTime? newDate;
    String newTime = 'Anumang oras';
    final textCtrl = TextEditingController();
    final timeOpts = ['Umaga', 'Hapon', 'Anumang oras'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(alignment: Alignment.centerLeft,
                  child: Text(isEn ? 'Reschedule Consultation' : 'I-reschedule ang Konsultasyon',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(alignment: Alignment.centerLeft,
                  child: Text('Dahilan ng pagbabago:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(height: 4),
              ...reasons.map((r) => RadioListTile<String>(
                value: r,
                // ignore: deprecated_member_use
                groupValue: selectedReason,
                activeColor: AppTheme.primary,
                title: Text(r, style: const TextStyle(fontSize: 14)),
                // ignore: deprecated_member_use
                onChanged: (v) => setSt(() => selectedReason = v),
              )),
              if (selectedReason == 'Iba pa')
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: textCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ilagay ang dahilan...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(alignment: Alignment.centerLeft,
                  child: Text('Bagong petsa:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ),
              ),
              // Date picker tile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(
                          const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                          const Duration(days: 60)),
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: AppTheme.primary)),
                        child: child!,
                      ),
                    );
                    if (d != null) setSt(() => newDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        newDate != null
                            ? DateFormat('MMMM d, yyyy').format(newDate!)
                            : isEn ? 'Select new date' : 'Pumili ng bagong petsa',
                        style: TextStyle(
                            color: newDate != null
                                ? AppTheme.textPrimary
                                : AppTheme.textHint,
                            fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
              initialValue: newTime,
                  decoration: const InputDecoration(
                      labelText: 'Bagong oras'),
                  items: timeOpts.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                  // ignore: deprecated_member_use
                  onChanged: (v) => setSt(() => newTime = v ?? 'Anumang oras'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: ElevatedButton(
                  onPressed: (selectedReason == null || newDate == null)
                      ? null
                      : () async {
                          final id = data['id'] ?? data['case_id'] ?? '';
                          await DatabaseService()
                              .updateConsultationStatus(id, 'Pending');
                          final newDateStr = DateFormat('MMMM d, yyyy').format(newDate!);
                          final db = await DatabaseService().database;
                          await db.update(
                            'consultations',
                            {
                              'preferred_date': newDateStr,
                              'preferred_time': newTime,
                              'reschedule_reason': selectedReason == 'Iba pa' || selectedReason == 'Other'
                                  ? textCtrl.text : selectedReason,
                              'updated_at': DateTime.now().toIso8601String(),
                            },
                            where: 'id = ? OR case_id = ?',
                            whereArgs: [id, id],
                          );
                          // Also update Firebase
                          try {
                            await FirebaseDatabase.instance
                                .ref('consultations/$id')
                                .update({
                              'preferred_date': newDateStr,
                              'preferred_time': newTime,
                              'status': 'Pending',
                              'reschedule_reason': selectedReason ?? '',
                            });
                          } catch (e) { debugPrint('Firebase reschedule error: \$e'); }
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          onRefresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Na-reschedule! Bagong petsa na-save.'),
                                backgroundColor: AppTheme.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Reschedule',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = (data['status'] ?? '').toString();
    final isPending = (st == 'Pending' || st == 'Confirmed') &&
        st.toLowerCase() != 'offline-pending';
    final s = S(ref.watch(langProvider));

    return GestureDetector(
      onTap: () => _showSummary(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Center(
                child: Text(
                  (data['type'] ?? 'C').isNotEmpty
                      ? (data['type'] ?? 'C')[0]
                      : 'C',
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['case_id'] ?? '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text('${data['type'] ?? '—'} · ${data['health_center'] ?? '—'}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(data['status'] ?? 'Pending',
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          // Date row
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              data['preferred_date'] != null &&
                      data['preferred_date'].toString().isNotEmpty
                  ? (() {
                      try {
                        return DateFormat('MMM d, yyyy').format(
                            DateTime.parse(data['preferred_date']));
                      } catch (_) {
                        return data['preferred_date'].toString();
                      }
                    })()
                  : '—',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.access_time_rounded,
                size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(data['preferred_time'] ?? '—',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.touch_app_rounded,
                size: 12, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Text(s.isEn ? 'Tap to view summary' : 'I-tap para tingnan',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textHint)),
          ]),

          // Offline-Pending badge + action buttons
          if ((data['status'] ?? '').toString().toLowerCase() == 'offline-pending') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFBBF24))),
              child: Row(children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                const Expanded(child: Text(
                    'Offline — waiting to sync when online',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  final phone = (data['worker_phone'] ?? '').toString();
                  final caseId = data['case_id'] ?? data['id'] ?? '';
                  if (phone.isEmpty) return;
                  final sms = '[ALAGAHUB OFFLINE]\nCase ID: $caseId\n'
                      'Patient: ${data["patient_id"] ?? ""}\n'
                      'Symptoms: ${data["symptoms"] ?? ""}\n'
                      'Date: ${data["preferred_date"] ?? ""}\n'
                      'Time: ${data["preferred_time"] ?? ""}';
                  try {
                    await launchUrl(
                      Uri.parse('sms:$phone?body=${Uri.encodeComponent(sms)}'),
                      mode: LaunchMode.externalApplication);
                  } catch (_) {
                    Clipboard.setData(ClipboardData(text: sms));
                  }
                },
                icon: const Icon(Icons.sms_rounded, size: 16),
                label: const Text('Resend SMS',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: () async {
                  final result =
                      await OfflineSyncService().syncPendingOffline();
                  if (!context.mounted) return;
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result.synced > 0
                        ? 'Synced ${result.synced} record(s)!'
                        : 'Nothing to sync yet.'),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync Now',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
            ]),
          ],
          // Action buttons — only for Pending/Confirmed
          if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () { final en = S(ref.read(langProvider)).isEn; _cancelFlow(context, en); },
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(s.isEn ? 'Cancel' : 'Kanselahin',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () { final en = S(ref.read(langProvider)).isEn; _rescheduleFlow(context, en); },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(s.isEn ? 'Reschedule' : 'I-reschedule',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              )),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── New Consultation Multi-Step ────────────────────────────────────────────
class NewConsultationSheet extends ConsumerStatefulWidget {
  const NewConsultationSheet({super.key});
  @override
  ConsumerState<NewConsultationSheet> createState() =>
      _NewConsultationSheetState();
}

class _NewConsultationSheetState extends ConsumerState<NewConsultationSheet> {
  // Auto-generated case ID for this consultation session
  final String caseId = 'CASE-'
      '${DateTime.now().millisecondsSinceEpoch}'
      '-${DateTime.now().microsecond.toString().padLeft(3, '0')}';

  int _step = 0;
  bool _isCelsius = true;
  final _notesCtrl = TextEditingController();

  // Patient info — loaded in initState, never empty at submit time
  String _patientId = '';
  String _patientName = '';
  String _barangay = '';
  String _city = '';
  String _region = '';
  String _healthCenter = '';
  String _bloodType = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) {
        return;
      }
      setState(() {
        _patientId    = p.getString('patient_id')            ?? '';
        _patientName  = p.getString('patient_name')          ?? '';
        _barangay     = p.getString('patient_barangay')      ?? '';
        _city         = p.getString('patient_city')          ?? '';
        _region       = p.getString('patient_region')        ?? '';
        _healthCenter = p.getString('patient_health_center') ?? '';
        _bloodType    = p.getString('patient_blood_type')    ?? '';
      });
    });
  }

  final _symptomOpts = [
    'Lagnat / Fever', 'Ubo / Cough', 'Sakit ng ulo / Headache',
    'Pananakit ng katawan / Body pain', 'Hilo / Dizziness',
    'Pagsusuka / Vomiting', 'Pagtatae / Diarrhea', 'Iba pa / Others',
  ];
  final _durationOpts = ['1 araw', '2-3 araw', '1 linggo', '2+ linggo'];
  final _timeOpts = [
    '8:00 AM – 9:00 AM',
    '9:00 AM – 10:00 AM',
    '10:00 AM – 11:00 AM',
    '11:00 AM – 12:00 PM',
    '1:00 PM – 2:00 PM',
    '2:00 PM – 3:00 PM',
    '3:00 PM – 4:00 PM',
    '4:00 PM – 5:00 PM',
  ];

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Widget _buildStep1(ConsultationDraft draft) {
    final s = S(ref.read(langProvider));
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.isEn ? 'Step 1: Symptoms' : 'Hakbang 1: Mga Sintomas',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...(_symptomOpts.map((s) => CheckboxListTile(
                title: Text(s, style: const TextStyle(fontSize: 14)),
                value: draft.symptoms.contains(s),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
                // ignore: deprecated_member_use
                onChanged: (v) {
                  final updated = List<String>.from(draft.symptoms);
                  if (v == true) { updated.add(s); } else { updated.remove(s); }
                  ref.read(consultationDraftProvider.notifier)
                      .update((d) => d.copyWith(symptoms: updated));
                },
              ))),
          const SizedBox(height: 16),
          Row(children: [
            Text(s.isEn ? 'Temperature:' : 'Temperatura:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _isCelsius = !_isCelsius),
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_isCelsius ? '°C' : '°F',
                      style: const TextStyle(
                          color: AppTheme.primaryDark, fontWeight: FontWeight.w600))),
            ),
          ]),
          Slider(
            value: draft.temperature,
            min: _isCelsius ? 35.0 : 95.0,
            max: _isCelsius ? 42.0 : 107.6,
            divisions: _isCelsius ? 70 : 126,
            activeColor: AppTheme.primary,
            label: '${draft.temperature.toStringAsFixed(1)}${_isCelsius ? '°C' : '°F'}',
            // ignore: deprecated_member_use
            onChanged: (v) => ref.read(consultationDraftProvider.notifier)
                .update((d) => d.copyWith(temperature: v)),
          ),
          const SizedBox(height: 16),
          Text(s.isEn ? 'Pain Level (1-10):' : 'Antas ng Sakit (1-10):',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(children: [
            Text(_painEmoji(draft.painLevel), style: const TextStyle(fontSize: 24)),
            Expanded(child: Slider(
              value: draft.painLevel.toDouble(), min: 1, max: 10, divisions: 9,
              activeColor: AppTheme.primary, label: draft.painLevel.toString(),
              // ignore: deprecated_member_use
              onChanged: (v) => ref.read(consultationDraftProvider.notifier)
                  .update((d) => d.copyWith(painLevel: v.round())),
            )),
            Text('${draft.painLevel}/10', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
              initialValue: draft.duration.isEmpty ? null : draft.duration,
            decoration: InputDecoration(
                labelText: s.isEn ? 'How long?' : 'Gaano katagal?'),
            items: _durationOpts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            // ignore: deprecated_member_use
            onChanged: (v) => ref.read(consultationDraftProvider.notifier)
                .update((d) => d.copyWith(duration: v ?? '')),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesCtrl,
            decoration: InputDecoration(
                labelText: s.isEn ? 'Additional Notes (optional)' : 'Karagdagang Tala (opsyonal)'),
            maxLines: 3,
            // ignore: deprecated_member_use
            onChanged: (v) => ref.read(consultationDraftProvider.notifier)
                .update((d) => d.copyWith(notes: v)),
          ),
          const SizedBox(height: 24),
        ]));
  }

  String _painEmoji(int level) {
    if (level <= 2) {
      return '😊';
    }
    if (level <= 4) {
      return '😐';
    }
    if (level <= 6) {
      return '😟';
    }
    if (level <= 8) {
      return '😣';
    }
    return '😭';
  }

  Widget _buildStep2(ConsultationDraft draft) {
    final s = S(ref.read(langProvider));
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.isEn ? 'Step 2: Consultation Type' : 'Hakbang 2: Uri ng Konsultasyon',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _TypeCard(
              icon: Icons.local_hospital_rounded, label: 'Clinic Visit',
              sublabel: s.isEn ? 'Go to health center' : 'Pumunta sa health center',
              selected: draft.type == 'Clinic Visit',
              onTap: () => ref.read(consultationDraftProvider.notifier)
                  .update((d) => d.copyWith(type: 'Clinic Visit')),
            )),
            const SizedBox(width: 12),
            Expanded(child: _TypeCard(
              icon: Icons.home_rounded, label: 'Home Visit',
              sublabel: s.isEn ? 'Worker visits your home' : 'Bibisita sa bahay',
              selected: draft.type == 'Home Visit',
              onTap: () => ref.read(consultationDraftProvider.notifier)
                  .update((d) => d.copyWith(type: 'Home Visit')),
            )),
          ]),
          const SizedBox(height: 24),
          Text(s.isEn ? 'Consultation Date:' : 'Petsa ng Konsultasyon:',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (ctx, child) => Theme(
                  data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
                  child: child!,
                ),
              );
              if (d != null) {
              ref.read(consultationDraftProvider.notifier)
                  .update((dr) => dr.copyWith(preferredDate: d));
            }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text(
                  draft.preferredDate != null
                      ? DateFormat('MMMM d, yyyy').format(draft.preferredDate!)
                      : (s.isEn ? 'Select a date' : 'Pumili ng petsa'),
                  style: TextStyle(
                      color: draft.preferredDate != null
                          ? AppTheme.textPrimary : AppTheme.textHint,
                      fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
              initialValue: draft.preferredTime.isEmpty ? null : draft.preferredTime,
            decoration: InputDecoration(
                labelText: s.isEn ? 'Preferred Time Slot' : 'Oras ng Kagustuhan'),
            items: _timeOpts.map((t) =>
                DropdownMenuItem(value: t, child: Text(t))).toList(),
            // ignore: deprecated_member_use
            onChanged: (v) => ref.read(consultationDraftProvider.notifier)
                .update((d) => d.copyWith(preferredTime: v ?? '')),
          ),
          const SizedBox(height: 24),
        ]));
  }

  Widget _buildStep3(ConsultationDraft draft) {
    final s = S(ref.read(langProvider));
    final name         = _patientName.isNotEmpty  ? _patientName  : '—';
    final patientId    = _patientId.isNotEmpty    ? _patientId    : '—';
    final barangay     = _barangay.isNotEmpty     ? _barangay     : '—';
    final healthCenter = _healthCenter.isNotEmpty ? _healthCenter : '—';
    final bloodType    = _bloodType.isNotEmpty    ? _bloodType    : '—';
    // Capture the navigator context BEFORE entering the Builder
    // so popUntil always reaches the real root route.
    final rootContext = context;
    return Builder(
      builder: (context) {

        final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
        final summary = '''[ALAGAHUB PATIENT SUMMARY]
----------------------------
Patient name  : $name
Patient ID    : $patientId
Barangay      : $barangay
Blood type    : $bloodType
----------------------------
CASE ID       : $caseId
Date submitted: $now
----------------------------
SYMPTOMS      : ${draft.symptoms.join(', ')}
Temperature   : ${draft.temperature.toStringAsFixed(1)}°C
Pain level    : ${draft.painLevel}/10
Duration      : ${draft.duration}
Notes         : ${draft.notes.isEmpty ? '—' : draft.notes}
----------------------------
CONSULTATION TYPE : ${draft.type}
Preferred date    : ${draft.preferredDate != null ? DateFormat('MMMM d, yyyy').format(draft.preferredDate!) : '—'}
Preferred time    : ${draft.preferredTime}
Health center     : $healthCenter
----------------------------''';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.isEn ? 'Step 3: Review & Submit' : 'Hakbang 3: I-review at Isumite',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider)),
              child: SelectableText(summary,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, height: 1.6)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  _submitOnline(summary, caseId, draft, patientId, healthCenter),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Isumite Online'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _doOfflineSms(
                  rootContext, summary, caseId, draft, patientId, healthCenter),
              icon: const Icon(Icons.sms_rounded),
              label: const Text('Confirm & Send via SMS (Offline)'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }

  Future<void> _submitOnline(String summary, String caseId,
      ConsultationDraft draft, String patientId, String healthCenter) async {
    final now = DateTime.now().toIso8601String();

    // Refresh worker cache whenever we attempt a submit (best-effort)
    BookingService().refreshWorkerCache();

    // Find nearest worker — try Firebase first, fall back to SQLite
    Map<String, dynamic>? worker;
    final prefs = await SharedPreferences.getInstance();
    final barangay = prefs.getString('patient_barangay') ?? '';
    final city     = prefs.getString('patient_city')     ?? '';
    final region   = prefs.getString('patient_region')   ?? '';
    final isOnline = await _isConnected();
    if (isOnline) {
      worker = await BookingService().findNearestWorker(
        patientBarangay: barangay, patientCity: city, patientRegion: region);
    }
    worker ??= await BookingService().findNearestWorkerOffline(
      patientBarangay: barangay, patientCity: city, patientRegion: region);

    final workerUid   = worker?['uid']   ?? '';
    final workerName  = worker?['fullName'] ?? worker?['full_name'] ?? 'Unassigned';
    final workerPhone = worker?['phone'] ?? '';

    final consultData = {
      'id': caseId,
      'case_id': caseId,
      'patient_id': patientId,
      'patientId': patientId,
      'symptoms': draft.symptoms.join(', '),
      'temperature': draft.temperature,
      'pain_level': draft.painLevel,
      'painLevel': draft.painLevel,
      'duration': draft.duration,
      'notes': draft.notes,
      'type': draft.type,
      'preferred_date': draft.preferredDate != null
          ? DateFormat('MMMM d, yyyy').format(draft.preferredDate!)
          : '',
      'preferred_time': draft.preferredTime,
      'health_center': healthCenter,
      'healthCenter': healthCenter,
      'status': 'Pending',
      'workerUid': workerUid,
      'workerName': workerName,
      'workerPhone': workerPhone,
      'created_at': now,
      'createdAt': now,
      'synced': 1,
    };
    // Save to Firebase Realtime DB (for worker to see)
    try {
      await FirebaseDatabase.instance
          .ref('consultations/$caseId')
          .set(consultData);
    } catch (e) {
      debugPrint('Firebase consultation save error: \$e');
    }
    // Write system message so patient sees the assigned worker
    if (isOnline && workerPhone.isNotEmpty) {
      try {
        await FirebaseDatabase.instance
            .ref('messages/$patientId')
            .push()
            .set({
          'patient_id': patientId,
          'sender': 'system',
          'content': 'Your consultation ($caseId) has been submitted.'
              ' Assigned worker: $workerName'
              ' — Contact: $workerPhone',
          'sent_at': now,
          'is_system': 1,
        });
      } catch (e) { debugPrint('System message error: ${e.toString()}'); }
    }
    // Save locally with only SQLite-compatible fields
    try {
      await DatabaseService().insertConsultation({
        'id': caseId,
        'case_id': caseId,
        'patient_id': patientId,
        'symptoms': draft.symptoms.join(', '),
        'temperature': draft.temperature,
        'pain_level': draft.painLevel,
        'duration': draft.duration,
        'notes': draft.notes,
        'type': draft.type,
        'preferred_date': draft.preferredDate != null
            ? DateFormat('MMMM d, yyyy').format(draft.preferredDate!)
            : '',
        'preferred_time': draft.preferredTime,
        'health_center': healthCenter,
        'status': 'Pending',
        'worker_uid': workerUid,
        'worker_phone': workerPhone,
        'worker_name': workerName,
        'created_at': now,
        'synced': 1,
      });
    } catch (e) {
      debugPrint('SQLite save error: ${e.toString()}');
    }
    if (!mounted) {
      return;
    }
    ref.read(consultationDraftProvider.notifier).reset();
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Offline path: open native SMS to worker if we have their number
    if (!isOnline && workerPhone.isNotEmpty) {
      // Extract date string first — avoids escaped-quote issues inside ${}
      final dateStr = draft.preferredDate != null
          ? DateFormat('MMMM d, yyyy').format(draft.preferredDate!)
          : '—';
      final encoded = Uri.encodeComponent(
          '[ALAGAHUB OFFLINE]\nCase ID: $caseId'
          '\nPatient: $patientId'
          '\nSymptoms: ${draft.symptoms.join(', ')}'
          '\nDate: $dateStr'
          '\nTime: ${draft.preferredTime}');
      try {
        await launchUrl(Uri.parse('sms:$workerPhone?body=$encoded'),
            mode: LaunchMode.externalApplication);
      } catch (_) {
        Clipboard.setData(ClipboardData(text: summary));
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(workerPhone.isNotEmpty
          ? 'Submitted! Worker: $workerName ($workerPhone)'
          : 'Consultation submitted! Case ID: $caseId'),
      backgroundColor: AppTheme.primary,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Offline SMS: look up worker from SQLite cache (already populated),
  // pre-fill their number in the SMS app, copy body to clipboard.
  void _doOfflineSms(BuildContext ctx, String summary, String caseId,
      ConsultationDraft draft, String patientId, String healthCenter) {
    final dateStr = draft.preferredDate != null
        ? DateFormat('MMMM d, yyyy').format(draft.preferredDate!) : '—';
    final now = DateTime.now().toIso8601String();

    // Build SMS body from in-memory data — no network calls
    final smsBody =
        '[ALAGAHUB OFFLINE CONSULTATION]\n'
        'Case ID  : $caseId\n'
        'Patient  : $patientId\n'
        'Barangay : $_barangay\n'
        'Symptoms : ${draft.symptoms.join(', ')}\n'
        'Temp     : ${draft.temperature.toStringAsFixed(1)}C\n'
        'Pain     : ${draft.painLevel}/10\n'
        'Date     : $dateStr\n'
        'Time     : ${draft.preferredTime}\n'
        'Type     : ${draft.type}\n'
        '---\n'
        'Reply ACCEPT $caseId to confirm\n'
        'Reply REJECT $caseId to decline';

    // 1. Save locally (fire-and-forget)
    DatabaseService().insertConsultation({
      'id': caseId,
      'case_id': caseId,
      'patient_id': patientId,
      'symptoms': draft.symptoms.join(', '),
      'temperature': draft.temperature,
      'pain_level': draft.painLevel,
      'duration': draft.duration,
      'notes': draft.notes,
      'type': draft.type,
      'preferred_date': dateStr,
      'preferred_time': draft.preferredTime,
      'health_center': healthCenter,
      'status': 'Offline-Pending',
      'created_at': now,
      'synced': 0,
      'offline_source': 1,
    }).catchError((e) { debugPrint('Offline save: $e'); return 0; });

    // 2. Copy SMS body to clipboard
    Clipboard.setData(ClipboardData(text: smsBody));

    // 3. Reset draft and pop to root
    ref.read(consultationDraftProvider.notifier).reset();
    Navigator.of(ctx).popUntil((route) => route.isFirst);

    // 4. Look up worker phone from SQLite cache, then open SMS app.
    //    SQLite is synchronous-friendly via then(); UI has already popped.
    DatabaseService().findNearestWorkerOffline(
      barangay: _barangay,
      city: _city,
      region: _region,
    ).then((worker) {
      final phone = (worker?['phone'] ?? '').toString().trim();
      final workerName = (worker?['full_name'] ?? worker?['fullName'] ?? '').toString();
      // Save worker info back to the local record
      if (phone.isNotEmpty) {
        DatabaseService().database.then((db) => db.update(
          'consultations',
          {'worker_phone': phone, 'worker_name': workerName},
          where: 'case_id = ?', whereArgs: [caseId],
        ));
      }
      // Open SMS app — with number if found, without if not
      final uri = phone.isNotEmpty
          ? Uri.parse('sms:$phone?body=${Uri.encodeComponent(smsBody)}')
          : Uri.parse('sms:');
      launchUrl(uri, mode: LaunchMode.externalApplication)
          .catchError((_) => false);
    }).catchError((_) {
      // Cache lookup failed — open SMS app without number
      launchUrl(Uri.parse('sms:'),
          mode: LaunchMode.externalApplication).catchError((_) => false);
      return null;
    });

    // 5. Snackbar
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text(
          'Booking saved offline!\n'
          'Opening SMS to your health worker...'),
      duration: Duration(seconds: 4),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<bool> _isConnected() async {
    try {
      final r = await Connectivity().checkConnectivity();
      return !r.contains(ConnectivityResult.none);
    } catch (_) { return false; }
  }


  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(consultationDraftProvider);
    final s = S(ref.watch(langProvider));
    final steps = s.isEn
        ? ['Symptoms', 'Schedule', 'Review']
        : ['Sintomas', 'Iskedyul', 'I-review'];
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context)),
        title: Text((s.isEn ? 'New Consultation · ' : 'Bagong Konsultasyon · ')
            + steps[_step]),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
                value: (_step + 1) / 3,
                color: AppTheme.primary,
                backgroundColor: AppTheme.divider)),
      ),
      body: IndexedStack(index: _step, children: [
        _buildStep1(draft),
        _buildStep2(draft),
        _buildStep3(draft),
      ]),
      bottomNavigationBar: SafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(children: [
          if (_step > 0) ...[
            Expanded(
                child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: Text(s.isEn ? 'Back' : 'Bumalik'))),
            const SizedBox(width: 12),
          ],
          if (_step < 2)
            Expanded(
                child: ElevatedButton(
                    onPressed: () => setState(() => _step++),
                    child: Text(s.isEn ? 'Next →' : 'Susunod →'))),
        ]),
      )),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard(
      {required this.icon, required this.label, required this.sublabel,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.divider,
                width: selected ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primary : AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
      );
}

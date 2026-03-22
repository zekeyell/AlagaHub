import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagesTab extends ConsumerStatefulWidget {
  const MessagesTab({super.key});
  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  String _patientId = '';
  String _patientName = '';
  Map<String, Map<String, dynamic>> _threads = {};
  String? _openConvId;
  List<Map<String, dynamic>> _threadMessages = [];
  bool _loading = true;
  StreamSubscription<DatabaseEvent>? _convSub;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _convSub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _patientId = prefs.getString('patient_id') ?? '';
    _patientName = prefs.getString('patient_name') ?? 'Patient';
    if (_patientId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _listenConversations();
  }

  void _listenConversations() {
    // Listen to all conversations, filter client-side by patientId
    _convSub = FirebaseDatabase.instance
        .ref('conversations')
        .onValue
        .listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        if (mounted) setState(() { _threads = {}; _loading = false; });
        return;
      }
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      final newThreads = <String, Map<String, dynamic>>{};
      raw.forEach((convId, convData) {
        if (convData is! Map) return;
        final conv = Map<String, dynamic>.from(convData);
        if ((conv['patientId'] ?? '') != _patientId) return; // only mine
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
          'workerName': conv['workerName'] ?? 'Health Worker',
          'workerPhone': conv['workerPhone'] ?? '',
          'type': conv['type'] ?? 'consultation',
          'latestMessage': latest['content'] ?? '',
          'latestTime': latest['sent_at'] ?? conv['createdAt'] ?? '',
          'allMessages': allMsgs,
        };
      });
      if (mounted) {
        setState(() {
          _threads = newThreads;
          _loading = false;
          if (_openConvId != null && newThreads.containsKey(_openConvId)) {
            _threadMessages = List<Map<String, dynamic>>
                .from(newThreads[_openConvId]!['allMessages'] as List);
            Future.delayed(const Duration(milliseconds: 200), () {
              if (_scrollCtrl.hasClients) {
                _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut);
              }
            });
          }
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _openConvId == null) return;
    final msgRef = FirebaseDatabase.instance
        .ref('conversations/$_openConvId/messages')
        .push();
    await msgRef.set({
      'id': msgRef.key,
      'sender': 'patient',
      'senderName': _patientName,
      'content': text,
      'sent_at': DateTime.now().toIso8601String(),
      'is_system': 0,
    });
    _inputCtrl.clear();
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
    if (_openConvId != null) return _buildChat(s);
    return _buildList(s);
  }

  Widget _buildList(S s) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(s.mensahe,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _threads.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 56, color: AppTheme.textHint),
                    const SizedBox(height: 16),
                    Text(
                      s.isEn
                          ? 'No conversations yet'
                          : 'Wala pang mga usapan',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.isEn
                          ? 'Once a worker confirms your booking,\nyour conversation will appear here.'
                          : 'Kapag na-confirm ng worker ang iyong booking,\nlalabas dito ang inyong usapan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = _threads.values.toList()[i];
                    final convId = t['convId'] as String;
                    String timeStr = '';
                    try {
                      timeStr = DateFormat('MMM d, h:mm a')
                          .format(DateTime.parse(t['latestTime'] as String));
                    } catch (_) {}
                    final workerName = t['workerName'] as String;
                    final isMed = t['type'] == 'medicine';
                    return GestureDetector(
                      onTap: () => setState(() {
                        _openConvId = convId;
                        _threadMessages = List<Map<String, dynamic>>
                            .from(t['allMessages'] as List);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(14),
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
                        child: Row(children: [
                          CircleAvatar(
                              backgroundColor: AppTheme.primaryLight,
                              radius: 22,
                              child: Icon(
                                  isMed
                                      ? Icons.medication_rounded
                                      : Icons.local_hospital_rounded,
                                  color: AppTheme.primary,
                                  size: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(workerName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: (isMed
                                                ? Colors.purple
                                                : AppTheme.primary)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    child: Text(
                                        isMed ? 'Medicine' : 'Consult',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: isMed
                                                ? Colors.purple
                                                : AppTheme.primary)),
                                  ),
                                ]),
                                const SizedBox(height: 2),
                                Text(t['latestMessage'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                              ])),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(timeStr,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textHint)),
                                const SizedBox(height: 4),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppTheme.textHint, size: 18),
                              ]),
                        ]),
                      ),
                    );
                  }),
    );
  }

  Widget _buildChat(S s) {
    final thread = _threads[_openConvId];
    final workerName = thread?['workerName'] as String? ?? 'Health Worker';
    final workerPhone = thread?['workerPhone'] as String? ?? '';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.primary),
          onPressed: () =>
              setState(() { _openConvId = null; _threadMessages = []; }),
        ),
        title: Row(children: [
          CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              radius: 16,
              child: const Icon(Icons.local_hospital_rounded,
                  color: AppTheme.primary, size: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(workerName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (workerPhone.isNotEmpty) ...[
                  Text(workerPhone,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace')),
                ],
              ])),
        ]),
        actions: [
          if (workerPhone.isNotEmpty)
            IconButton(
              tooltip: 'Open SMS',
              icon: const Icon(Icons.sms_rounded, color: AppTheme.primary),
              onPressed: () async {
                try {
                  await launchUrl(
                    Uri.parse('sms:$workerPhone'),
                    mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
            ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppTheme.divider)),
      ),
      body: Column(children: [
        Expanded(
            child: _threadMessages.isEmpty
                ? Center(
                    child: Text(s.isEn ? 'No messages' : 'Walang mensahe'))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _threadMessages.length,
                    itemBuilder: (_, i) =>
                        _MessageBubble(_threadMessages[i]))),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SafeArea(
              top: false,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                    child: TextField(
                  controller: _inputCtrl,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        s.isEn ? 'Type a message...' : 'Mag-type ng mensahe...',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: AppTheme.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: AppTheme.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2)),
                  ),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ])),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MessageBubble(this.data);

  @override
  Widget build(BuildContext context) {
    final isPatient = data['sender'] == 'patient';
    final isSystem = data['is_system'] == 1;
    String time = '';
    try {
      time = DateFormat('h:mm a')
          .format(DateTime.tryParse(data['sent_at'] ?? '') ?? DateTime.now());
    } catch (_) {}

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
            child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2))),
          child: Text(data['content'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryDark,
                  height: 1.4)),
        )),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isPatient) ...[
            Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.local_hospital_rounded,
                    size: 16, color: AppTheme.primary)),
            const SizedBox(width: 8),
          ],
          Flexible(
              child: Column(
            crossAxisAlignment: isPatient
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isPatient ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        Radius.circular(isPatient ? 18 : 4),
                    bottomRight:
                        Radius.circular(isPatient ? 4 : 18),
                  ),
                  border: isPatient
                      ? null
                      : Border.all(color: AppTheme.divider),
                ),
                child: Text(data['content'] ?? '',
                    style: TextStyle(
                        color: isPatient
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.4)),
              ),
              const SizedBox(height: 3),
              Text(time,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textHint)),
            ],
          )),
        ],
      ),
    );
  }
}

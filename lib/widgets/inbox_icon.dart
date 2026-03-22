import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/utils/app_theme.dart';

/// Mail-style inbox icon with unread badge.
/// Works for both patient and worker — pass their userId (firebase_uid or patient_id).
class InboxIcon extends StatelessWidget {
  final String userId;
  const InboxIcon({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const IconButton(
        icon: Icon(Icons.mail_outline_rounded),
        onPressed: null,
      );
    }
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('inbox/$userId').onValue,
      builder: (context, snap) {
        int unread = 0;
        if (snap.hasData &&
            snap.data!.snapshot.exists &&
            snap.data!.snapshot.value != null) {
          final raw = Map<String, dynamic>.from(
              snap.data!.snapshot.value as Map);
          unread = raw.values.where((v) {
            if (v is! Map) return false;
            return v['read'] == false || v['read'] == 0;
          }).length;
        }
        return Stack(clipBehavior: Clip.none, children: [
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => InboxScreen(userId: userId)),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: 6, top: 6,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: Text('$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

class InboxScreen extends StatelessWidget {
  final String userId;
  const InboxScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Inbox',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppTheme.divider)),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('inbox/$userId').onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (!snap.hasData ||
              !snap.data!.snapshot.exists ||
              snap.data!.snapshot.value == null) {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.mail_outline_rounded,
                      size: 56, color: AppTheme.textHint),
                  SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ]));
          }
          final raw = Map<String, dynamic>.from(
              snap.data!.snapshot.value as Map);
          final items = raw.entries.map((e) {
            final v = Map<String, dynamic>.from(e.value as Map? ?? {});
            v['_key'] = e.key;
            return v;
          }).toList()
            ..sort((a, b) =>
                (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final isRead = item['read'] == true || item['read'] == 1;
              final convId = item['convId'] as String? ?? '';
              final isMed = item['type'] == 'medicine';
              String timeStr = '';
              try {
                timeStr = DateFormat('MMM d, h:mm a').format(
                    DateTime.parse(item['createdAt'] as String? ?? ''));
              } catch (_) {}

              return GestureDetector(
                onTap: () async {
                  await FirebaseDatabase.instance
                      .ref('inbox/$userId/${item['_key']}')
                      .update({'read': true});
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (convId.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Opening conversation — go to Messages tab'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isRead
                            ? AppTheme.divider
                            : AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: (isMed ? Colors.purple : AppTheme.primary)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Icon(
                          isMed
                              ? Icons.medication_rounded
                              : Icons.local_hospital_rounded,
                          color: isMed ? Colors.purple : AppTheme.primary,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Expanded(
                                child: Text(
                                    item['title'] as String? ?? 'Notification',
                                    style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        fontSize: 14))),
                            if (!isRead)
                              Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle)),
                          ]),
                          const SizedBox(height: 2),
                          Text(item['body'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4)),
                          const SizedBox(height: 4),
                          Text(timeStr,
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textHint)),
                        ])),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:alagahub/services/connectivity_service.dart';
import 'package:alagahub/utils/app_theme.dart';

// ── Full-width offline/syncing banner ─────────────────────────────────────
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    return status.when(
      data: (s) {
        if (s == ConnectivityStatus.online) return const SizedBox.shrink();
        final isOffline = s == ConnectivityStatus.offline;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          color: isOffline ? AppTheme.offlineYellow : AppTheme.syncBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.sync_rounded,
              size: 16,
              color: isOffline
                  ? AppTheme.offlineYellowBorder
                  : AppTheme.syncBlueBorder,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              isOffline
                  ? 'Wala kang koneksyon — offline mode'
                  : 'Nag-si-sync ng iyong mga rekord...',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: isOffline
                    ? const Color(0xFF92400E)
                    : const Color(0xFF1E40AF),
              ),
            )),
            if (!isOffline)
              const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.syncBlueBorder)),
          ]),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Status dot for app bars — shows YOUR own connection ───────────────────
// Add to AppBar actions: const StatusDot()
class StatusDot extends ConsumerWidget {
  const StatusDot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    return status.when(
      data: (s) {
        final color = switch (s) {
          ConnectivityStatus.online  => AppTheme.primary,
          ConnectivityStatus.syncing => AppTheme.syncBlueBorder,
          ConnectivityStatus.offline => AppTheme.error,
        };
        final label = switch (s) {
          ConnectivityStatus.online  => 'Online',
          ConnectivityStatus.syncing => 'Syncing',
          ConnectivityStatus.offline => 'Offline',
        };
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              s == ConnectivityStatus.syncing
                  ? SizedBox(width: 8, height: 8,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: color))
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 4, spreadRadius: 1)])),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ]),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Presence badge — shows ANOTHER user's online status from Firebase ─────
// Wrap around an avatar: Stack(children: [avatar, Positioned(bottom:0, right:0, child: PresenceBadge(userId: id))])
class PresenceBadge extends StatelessWidget {
  final String userId;
  final double size;
  const PresenceBadge({super.key, required this.userId, this.size = 12});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<bool>(
      stream: FirebaseDatabase.instance
          .ref('presence/$userId/online')
          .onValue
          .map((e) => e.snapshot.value == true),
      builder: (_, snap) {
        final isOnline = snap.data ?? false;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size, height: size,
          decoration: BoxDecoration(
            color: isOnline ? AppTheme.primary : AppTheme.textHint,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        );
      },
    );
  }
}

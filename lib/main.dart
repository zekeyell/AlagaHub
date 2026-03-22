import 'package:flutter/material.dart';
import 'package:alagahub/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alagahub/utils/app_router.dart';
import 'package:alagahub/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Trigger sync on app start if online
  Connectivity().checkConnectivity().then((result) {
    if (!result.contains(ConnectivityResult.none)) {
      SyncService.instance.runSync();
    }
  });
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: AlagaHubApp()));
}

class AlagaHubApp extends ConsumerWidget {
  const AlagaHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'AlagaHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

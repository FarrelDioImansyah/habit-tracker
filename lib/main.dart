import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Supabase
  await Supabase.initialize(
  url: 'https://ntfdvwsilmqqyuysjjcd.supabase.co',
  anonKey: 'sb_publishable_7cowgPVVNgnf2FTTToNQow_nhcrtKph',
);

  // Init Hive (local cache)
  await Hive.initFlutter();

  // Init timezone untuk notifikasi
  tz.initializeTimeZones();

  // Init notifikasi
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: HabitApp(),
    ),
  );
}

class HabitApp extends ConsumerWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicktasks/app/router.dart';
import 'package:quicktasks/app/theme/paper_theme.dart';
import 'package:quicktasks/features/sync/home_widget_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize home screen widget synchronizer
    ref.watch(homeWidgetSyncProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QuickTasks',
      theme: PaperTheme.themeData,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/app/router.dart';
import 'package:quicktasks/app/theme/paper_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QuickTasks',
      theme: PaperTheme.themeData,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

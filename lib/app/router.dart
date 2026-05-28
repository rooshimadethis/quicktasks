import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicktasks/features/sync/google_auth_provider.dart';
import 'package:quicktasks/features/calendar/day_view/day_view_page.dart';
import 'package:quicktasks/features/calendar/week_view/week_view_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'QuickTasks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'A personal calendar and task manager tailored for e-ink devices.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              OutlinedButton(
                onPressed: () async {
                  final notifier = ref.read(googleAuthNotifierProvider.notifier);
                  final success = await notifier.signIn();
                  if (!success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to sign in. Please try again.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to trigger redirect evaluations when it changes
  final isSignedIn = ref.watch(googleCalendarSignInStateProvider);

  return GoRouter(
    initialLocation: isSignedIn ? '/day' : '/login',
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';

      if (!isSignedIn) {
        return '/login';
      }

      if (isLoggingIn) {
        return '/day';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/day',
        builder: (context, state) => const DayViewPage(),
      ),
      GoRoute(
        path: '/week',
        builder: (context, state) => const WeekViewPage(),
      ),
    ],
  );
});

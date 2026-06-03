import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicktasks/main.dart';
import 'package:quicktasks/app/router.dart';
import 'package:quicktasks/features/sync/google_auth_provider.dart';
import 'package:quicktasks/features/sync/home_widget_sync.dart';

class MockGoogleAuthNotifier extends GoogleAuthNotifier {
  MockGoogleAuthNotifier(super.googleSignIn) {
    state = GoogleAuthState(account: null, isInitialized: true);
  }

  @override
  Future<void> signInSilently() async {
    // Do nothing, already initialized
  }
}

void main() {
  testWidgets('App starts on login screen when unauthenticated', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeWidgetSyncProvider.overrideWith((ref) {}),
          googleAuthNotifierProvider.overrideWith((ref) {
            return MockGoogleAuthNotifier(ref.watch(googleSignInProvider));
          }),
        ],
        child: const MyApp(),
      ),
    );

    // Let the GoRouter navigation settle
    await tester.pumpAndSettle();

    // Verify LoginPage builds
    expect(find.text('QuickTasks'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}

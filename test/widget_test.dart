import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/main.dart';
import 'package:quicktasks/features/sync/google_auth_provider.dart';

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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

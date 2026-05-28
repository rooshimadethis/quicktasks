import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/main.dart';

void main() {
  testWidgets('App starts on login screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Let the GoRouter navigation settle
    await tester.pumpAndSettle();

    // Verify LoginPage builds
    expect(find.text('QuickTasks'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}

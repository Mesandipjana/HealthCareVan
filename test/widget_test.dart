import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthcare/main.dart';

void main() {
  testWidgets('Smoke test - Verify Login Screen displays Sign In', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: HealthcareOpsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the login page displays 'Sign In'
    expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}

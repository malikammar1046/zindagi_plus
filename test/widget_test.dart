// Smoke test for Zindagi+ — validates that the app starts without throwing.
//
// The full counter test from the scaffold has been replaced because MyApp
// was renamed to ZindagiApp and the counter widget was removed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ZindagiApp()),
    );
    // Allow async providers to settle.
    await tester.pump();
    // App should render without throwing.
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ZindagiApp()),
    );
    // Advance timers so splash animation and async restoration settle.
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}

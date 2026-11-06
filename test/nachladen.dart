import 'package:flutter_test/flutter_test.dart';

/// Wartet nach einem Tipp, bis ein **nachgeladener** Bildschirm steht
/// (`oeffneGeladen`, `lib/ui/spaeter_laden.dart`).
///
/// `loadLibrary` wird erst in einem Takt mit vergangener Zeit fertig;
/// geschoben wird danach, und die Seite fährt im nächsten herein. Kein
/// `pumpAndSettle`: Flame zeichnet dauerhaft (`gotchas.md`).
Future<void> nachgeladen(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1));
}

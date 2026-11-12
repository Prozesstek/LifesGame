import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/habits/widgets/daily_chest_card.dart';
import 'package:lifes_game/habits/widgets/truhe_oeffnen.dart';

/// Tippt die Tagestruhe auf, die gerade in der Mitte steht
/// (`TruheOeffnen`), und wartet, bis sie offen ist.
Future<void> tippeTruheAuf(WidgetTester tester) async {
  for (var i = 0; i < TruheOeffnen.tipps; i++) {
    await tester.tap(find.byKey(TruheOeffnen.truheKey));
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pumpAndSettle();
}

/// Tippt sie auf und sackt ein — für Tests, die danach weitermachen.
Future<void> nimmTruhe(WidgetTester tester) async {
  await tippeTruheAuf(tester);
  await tester.tap(find.byKey(DailyChestCard.einsackenKey));
  await tester.pumpAndSettle();
}

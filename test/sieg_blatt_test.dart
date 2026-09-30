import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/widgets/sieg_blatt.dart';

/// Das Blatt nach einem gewonnenen Lauf: Sieg, Ebene und Zeit, Beute,
/// die hereinkommt, zuletzt „Weiter“.
void main() {
  Future<void> zeige(
    WidgetTester tester, {
    int xp = 55,
    int gold = 22,
    bool newBest = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => SiegBlatt(
                    stage: 12,
                    seconds: 84,
                    earnedXp: xp,
                    earnedGold: gold,
                    newBest: newBest,
                  ),
                ),
                child: const Text('los'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pump();
  }

  Opacity deckkraftVon(WidgetTester tester, Finder finder) =>
      tester.widget<Opacity>(
        find.ancestor(of: finder, matching: find.byType(Opacity)).first,
      );

  testWidgets('Sieg, Ebene und Zeit stehen sofort da', (tester) async {
    await zeige(tester);

    expect(find.text('Sieg'), findsOneWidget);
    expect(find.text('Ebene: 12'), findsOneWidget);
    expect(find.text('84 s'), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('die Beute kommt herein und endet in ihrer Farbe', (
    tester,
  ) async {
    await zeige(tester);

    // Am Anfang noch unsichtbar.
    expect(deckkraftVon(tester, find.text('+55')).opacity, 0);

    await tester.pumpAndSettle();
    expect(deckkraftVon(tester, find.text('+55')).opacity, 1);
    expect(deckkraftVon(tester, find.text('+22')).opacity, 1);
    expect(
      tester.widget<Text>(find.text('+22')).style?.color,
      isNot(tester.widget<Text>(find.text('Sieg')).style?.color),
      reason: 'Zum Schluss nicht mehr grün.',
    );
  });

  testWidgets('Weiter erscheint zuletzt und schliesst', (tester) async {
    await zeige(tester);

    await tester.tap(find.byKey(SiegBlatt.weiterKey), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(SiegBlatt), findsOneWidget, reason: 'noch unsichtbar');

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SiegBlatt.weiterKey));
    await tester.pumpAndSettle();
    expect(find.byType(SiegBlatt), findsNothing);
  });

  testWidgets('ein zweiter Sieg zeigt keine Beute', (tester) async {
    await zeige(tester, xp: 0, gold: 0);
    await tester.pumpAndSettle();

    expect(find.textContaining('+'), findsNothing);
    expect(find.byKey(SiegBlatt.weiterKey), findsOneWidget);
  });

  testWidgets('eine neue Bestzeit trägt einen Stern', (tester) async {
    await zeige(tester, newBest: true);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

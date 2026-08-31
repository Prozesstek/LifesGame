import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/widgets/result_dialog.dart';

/// Das Blatt am Ende eines Kampfes.
///
/// Der wichtigste Test ist der letzte: **Es darf keine Belohnung nennen.**
/// Der Kampf ist im Konzept die Auszahlung des Fortschritts, nicht seine
/// Quelle (`konzept.md` Abschnitt 2). Stünde dort eines Tages „+50 XP",
/// wäre das eine Richtungsentscheidung und kein Textdetail — dieser Test
/// zwingt sie ans Licht.
void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required bool won,
    int rounds = 9,
    String enemyName = 'Wegelagerer',
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatResultDialog(
            won: won,
            rounds: rounds,
            enemyName: enemyName,
          ),
        ),
      ),
    );
  }

  group('Ein gewonnener Kampf', () {
    testWidgets('nennt den Gegner und die Rundenzahl', (tester) async {
      await pumpDialog(tester, won: true, rounds: 12, enemyName: 'Söldner');

      expect(find.text('Gewonnen'), findsOneWidget);
      expect(find.textContaining('Söldner'), findsOneWidget);
      expect(find.textContaining('12'), findsOneWidget);
    });

    testWidgets('lässt sich nur über OK schließen', (tester) async {
      await pumpDialog(tester, won: true);

      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('Ein verlorener Kampf', () {
    testWidgets('sagt es ebenso deutlich', (tester) async {
      await pumpDialog(tester, won: false, rounds: 7);

      expect(find.text('Verloren'), findsOneWidget);
      expect(find.text('Gewonnen'), findsNothing);
      expect(find.textContaining('7'), findsOneWidget);
    });

    testWidgets('und nennt keinen Verlust an Werten', (tester) async {
      // `konzept.md` 3.7: Das Spiel bestraft nicht. Eine Niederlage kostet
      // den Kampf und sonst nichts.
      await pumpDialog(tester, won: false);

      expect(find.textContaining('verlierst'), findsNothing);
      expect(find.textContaining('verloren gegangen'), findsNothing);
    });
  });

  group('Es steht keine Belohnung darin', () {
    testWidgets('weder gewonnen noch verloren nennt eine Zahl an XP', (
      tester,
    ) async {
      for (final gewonnen in <bool>[true, false]) {
        await pumpDialog(tester, won: gewonnen);

        final texte = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' ');

        // Kein „+N XP", kein „+N Gold" — der Kampf gibt nichts.
        expect(
          RegExp(r'\+\s*\d').hasMatch(texte),
          isFalse,
          reason: 'Das Blatt verspricht eine Belohnung: $texte',
        );
      }
    });

    testWidgets('sondern sagt, woher der Fortschritt kommt', (tester) async {
      await pumpDialog(tester, won: true);

      expect(find.textContaining('Gewohnheiten'), findsOneWidget);
    });
  });
}

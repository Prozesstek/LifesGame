import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/widgets/result_dialog.dart';

/// Das Blatt am Ende eines Kampfes.
///
/// **Der Test, der hier stand, hat seine Aufgabe erfüllt.** Er verbot
/// jede Belohnung — „stünde dort eines Tages ‚+50 XP', wäre das eine
/// Richtungsentscheidung und kein Textdetail" — und hat sie mit Issue #36
/// ans Licht gezwungen. Die Entscheidung fiel in ADR-0032, und sie ist
/// kleiner als der alte Test annahm: Belohnung ja, aber **einmal je
/// Gegner**.
///
/// An seiner Stelle stehen zwei Zusicherungen, die dieselbe Grenze
/// bewachen: Ein zweiter Sieg gegen denselben Gegner zahlt nichts, und
/// eine Niederlage erst recht nicht. Fällt eine davon, ist aus der
/// Belohnung eine Dauerquelle geworden, und `konzept.md` Abschnitt 2 gilt
/// nicht mehr.
void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required bool won,
    int rounds = 9,
    String enemyName = 'Wegelagerer',
    int earnedXp = 0,
    int earnedGold = 0,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatResultDialog(
            won: won,
            rounds: rounds,
            enemyName: enemyName,
            earnedXp: earnedXp,
            earnedGold: earnedGold,
          ),
        ),
      ),
    );
  }

  /// Alle Texte des Blattes in einer Zeichenkette.
  String texteVon(WidgetTester tester) {
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
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

  group('Belohnung gibt es genau einmal je Gegner', () {
    testWidgets('der erste Sieg nennt Erfahrung und Gold', (tester) async {
      await pumpDialog(tester, won: true, earnedXp: 35, earnedGold: 14);

      expect(find.textContaining('+35 Erfahrung'), findsOneWidget);
      expect(find.textContaining('+14 Gold'), findsOneWidget);
    });

    testWidgets('ein zweiter Sieg gegen denselben Gegner nennt keine', (
      tester,
    ) async {
      // **Die Grenze, unter der es ueberhaupt Belohnung geben darf.**
      // Ohne sie liesse sich der leichteste Gegner in Dauerschleife
      // schlagen, statt Haekchen zu setzen.
      await pumpDialog(tester, won: true);

      expect(
        RegExp(r'\+\s*\d').hasMatch(texteVon(tester)),
        isFalse,
        reason: 'Ein wiederholter Sieg verspricht eine Belohnung.',
      );
      expect(find.textContaining('Den hattest du schon'), findsOneWidget);
    });

    testWidgets('eine Niederlage erst recht nicht', (tester) async {
      // Auch dann nicht, wenn der Aufrufer sich irrt und Zahlen
      // hereingibt: Das Blatt ist die letzte Stelle, an der das auffaellt.
      await pumpDialog(tester, won: false, earnedXp: 35, earnedGold: 14);

      expect(
        RegExp(r'\+\s*\d').hasMatch(texteVon(tester)),
        isFalse,
        reason: 'Eine Niederlage verspricht eine Belohnung.',
      );
    });

    testWidgets('und es sagt weiter, woher der Fortschritt kommt', (
      tester,
    ) async {
      await pumpDialog(tester, won: true, earnedXp: 35, earnedGold: 14);

      expect(find.textContaining('Gewohnheiten'), findsOneWidget);
    });
  });
}

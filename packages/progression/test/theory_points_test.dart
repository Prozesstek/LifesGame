import 'package:progression/progression.dart';
import 'package:test/test.dart';

void main() {
  group('Theoriepunkte entstehen beim Aufstieg', () {
    test('Level 1 hat noch keinen Punkt — er kommt für den Aufstieg', () {
      expect(TheoryPoints.earnedAt(1), 0);
    });

    test('jeder Aufstieg gibt einen Punkt (ADR-0035)', () {
      expect(TheoryPoints.earnedAt(2), 1);
      expect(TheoryPoints.earnedAt(3), 2);
      expect(TheoryPoints.earnedAt(10), 9);
    });

    test('unter Level 1 gibt es nichts', () {
      expect(TheoryPoints.earnedAt(0), 0);
      expect(TheoryPoints.earnedAt(-5), 0);
    });

    test('über dem Höchstlevel wächst nichts mehr', () {
      final amMaximum = TheoryPoints.earnedAt(LevelCurve.maxLevel);

      expect(TheoryPoints.earnedAt(LevelCurve.maxLevel + 10), amMaximum);
    });
  });

  group('Der Vorrat über ein Spielerleben', () {
    test('sind 49 Punkte — ein Punkt je Aufstieg', () {
      expect(TheoryPoints.lifetimeTotal, 49);
      expect(
        TheoryPoints.lifetimeTotal,
        (LevelCurve.maxLevel - 1) * TheoryPoints.perLevel,
      );
    });

    test('der Startbaum steht ab Level 22 ganz offen, nicht früher', () {
      // Der Startbaum hat 21 kostenpflichtige Knoten (ADR-0035 rechnete
      // noch mit 20 und Level 21; seit dem 21.09. hängt *Psychologie*
      // dazu). Unter ADR-0019 stand er ab Level 11 offen, und jeder
      // weitere Punkt war wertlos. Mit einem Punkt je Aufstieg ist die
      // Reihenfolge bis dahin eine Wahl.
      const knotenImStartbaum = 21;

      expect(
        TheoryPoints.earnedAt(22),
        greaterThanOrEqualTo(knotenImStartbaum),
      );
      expect(TheoryPoints.earnedAt(21), lessThan(knotenImStartbaum));
    });
  });

  group('Ausgeben', () {
    test('verfügbar ist verdient minus ausgegeben', () {
      expect(TheoryPoints.availableAt(level: 5, spent: 3), 1);
    });

    test('nie negativ, auch wenn ein Spielstand mehr ausgibt als er hat', () {
      expect(TheoryPoints.availableAt(level: 2, spent: 99), 0);
    });

    test('leisten kann man sich, was man übrig hat', () {
      expect(TheoryPoints.canAfford(level: 2, spent: 0, cost: 1), isTrue);
      expect(TheoryPoints.canAfford(level: 2, spent: 1, cost: 1), isFalse);
    });

    test('was nichts kostet, kann man immer — das Handbuch', () {
      expect(TheoryPoints.canAfford(level: 1, spent: 0, cost: 0), isTrue);
    });
  });
}

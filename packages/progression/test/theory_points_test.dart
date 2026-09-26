import 'package:progression/progression.dart';
import 'package:test/test.dart';

void main() {
  group('Theoriepunkte entstehen beim Aufstieg', () {
    test('Level 1 hat den Startpunkt (ADR-0051)', () {
      expect(TheoryPoints.earnedAt(1), TheoryPoints.atStart);
      expect(TheoryPoints.earnedAt(1), 1);
    });

    test('jeder Aufstieg gibt einen Punkt dazu (ADR-0035)', () {
      expect(TheoryPoints.earnedAt(2), 2);
      expect(TheoryPoints.earnedAt(3), 3);
      expect(TheoryPoints.earnedAt(10), 10);
    });

    test('auf Level 3 reicht es für Wurzel, Zwischenebene und Thema', () {
      // Das Handbuch führt auf Level 3, dort geht der zweite Platz auf.
      // Der Weg zur ersten Fähigkeit kostet seit ADR-0051 drei Punkte.
      expect(TheoryPoints.earnedAt(3), greaterThanOrEqualTo(3));
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
    test('sind 50 Punkte — der Startpunkt und einer je Aufstieg', () {
      expect(TheoryPoints.lifetimeTotal, 50);
      expect(
        TheoryPoints.lifetimeTotal,
        TheoryPoints.atStart +
            (LevelCurve.maxLevel - 1) * TheoryPoints.perLevel,
      );
      expect(
        TheoryPoints.lifetimeTotal,
        TheoryPoints.earnedAt(LevelCurve.maxLevel),
      );
    });

    test('der befüllte Baum steht ab Level 43 ganz offen, nicht früher', () {
      // 43 Knoten, jeder kostet seit ADR-0051 einen Punkt — auch die
      // Wurzeln. ADR-0035 rechnete mit 21 und Level 22. Mit jedem
      // befüllten Gebiet rückt die Zahl nach oben, bis der Baum größer
      // ist als ein Spielerleben (ADR-0037).
      const knotenImBaum = 43;

      expect(
        TheoryPoints.earnedAt(43),
        greaterThanOrEqualTo(knotenImBaum),
      );
      expect(TheoryPoints.earnedAt(42), lessThan(knotenImBaum));
    });
  });

  group('Ausgeben', () {
    test('verfügbar ist verdient minus ausgegeben', () {
      expect(TheoryPoints.availableAt(level: 5, spent: 3), 2);
    });

    test('nie negativ, auch wenn ein Spielstand mehr ausgibt als er hat', () {
      expect(TheoryPoints.availableAt(level: 2, spent: 99), 0);
    });

    test('leisten kann man sich, was man übrig hat', () {
      expect(TheoryPoints.canAfford(level: 2, spent: 1, cost: 1), isTrue);
      expect(TheoryPoints.canAfford(level: 2, spent: 2, cost: 1), isFalse);
    });

    test('was nichts kostet, kann man immer — das Handbuch', () {
      expect(TheoryPoints.canAfford(level: 1, spent: 0, cost: 0), isTrue);
    });
  });
}

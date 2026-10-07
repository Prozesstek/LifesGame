import 'package:progression/progression.dart';
import 'package:test/test.dart';

void main() {
  group('Theoriepunkte entstehen beim Aufstieg', () {
    test('Level 1 hat die Startpunkte (ADR-0070)', () {
      expect(TheoryPoints.earnedAt(1), TheoryPoints.atStart);
      expect(TheoryPoints.earnedAt(1), 9);
    });

    test('jeder Aufstieg gibt einen Punkt dazu (ADR-0035)', () {
      const start = TheoryPoints.atStart;
      expect(TheoryPoints.earnedAt(2), start + 1);
      expect(TheoryPoints.earnedAt(3), start + 2);
      expect(TheoryPoints.earnedAt(10), start + 9);
    });

    test('schon am Anfang reicht es für Wurzel, Zwischenebene und Thema', () {
      // Der Weg zur ersten Fähigkeit kostet seit ADR-0051 drei Punkte.
      // Seit ADR-0070 gibt es sie vom Start weg — wer sie dort ausgibt,
      // hat sechs weniger für die Grundlagen.
      expect(TheoryPoints.earnedAt(1), greaterThanOrEqualTo(3));
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
    test('sind 58 Punkte — neun vom Start und einer je Aufstieg', () {
      expect(TheoryPoints.lifetimeTotal, 58);
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

    test('der Baum ist größer als ein Spielerleben (ADR-0037)', () {
      // Mit den fünf Seiten des Handbuchs hat der Baum 63 Knoten
      // (ADR-0070), jeder kostet einen Punkt — mehr, als es über 50
      // Level je gibt. Das ist das Zielbild aus ADR-0037: Man kann nicht
      // alles lernen, man wählt. Wer Knoten entfernt oder Startpunkte
      // verschenkt, bis diese Zusage fällt, soll es hier merken.
      const knotenImBaum = 63;

      expect(TheoryPoints.lifetimeTotal, lessThan(knotenImBaum));
    });
  });

  group('Ausgeben', () {
    test('verfügbar ist verdient minus ausgegeben', () {
      final verdient = TheoryPoints.earnedAt(5);

      expect(TheoryPoints.availableAt(level: 5, spent: 3), verdient - 3);
      expect(TheoryPoints.availableAt(level: 5, spent: verdient), 0);
    });

    test('nie negativ, auch wenn ein Spielstand mehr ausgibt als er hat', () {
      expect(TheoryPoints.availableAt(level: 2, spent: 99), 0);
    });

    test('leisten kann man sich, was man übrig hat', () {
      final verdient = TheoryPoints.earnedAt(2);

      expect(
        TheoryPoints.canAfford(level: 2, spent: verdient - 1, cost: 1),
        isTrue,
      );
      expect(
        TheoryPoints.canAfford(level: 2, spent: verdient, cost: 1),
        isFalse,
      );
    });

    test('was nichts kostet, kann man immer', () {
      expect(TheoryPoints.canAfford(level: 1, spent: 0, cost: 0), isTrue);
    });
  });
}

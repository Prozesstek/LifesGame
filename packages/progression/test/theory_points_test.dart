import 'package:progression/progression.dart';
import 'package:test/test.dart';

void main() {
  group('Theoriepunkte entstehen beim Aufstieg', () {
    test('Level 1 hat noch keinen Punkt — er kommt für den Aufstieg', () {
      expect(TheoryPoints.earnedAt(1), 0);
    });

    test('jeder Aufstieg gibt zwei Punkte (ADR-0019)', () {
      expect(TheoryPoints.earnedAt(2), 2);
      expect(TheoryPoints.earnedAt(3), 4);
      expect(TheoryPoints.earnedAt(10), 18);
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
    test('sind 98 Punkte — 49 Aufstiege mal zwei', () {
      expect(TheoryPoints.lifetimeTotal, 98);
      expect(
        TheoryPoints.lifetimeTotal,
        (LevelCurve.maxLevel - 1) * TheoryPoints.perLevel,
      );
    });

    test('übersteigt den Startbaum deutlich — bewusst, ADR-0019', () {
      // Der Startbaum hat 20 kostenpflichtige Knoten. Diese Prüfung
      // hält die unangenehme Folge fest, statt sie zu verstecken: Ab
      // Level 11 ist jeder weitere Punkt wertlos, bis der Baum wächst.
      const knotenImStartbaum = 20;
      final aufElf = TheoryPoints.earnedAt(11);
      final aufZehn = TheoryPoints.earnedAt(10);

      expect(aufElf, greaterThanOrEqualTo(knotenImStartbaum));
      expect(aufZehn, lessThan(knotenImStartbaum));
    });
  });

  group('Ausgeben', () {
    test('verfügbar ist verdient minus ausgegeben', () {
      expect(TheoryPoints.availableAt(level: 5, spent: 3), 5);
    });

    test('nie negativ, auch wenn ein Spielstand mehr ausgibt als er hat', () {
      expect(TheoryPoints.availableAt(level: 2, spent: 99), 0);
    });

    test('leisten kann man sich, was man übrig hat', () {
      expect(TheoryPoints.canAfford(level: 2, spent: 0, cost: 2), isTrue);
      expect(TheoryPoints.canAfford(level: 2, spent: 1, cost: 2), isFalse);
    });

    test('was nichts kostet, kann man immer — das Handbuch', () {
      expect(TheoryPoints.canAfford(level: 1, spent: 0, cost: 0), isTrue);
    });
  });
}

import 'package:progression/progression.dart';
import 'package:test/test.dart';

void main() {
  group('Schwellen', () {
    test('Level 1 kostet nichts', () {
      expect(LevelCurve.totalXpFor(1), 0);
      expect(LevelCurve.totalXpFor(0), 0);
      expect(LevelCurve.totalXpFor(-3), 0);
    });

    test('die ersten Stufen liegen auf den erwarteten Werten', () {
      expect(LevelCurve.totalXpFor(2), 100);
      expect(LevelCurve.totalXpFor(3), 225);
      expect(LevelCurve.totalXpFor(4), 375);
      expect(LevelCurve.totalXpFor(5), 550);
      expect(LevelCurve.totalXpFor(6), 750);
    });

    test('jede Stufe kostet mehr als die vorige', () {
      for (var level = 1; level < LevelCurve.maxLevel - 1; level++) {
        expect(
          LevelCurve.xpForStep(level + 1),
          greaterThan(LevelCurve.xpForStep(level)),
          reason: 'Stufe $level',
        );
      }
    });

    test('der Zuwachs bleibt linear und explodiert nicht', () {
      for (var level = 1; level < LevelCurve.maxLevel - 1; level++) {
        final delta =
            LevelCurve.xpForStep(level + 1) - LevelCurve.xpForStep(level);
        expect(delta, LevelCurve.stepXp, reason: 'Stufe $level');
      }
    });
  });

  group('Level aus Erfahrung', () {
    test('null Erfahrung ist Level 1', () {
      final result = LevelCurve.levelFor(0);

      expect(result.level, 1);
      expect(result.xpIntoLevel, 0);
      expect(result.xpForLevel, LevelCurve.baseXp);
      expect(result.ratio, 0);
    });

    test('negative Erfahrung wird wie null behandelt', () {
      expect(LevelCurve.levelFor(-50).level, 1);
      expect(LevelCurve.levelFor(-50).totalXp, 0);
    });

    test('genau an der Schwelle steigt das Level', () {
      expect(LevelCurve.levelFor(99).level, 1);
      expect(LevelCurve.levelFor(100).level, 2);
      expect(LevelCurve.levelFor(224).level, 2);
      expect(LevelCurve.levelFor(225).level, 3);
    });

    test('Restfortschritt innerhalb der Stufe stimmt', () {
      final result = LevelCurve.levelFor(150);

      expect(result.level, 2);
      expect(result.xpIntoLevel, 50);
      expect(result.xpForLevel, 125);
      expect(result.xpToNextLevel, 75);
      expect(result.ratio, closeTo(0.4, 0.001));
    });

    test('auf Maximalstufe gibt es kein Weiter', () {
      final result = LevelCurve.levelFor(10000000);

      expect(result.level, LevelCurve.maxLevel);
      expect(result.isMaxLevel, isTrue);
      expect(result.xpToNextLevel, 0);
      expect(result.ratio, 1);
    });
  });

  group('Zusammenspiel', () {
    test('jede Schwelle ergibt exakt ihr Level', () {
      for (var level = 1; level <= LevelCurve.maxLevel; level++) {
        final atThreshold = LevelCurve.levelFor(LevelCurve.totalXpFor(level));
        expect(atThreshold.level, level);
        expect(atThreshold.xpIntoLevel, 0);
      }
    });

    test('einen Punkt unter der Schwelle bleibt das alte Level', () {
      for (var level = 2; level <= LevelCurve.maxLevel; level++) {
        final below = LevelCurve.levelFor(LevelCurve.totalXpFor(level) - 1);
        expect(below.level, level - 1, reason: 'Schwelle zu $level');
      }
    });
  });
}

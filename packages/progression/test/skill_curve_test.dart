import 'package:progression/progression.dart';
import 'package:test/test.dart';

/// Die Kurve der Skills (ADR-0085). Wie schnell ein Skill mit echten
/// Häkchen steigt, prüft `test/skills_test.dart` in der App — hier steht
/// nur die Form der Kurve.
void main() {
  group('SkillCurve', () {
    test('beginnt auf 1, die erste Stufe kostet so viel wie beim Level', () {
      expect(SkillCurve.levelFor(0).level, 1);
      expect(SkillCurve.totalXpFor(2), LevelCurve.baseXp);
      expect(SkillCurve.levelFor(99).level, 1);
      expect(SkillCurve.levelFor(100).level, 2);
    });

    test('jede Stufe kostet mehr als die vorige, um denselben Schritt', () {
      for (var level = 2; level < SkillCurve.maxLevel; level++) {
        final vorher =
            SkillCurve.totalXpFor(level) - SkillCurve.totalXpFor(level - 1);
        final jetzt =
            SkillCurve.totalXpFor(level + 1) - SkillCurve.totalXpFor(level);
        expect(jetzt - vorher, SkillCurve.stepXp, reason: 'Stufe $level');
      }
    });

    test('flacher als das Level — sonst endete er so früh wie das Level', () {
      expect(SkillCurve.stepXp, lessThan(LevelCurve.stepXp));
      expect(SkillCurve.maxLevel, greaterThan(LevelCurve.maxLevel));
    });

    test('endet bei 100 und bleibt dort', () {
      final ende = SkillCurve.totalXpFor(SkillCurve.maxLevel);
      final skill = SkillCurve.levelFor(ende * 10);

      expect(skill.level, SkillCurve.maxLevel);
      expect(skill.isMaxLevel, isTrue);
      expect(skill.xpToNextLevel, 0);
      expect(skill.ratio, 1);
    });

    test('der Stand innerhalb der Stufe geht auf', () {
      final skill = SkillCurve.levelFor(SkillCurve.totalXpFor(7) + 40);

      expect(skill.level, 7);
      expect(skill.xpIntoLevel, 40);
      expect(skill.xpForLevel, SkillCurve.baseXp + 6 * SkillCurve.stepXp);
      expect(skill.xpToNextLevel, skill.xpForLevel - 40);
    });

    test('negative Erfahrung ist keine — Stufe 1', () {
      expect(SkillCurve.levelFor(-50).level, 1);
      expect(SkillCurve.levelFor(-50).totalXp, 0);
    });

    test('der Start ist dasselbe wie null Erfahrung', () {
      const start = SkillLevel.start();
      final leer = SkillCurve.levelFor(0);

      expect(start.level, leer.level);
      expect(start.xpForLevel, leer.xpForLevel);
    });

    test('das Gesamtlevel ist die Summe', () {
      final skills = <SkillLevel>[
        SkillCurve.levelFor(0),
        SkillCurve.levelFor(SkillCurve.totalXpFor(10)),
        SkillCurve.levelFor(SkillCurve.totalXpFor(25)),
        SkillCurve.levelFor(SkillCurve.totalXpFor(3)),
      ];
      expect(SkillCurve.totalLevelOf(skills), 1 + 10 + 25 + 3);
    });
  });
}

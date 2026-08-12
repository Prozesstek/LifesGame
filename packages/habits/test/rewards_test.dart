import 'package:habits/habits.dart';
import 'package:test/test.dart';

void main() {
  group('Streak-Multiplikator', () {
    test('erster Tag zählt einfach', () {
      expect(HabitRewards.multiplierFor(1), 1.0);
      expect(HabitRewards.xpFor(1), HabitRewards.xpPerCheck);
    });

    test('steigt an den Meilensteinen und nicht dazwischen', () {
      expect(HabitRewards.multiplierFor(2), 1.0);
      expect(HabitRewards.multiplierFor(3), 1.2);
      expect(HabitRewards.multiplierFor(6), 1.2);
      expect(HabitRewards.multiplierFor(7), 1.4);
    });

    test('ist bei x2 gedeckelt — auch nach Jahren', () {
      expect(HabitRewards.multiplierFor(60), HabitRewards.multiplierCap);
      expect(HabitRewards.multiplierFor(3650), HabitRewards.multiplierCap);
    });

    test('Meilensteine steigen streng und enden am Deckel', () {
      const milestones = HabitRewards.streakMilestones;
      for (var i = 1; i < milestones.length; i++) {
        expect(milestones[i].days, greaterThan(milestones[i - 1].days));
        expect(
          milestones[i].multiplier,
          greaterThan(milestones[i - 1].multiplier),
        );
      }
      expect(milestones.last.multiplier, HabitRewards.multiplierCap);
    });

    test('nextMilestoneAfter zeigt das nächste Ziel, am Deckel nichts', () {
      expect(HabitRewards.nextMilestoneAfter(0)?.days, 3);
      expect(HabitRewards.nextMilestoneAfter(3)?.days, 7);
      expect(HabitRewards.nextMilestoneAfter(60), isNull);
    });

    test('kein Ertrag ohne Häkchen', () {
      expect(HabitRewards.xpFor(0), 0);
      expect(HabitRewards.goldFor(0), 0);
    });

    test('Gold folgt dem Streak bewusst nicht', () {
      expect(HabitRewards.goldFor(1), HabitRewards.goldPerCheck);
      expect(HabitRewards.goldFor(100), HabitRewards.goldPerCheck);
    });
  });

  group('Stat-Kurve', () {
    test('ohne Häkchen steht jeder Wert auf seinem Grundwert', () {
      const stats = CharacterStats.fresh();

      expect(stats.attack, 13);
      expect(stats.maxHp, 100);
      expect(stats.defense, 8);
      expect(stats.maxEnergy, 8);
      expect(stats.totalChecks, 0);
    });

    test('wächst in Stufen, nicht kontinuierlich', () {
      const stat = HabitStat.staerke;
      expect(StatCurve.bonusFor(stat, 4), 0);
      expect(StatCurve.bonusFor(stat, 5), 1);
      expect(StatCurve.bonusFor(stat, 9), 1);
      expect(StatCurve.bonusFor(stat, 10), 2);
    });

    test('jeder Wert hat einen Deckel', () {
      for (final stat in HabitStat.values) {
        final rule = StatCurve.ruleFor(stat);
        expect(StatCurve.bonusFor(stat, 100000), rule.maxBonus);
      }
    });

    test('Energie bleibt über den Kosten des teuersten Moves', () {
      // Der Wuchtschlag kostet 6 Energie. Ein Grundwert darunter würde
      // einen der vier Kampf-Slots unbenutzbar machen.
      final energie = StatCurve.ruleFor(HabitStat.klarheit);
      expect(energie.base, greaterThanOrEqualTo(6));
    });

    test('Angriff bleibt im Band, das die Simulation als offen zeigt', () {
      // Der Gegner steht bei 18 Angriff. Ein Held, der schon am ersten Tag
      // darüber läge, hätte keinen Grund, Gewohnheiten abzuhaken.
      final rule = StatCurve.ruleFor(HabitStat.staerke);
      expect(rule.base, lessThan(18));
      expect(rule.base + rule.maxBonus, greaterThanOrEqualTo(18));
    });

    test('checksToNextPoint zählt herunter und ist am Deckel 0', () {
      const stat = HabitStat.staerke;
      expect(StatCurve.checksToNextPoint(stat, 0), 5);
      expect(StatCurve.checksToNextPoint(stat, 4), 1);
      expect(StatCurve.checksToNextPoint(stat, 5), 5);

      final rule = StatCurve.ruleFor(stat);
      final atCap = rule.checksPerPoint * rule.maxBonus ~/ rule.pointStep;
      expect(StatCurve.checksToNextPoint(stat, atCap), 0);
    });
  });
}

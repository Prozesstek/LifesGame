import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Grössere Zahlen und vervielfachtes Wachstum (ADR-0042).
void main() {
  final kammer = Level.parse('Kammer', const <String>[
    '##########',
    '#@..e...B#',
    '##########',
  ]);

  group('Die Zahlen mal zehn', () {
    test('der Held geht mit seinen Kampfzahlen in die Welt', () {
      final welt = ActionWorld(level: kammer, heroStats: ActionStats.frisch);
      expect(welt.heroMaxHp, ActionStats.frisch.combatMaxHp);
      expect(
        welt.heroMaxHp,
        ActionStats.frisch.maxHp * ActionBalance.powerScale,
      );
    });

    test('die Gegner stehen im selben Massstab, auch ohne Stufe', () {
      // Ohne Stufe: Grundwerte mal zehn. Ein Schlag des frischen Helden
      // bleibt damit derselbe Anteil ihres Lebens wie vorher.
      final welt = ActionWorld(level: kammer, heroStats: ActionStats.frisch);
      welt.step(Vec2.zero);
      expect(welt.bossView, isNotNull);
      expect(welt.bossView!.hpRatio, 1);
    });
  });

  group('Vervielfacht statt addiert', () {
    test('Level und Seltenheit multiplizieren, Häkchen addieren', () {
      final roh = PitPower.hero(
        attack: 20,
        maxHp: 200,
        defense: 10,
        energy: 10,
        levelFactor: 1,
        weaponFactor: 1,
        armorFactor: 1,
      );
      final stark = PitPower.hero(
        attack: 20,
        maxHp: 200,
        defense: 10,
        energy: 10,
        levelFactor: 2,
        weaponFactor: 2.2,
        armorFactor: 1.5,
      );

      expect(stark.combatAttack, closeTo(roh.combatAttack * 4.4, 1));
      expect(stark.combatMaxHp, closeTo(roh.combatMaxHp * 3, 1));
      expect(stark.combatDefense, closeTo(roh.combatDefense * 2, 1));
      expect(stark.energy, roh.energy, reason: 'Energie bleibt Energie.');
    });

    test('die Stufen wachsen mit: ×1 auf Stufe 1, der Deckel auf 30', () {
      expect(PitStage(1).powerFactor, 1);
      expect(
        PitStage(PitStage.count).powerFactor,
        closeTo(ActionBalance.stagePowerLast, 0.0001),
      );
      for (var s = 2; s <= PitStage.count; s++) {
        expect(
          PitStage(s).powerFactor,
          greaterThan(PitStage(s - 1).powerFactor),
        );
      }
    });

    test('ein stärkerer Held fällt dieselbe Stufe schneller', () {
      // Das Verhalten, nicht nur die Zahl (`CLAUDE.md`: ein Feld, das
      // Verhalten steuern soll, braucht einen Test auf das Verhalten).
      double sekunden(double faktor) {
        final welt = ActionWorld(
          level: LevelBuilder.build(stage: PitStage(10), seed: 3),
          stage: PitStage(10),
          heroStats: PitPower.hero(
            attack: 20,
            maxHp: 300,
            defense: 15,
            energy: 12,
            levelFactor: faktor,
            weaponFactor: 1,
            armorFactor: 1,
          ),
          seed: 3,
        );
        PitBot.play(welt);
        expect(welt.isWon, isTrue, reason: '×$faktor');
        return welt.elapsed;
      }

      expect(sekunden(4), lessThan(sekunden(2)));
    });
  });
}

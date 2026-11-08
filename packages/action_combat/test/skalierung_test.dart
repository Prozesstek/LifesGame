import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Angriffsschaden und Fähigkeitsstärke (`docs/vorlagen/skalierung.md`).
void main() {
  ActionWorld welt(ActionStats stats, List<String> ids) => ActionWorld(
        level: LevelCatalog.grube,
        heroStats: stats,
        abilityIds: ids,
      );

  double wucht(PitAbility a) => switch (a.effects.first) {
        BoltAtNearest(:final power) => power,
        StrikeNearest(:final power) => power,
        _ => throw StateError('kein Schlag: ${a.id}'),
      };

  ActionStats held({required int attack, required int fs, double cdr = 0}) =>
      ActionStats(
        attack: attack,
        abilityPower: fs,
        maxHp: 200,
        defense: 10,
        energy: 10,
        cooldownReduction: cdr,
      );

  test('jede Fähigkeit hat einen Anteil zwischen 0 und 1', () {
    for (final a in <PitAbility>[
      ...PitAbilities.all,
      ...PitAbilities.ultimates,
    ]) {
      expect(a.fs, inInclusiveRange(0, 1), reason: a.id);
    }
  });

  test('sind beide Werte gleich, ändert sich nichts', () {
    for (final a in PitAbilities.all) {
      for (final m in PitSkalierung.fuer(a, held(attack: 20, fs: 20))) {
        switch (m) {
          case ScaleDamage(:final factor) || ScaleProtection(:final factor):
            expect(factor, closeTo(1, 1e-9), reason: a.id);
          default:
        }
      }
    }
  });

  test('ohne Angabe ist die Fähigkeitsstärke der Angriff', () {
    const s = ActionStats(attack: 17, maxHp: 1, defense: 1, energy: 8);
    expect(s.combatAbilityPower, s.combatAttack);
  });

  test('Geist macht Magie härter, Körper Schläge', () {
    final geist = welt(held(attack: 10, fs: 20), <String>[
      'funkenstoss',
      'heavy_attack',
    ]);
    final funke = wucht(PitAbilities.byId('funkenstoss')!);
    final schlag = wucht(PitAbilities.byId('heavy_attack')!);

    // Funkenstoß ist ganz Magie: doppelte Fähigkeitsstärke, doppelte Wucht.
    expect(wucht(geist.slots[0]), closeTo(funke * 2, 1e-9));
    // Kraftschlag ist ganz Schlag: unverändert.
    expect(wucht(geist.slots[1]), closeTo(schlag, 1e-9));
  });

  test('ein Hybrid nimmt seinen Anteil', () {
    // Zehrung: 40 % Fähigkeitsstärke.
    expect(
      PitSkalierung.schadensFaktor(0.4, as: 10, fs: 20),
      closeTo(1.4, 1e-9),
    );
  });

  test('Heilung wächst mit der Fähigkeitsstärke, aber gedeckelt', () {
    expect(
      PitSkalierung.schutzFaktor(1, as: 10, fs: 100),
      ActionBalance.schutzMax,
    );
    expect(
      PitSkalierung.schutzFaktor(1, as: 100, fs: 10),
      ActionBalance.schutzMin,
    );
  });

  test('die Abklingzeit kürzt höchstens um 40 %, nie die Ultimate', () {
    final a = PitAbilities.byId('funkenstoss')!;
    final kurz = welt(held(attack: 10, fs: 10, cdr: 0.9), <String>[
      'funkenstoss',
    ]);
    expect(
      kurz.slots.single.cooldown,
      closeTo(a.cooldown * (1 - ActionBalance.maxCooldownReduction), 1e-9),
    );
    final ult = PitAbilities.ultimates.first;
    expect(
      PitSkalierung.fuer(ult, held(attack: 10, fs: 10, cdr: 0.3))
          .whereType<ScaleCooldown>(),
      isEmpty,
    );
  });

  test('die Energie kommt aus dem Level, 8 bis 12', () {
    expect(ActionBalance.energyAt(1), 8);
    expect(ActionBalance.energyAt(ActionBalance.energyLevelCap), 12);
    expect(ActionBalance.energyAt(100), 12);
  });
}

import 'package:combat/combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/gear/set_effects.dart';

/// Die Naht zwischen `package:gear` und `package:combat` für die Sets.
///
/// Beide kennen einander nicht: `gear` weiß, welche vier Stücke ein Set
/// sind und was es gibt; `combat` weiß, was ein Zug ist und wie Schaden
/// entsteht. Sie treffen sich über zwei Aufzählungen, die dieselbe Sache
/// meinen und getrennt gepflegt werden — `SetTarget` und `MoveKind`.
///
/// Gleiche Bauform wie `test/abilities_seam_test.dart` für die Move-Ids.
void main() {
  group('Die beiden Aufzählungen passen aufeinander', () {
    test('jedes Set-Ziel findet eine Art von Zug', () {
      for (final target in SetTarget.values) {
        expect(moveKindFor(target), isNotNull, reason: target.name);
      }
    });

    test('keine zwei Ziele zeigen auf dieselbe Art', () {
      final arten = SetTarget.values.map(moveKindFor).toSet();

      expect(arten, hasLength(SetTarget.values.length));
    });

    test('jede Art von Zug ist von einem Ziel erreichbar', () {
      // **Die Richtung, die leicht auseinanderläuft.** Käme in
      // `package:combat` eine vierte Art dazu, gäbe es Fähigkeiten, die
      // kein Set je verstärken kann — und niemand würde es merken.
      final erreichbar = SetTarget.values.map(moveKindFor).toSet();

      expect(erreichbar, MoveKind.values.toSet());
    });
  });

  group('Jedes Set findet Fähigkeiten, auf die es wirkt', () {
    test('zu jedem Set gibt es mindestens zwei passende Fähigkeiten', () {
      // Ein Set, das genau eine Fähigkeit verstärkt, wäre keine
      // Entscheidung, sondern eine Bedingung.
      for (final set in GearSets.all) {
        final kind = moveKindFor(set.target);
        final passend = AbilityMoves.all.where(
          (move) => move.kind == kind && move.energyCost > 0,
        );

        expect(
          passend.length,
          greaterThanOrEqualTo(2),
          reason:
              '${set.name} wirkt auf ${set.target.label}, aber dafür gibt '
              'es nur ${passend.length} Fähigkeit(en).',
        );
      }
    });

    test('kein Set verstärkt einen Waffenzug', () {
      // **Die Regel aus ADR-0009, ein zweites Mal.** Ein Faktor auf den
      // Zug, den man jede Runde drückt, entscheidet den Kampf allein.
      final effekte = setEffectsFor(<ActiveSet>[
        for (final set in GearSets.all)
          ActiveSet(set: set, pieces: 4, perk: set.fourPiece),
      ]);

      for (final waffenMove in <String>[
        'basic_attack',
        'sword_strike',
        'dagger_double',
        'mace_bash',
        'staff_gather',
      ]) {
        final move = Moves.byId(waffenMove)!;

        for (final effekt in effekte) {
          expect(effekt.appliesTo(move), isFalse, reason: waffenMove);
        }
      }
    });
  });

  group('Die Übersetzung gibt weiter, was das Set sagt', () {
    test('jede Zahl kommt unverändert an', () {
      for (final set in GearSets.all) {
        final effekt = setEffectsFor(<ActiveSet>[
          ActiveSet(set: set, pieces: 4, perk: set.fourPiece),
        ]).single;

        expect(effekt.kind, moveKindFor(set.target), reason: set.name);
        expect(effekt.damageFactor, set.fourPiece.damageFactor);
        expect(effekt.energyDiscount, set.fourPiece.energyDiscount);
        expect(effekt.timingSpeedFactor, set.fourPiece.timingSpeedFactor);
        expect(effekt.timingWindowFactor, set.fourPiece.timingWindowFactor);
      }
    });

    test('ohne getragene Sets gibt es nichts zu übersetzen', () {
      expect(setEffectsFor(const <ActiveSet>[]), isEmpty);
    });
  });

  group('Ein volles Set ist im Kampf spürbar', () {
    test('Sturmruf macht Giftmoor wirklich billiger', () {
      // Der Weg vom getragenen Stück bis in die Engine, in einem Test.
      // Die beiden Enden getrennt zu prüfen hat schon einmal einen Fehler
      // durchgelassen (`docs/context/gotchas.md`).
      var loadout = const Loadout.empty();
      for (final item in GearCatalog.piecesOf(GearSets.sturmruf.id)) {
        loadout = loadout.buy(item.id, availableGold: 100000);
      }

      final giftmoor = Moves.byId('giftmoor')!;
      final sets = setEffectsFor(loadout.activeSets);

      expect(sets.energyDiscountFor(giftmoor), 2);

      final start = CombatState.start(
        player: Combatant.fresh(
          name: 'Du',
          maxHp: 200,
          attack: 16,
          defense: 8,
          maxEnergy: 20,
          startEnergy: 20,
        ),
        enemy: Combatant.fresh(
          name: 'Gegner',
          maxHp: 500,
          attack: 1,
          defense: 0,
          maxEnergy: 0,
        ),
      );
      final ohne = CombatEngine(seed: 3).resolveRound(
        start,
        PlayerAction(move: giftmoor, timedHit: TimedHit.none),
      );
      final mit = CombatEngine(seed: 3, playerSets: sets).resolveRound(
        start,
        PlayerAction(move: giftmoor, timedHit: TimedHit.none),
      );

      expect(mit.state.player.energy, ohne.state.player.energy + 2);
    });
  });
}

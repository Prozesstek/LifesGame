import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein Held in einer kleinen Halle, ein Gegner weit genug weg, dass er
/// nicht sofort zuschlägt, und nah genug für einen Funken.
ActionWorld _welt({
  List<String> abilities = const <String>[
    'funkenstoss',
    'steinhaut',
    'bluetentau',
  ],
  ActionStats stats = ActionStats.frisch,
}) {
  return ActionWorld(
    level: Level.parse('Probe', const <String>[
      '############',
      '#@.........#',
      '#..........#',
      '#.......e..#',
      '#.........B#',
      '############',
    ]),
    heroStats: stats,
    abilityIds: abilities,
  );
}

void main() {
  group('Der Katalog', () {
    test('jede kostet Mana oder bringt welches, klingt ab und wirkt', () {
      // Umsonst ist nur, was Mana zurückgibt — sonst wäre sie eine
      // Fähigkeit ohne Preis, und man drückte sie jede Abklingzeit blind.
      for (final ability in PitAbilities.all) {
        final bringtMana = ability.effects.any((e) => e is GainMana);
        expect(
          ability.manaCost > 0 || bringtMana,
          isTrue,
          reason: ability.id,
        );
        expect(ability.cooldown, greaterThan(0), reason: ability.id);
        expect(ability.effects, isNotEmpty, reason: ability.id);
      }
    });

    test('keine Id doppelt', () {
      final ids = PitAbilities.all.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('jede passt mit vollem Mana eines frischen Helden', () {
      // Sonst gäbe es auf Tag 0 einen Knopf, der nie geht.
      for (final ability in PitAbilities.all) {
        expect(
          ability.manaCost,
          lessThanOrEqualTo(ActionStats.frisch.maxMana),
          reason: ability.id,
        );
      }
    });
  });

  group('Mana', () {
    test('ein Lauf beginnt mit vollem Mana aus der Energie', () {
      final welt = _welt();
      expect(welt.maxMana, ActionStats.frisch.energy * 5);
      expect(welt.mana, welt.maxMana);
    });

    test('eine Fähigkeit kostet Mana, und es kommt mit der Zeit zurück', () {
      final welt = _welt();
      expect(welt.cast('steinhaut'), isTrue);
      final danach = welt.mana;
      expect(danach, welt.maxMana - PitAbilities.steinhaut.manaCost);

      for (var i = 0; i < 60; i++) {
        welt.step(Vec2.zero);
      }
      expect(welt.mana, greaterThan(danach));
    });

    test('ohne genug Mana geht nichts', () {
      final welt = _welt(
        stats: const ActionStats(attack: 13, maxHp: 160, defense: 8, energy: 1),
      );
      // 5 Mana, Blütentau kostet 30.
      expect(welt.canCast('bluetentau'), isFalse);
      expect(welt.cast('bluetentau'), isFalse);
    });
  });

  group('Plätze', () {
    test('Ids, die die Grube nicht kennt, fallen heraus', () {
      final welt = _welt(
        abilities: const <String>[
          'gibt-es-nicht-und-soll-es-nie-geben',
          'funkenstoss',
        ],
      );
      expect(welt.slots.map((a) => a.id), <String>['funkenstoss']);
      expect(welt.cast('gibt-es-nicht-und-soll-es-nie-geben'), isFalse);
    });

    test('höchstens drei Plätze gehen mit', () {
      final welt = _welt(
        abilities: const <String>[
          'funkenstoss',
          'steinhaut',
          'bluetentau',
          'funkenstoss',
        ],
      );
      expect(welt.slots.length, lessThanOrEqualTo(3));
    });

    test('was nicht auf einem Platz liegt, lässt sich nicht wirken', () {
      final welt = _welt(abilities: const <String>['steinhaut']);
      expect(welt.cast('bluetentau'), isFalse);
    });

    test('eine gewirkte Fähigkeit klingt ab', () {
      final welt = _welt();
      expect(welt.cast('steinhaut'), isTrue);
      expect(welt.cast('steinhaut'), isFalse);
      expect(welt.slotCooldownRatio('steinhaut'), greaterThan(0.9));
    });
  });

  group('Wirkungen', () {
    test('Funkenstoß trifft den nächsten Gegner', () {
      final welt = _welt();
      welt.drainEvents();

      expect(welt.cast('funkenstoss'), isTrue);
      expect(welt.projectiles, hasLength(1));
      expect(welt.projectiles.single.faction, Faction.held);

      var getroffen = false;
      for (var i = 0; i < 120 && !getroffen; i++) {
        welt.step(Vec2.zero);
        getroffen = welt.drainEvents().any(
              (e) => e is HitLanded && e.targetFaction == Faction.gegner,
            );
      }
      expect(getroffen, isTrue);
    });

    test('ein Funke ohne Ziel kostet nichts', () {
      final welt = ActionWorld(
        level: Level.parse('Leer', const <String>[
          '##############################',
          '#@...........................#',
          '#...........................B#',
          '##############################',
        ]),
        heroStats: ActionStats.frisch,
        abilityIds: const <String>['funkenstoss'],
      );

      expect(welt.cast('funkenstoss'), isFalse);
      expect(welt.mana, welt.maxMana);
      expect(welt.slotCooldownRatio('funkenstoss'), 0);
    });

    test('Blütentau heilt, aber nie über das Maximum', () {
      final welt = _welt();
      welt.drainEvents();
      expect(welt.cast('bluetentau'), isTrue);

      expect(welt.heroHp, welt.heroMaxHp);
      final heilung = welt.drainEvents().whereType<HeroHealed>().single;
      expect(heilung.amount, 0);
    });

    test('Steinhaut senkt den Schaden, den der Held nimmt', () {
      // Zwei gleiche Läufe mit demselben Startwert, einer mit Steinhaut:
      // Nach derselben Zeit im Nahkampf fehlt dem geschützten weniger.
      int verlust({required bool schutz}) {
        final welt = ActionWorld(
          level: Level.parse('Enge', const <String>[
            '#######',
            '#@e..B#',
            '#######',
          ]),
          heroStats: const ActionStats(
            attack: 1,
            maxHp: 500,
            defense: 0,
            energy: 8,
          ),
          abilityIds: const <String>['steinhaut'],
          seed: 4,
        );
        if (schutz) welt.cast('steinhaut');
        for (var i = 0; i < 240; i++) {
          welt.step(Vec2.zero);
        }
        return welt.heroMaxHp - welt.heroHp;
      }

      final ohne = verlust(schutz: false);
      final mit = verlust(schutz: true);

      expect(ohne, greaterThan(0));
      expect(mit, lessThan(ohne));
    });
  });

  test('ein Bot mit allen drei Fähigkeiten räumt eine Stufe', () {
    final welt = ActionWorld(
      level: LevelBuilder.build(stage: PitStage(3), seed: 2),
      heroStats: ActionStats.gereift,
      stage: PitStage(3),
      abilityIds: PitAbilities.all.map((a) => a.id).toList(),
      seed: 2,
    );

    PitBot.play(welt);

    expect(welt.isWon, isTrue);
  });
}

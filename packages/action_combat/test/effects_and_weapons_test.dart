import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein Held, zwei Fussvolk dicht daneben, der Wächter weit weg.
ActionWorld _eng({
  List<String> abilities = const <String>[],
  String? weapon,
  ActionStats stats = ActionStats.gereift,
  int seed = 3,
}) {
  return ActionWorld(
    level: Level.parse('Eng', const <String>[
      '##################',
      '#................#',
      '#.@e.............#',
      '#..e............B#',
      '#................#',
      '##################',
    ]),
    heroStats: stats,
    abilityIds: abilities,
    weaponMoveId: weapon,
    seed: seed,
  );
}

/// Ein langer Gang: Held links, ein Gegner fünf Felder weit, Wächter
/// rechts — nah genug für jeden Bogen und jeden Funken.
ActionWorld _weit({
  List<String> abilities = const <String>[],
  String? weapon,
}) {
  return ActionWorld(
    level: Level.parse('Weit', const <String>[
      '##################',
      '#@....e.........B#',
      '##################',
    ]),
    heroStats: ActionStats.gereift,
    abilityIds: abilities,
    weaponMoveId: weapon,
  );
}

int _schadenAnGegnern(List<ActionEvent> events) {
  return events
      .whereType<HitLanded>()
      .where((e) => e.targetFaction == Faction.gegner)
      .fold<int>(0, (summe, e) => summe + e.amount);
}

List<ActionEvent> _laufen(ActionWorld welt, int schritte) {
  final ereignisse = <ActionEvent>[];
  for (var i = 0; i < schritte; i++) {
    welt.step(Vec2.zero);
    ereignisse.addAll(welt.drainEvents());
  }
  return ereignisse;
}

void main() {
  group('Die neuen Wirkungen', () {
    test('Wurzelgriff verlangsamt, was in der Nähe steht', () {
      final welt = _eng(abilities: const <String>['wurzelgriff']);
      expect(welt.cast('wurzelgriff'), isTrue);

      final gegner = welt.views.where((v) => v.faction == Faction.gegner);
      expect(gegner.where((v) => v.isSlowed), isNotEmpty);
      // Der Wächter steht weit hinten und bleibt unberührt.
      expect(
        gegner.where((v) => v.kind == EnemyKind.endgegner && v.isSlowed),
        isEmpty,
      );
    });

    test('Giftmoor frisst über Zeit, auch ohne Treffer', () {
      // Ein Held mit Angriff 1: Seine Schläge richten fast nichts an, der
      // Unterschied zwischen beiden Läufen ist das Gift.
      int schaden({required bool gift}) {
        final welt = _eng(
          abilities: const <String>['giftmoor'],
          stats: const ActionStats(
            attack: 1,
            maxHp: 500,
            defense: 0,
            energy: 8,
          ),
        );
        if (gift) {
          expect(welt.cast('giftmoor'), isTrue);
          expect(welt.views.where((v) => v.isBurning), isNotEmpty);
        }
        welt.drainEvents();
        return _schadenAnGegnern(_laufen(welt, 120));
      }

      expect(schaden(gift: true), greaterThan(schaden(gift: false)));
    });

    test('Aurastrom bringt Mana zurück, kostet aber keins', () {
      final welt = _eng(abilities: const <String>['aurastrom', 'sternenfall']);
      expect(welt.cast('sternenfall'), isTrue);
      final leer = welt.mana;

      expect(welt.cast('aurastrom'), isTrue);
      expect(welt.mana, greaterThan(leer));
    });

    test('Seelenraub heilt um den angerichteten Schaden', () {
      final welt = _weit(abilities: const <String>['seelenraub']);
      expect(welt.cast('seelenraub'), isTrue);

      final ereignisse = _laufen(welt, 120);
      final heilung = ereignisse.whereType<HeroHealed>();
      expect(heilung, isNotEmpty);
    });

    test('die Prisma-Barriere trifft den Schläger', () {
      int schadenAmGegner({required bool barriere}) {
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
          abilityIds: const <String>['prisma_barriere'],
          seed: 4,
        );
        if (barriere) welt.cast('prisma_barriere');
        return _schadenAnGegnern(_laufen(welt, 180));
      }

      expect(
        schadenAmGegner(barriere: true),
        greaterThan(schadenAmGegner(barriere: false)),
      );
    });

    test('kein Funke auf einen Gegner hinter der Wand', () {
      final welt = ActionWorld(
        level: Level.parse('Mauer', const <String>[
          '###########',
          '#@..#..e..#',
          '#...#.....#',
          '#...#....B#',
          '#.........#',
          '###########',
        ]),
        heroStats: ActionStats.frisch,
        abilityIds: const <String>['funkenstoss'],
      );

      expect(welt.cast('funkenstoss'), isFalse);
      expect(welt.mana, welt.maxMana);
    });
  });

  group('Die Waffe ist der Grundangriff', () {
    test('ohne Waffe schlägt die Faust', () {
      expect(_eng().weapon, same(PitWeapons.fist));
    });

    test('ein Zug, der keine Waffe ist, bleibt die Faust', () {
      expect(_eng(weapon: 'funkenstoss').weapon, same(PitWeapons.fist));
    });

    test('der Bogen schiesst', () {
      final welt = _weit(weapon: 'basic_attack');
      welt.step(Vec2.zero);

      expect(welt.projectiles, isNotEmpty);
      expect(welt.projectiles.first.faction, Faction.held);
    });

    test('der Doppelschuss schiesst zwei Pfeile', () {
      final welt = _weit(weapon: 'longbow_volley');
      welt.step(Vec2.zero);

      expect(welt.projectiles, hasLength(2));
    });

    test('der Spalter trifft beide Nachbarn mit einem Schlag', () {
      final welt = _eng(weapon: 'greatsword_cleave');
      welt.drainEvents();
      welt.step(Vec2.zero);

      final getroffen = welt
          .drainEvents()
          .whereType<HitLanded>()
          .where((e) => e.targetFaction == Faction.gegner)
          .map((e) => e.targetId)
          .toSet();
      expect(getroffen, hasLength(2));
    });

    test('der Doppelstich trifft zweimal', () {
      final welt = _eng(weapon: 'dagger_double');
      welt.drainEvents();
      welt.step(Vec2.zero);

      final treffer = welt
          .drainEvents()
          .whereType<HitLanded>()
          .where((e) => e.targetFaction == Faction.gegner);
      expect(treffer, hasLength(2));
    });

    test('der Stab sammelt Mana mit jedem Treffer', () {
      // Giftmoor leert das Mana, ohne die Nachbarn sofort zu töten.
      final welt = _eng(
        weapon: 'staff_gather',
        abilities: const <String>['giftmoor'],
      );
      welt.cast('giftmoor');
      final vorher = welt.mana;

      welt.step(Vec2.zero);

      // Ein Schritt Regeneration allein brächte keinen ganzen Punkt.
      expect(welt.mana, greaterThanOrEqualTo(vorher + 3));
    });

    test('die Sonnenklinge lässt brennen', () {
      // Ein frischer Held: Ein toter Gegner brennt nicht mehr.
      final welt = _eng(weapon: 'sunblade_flare', stats: ActionStats.frisch);
      welt.step(Vec2.zero);

      expect(welt.views.where((v) => v.isBurning), isNotEmpty);
    });

    test('jede Waffe hat eine eigene Id und wirkt', () {
      final ids = PitWeapons.all.map((w) => w.moveId).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final waffe in PitWeapons.all) {
        expect(waffe.power, greaterThan(0), reason: waffe.moveId);
      }
    });
  });

  // Über alle Waffen und alle neunzehn Fähigkeiten: Keine Wirkung darf
  // einen Lauf festfahren. Dieselbe Sorge wie `termination_test.dart` im
  // Rundenkampf.
  test('jeder Lauf endet, mit jeder Waffe und jeder Fähigkeit', () {
    for (final waffe in PitWeapons.all) {
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: PitStage(2), seed: 5),
        heroStats: ActionStats.gereift,
        stage: PitStage(2),
        weaponMoveId: waffe.moveId,
        abilityIds: const <String>['wurzelgriff', 'giftmoor', 'aurastrom'],
        seed: 5,
      );
      PitBot.play(welt);
      expect(welt.isOver, isTrue, reason: waffe.moveId);
    }
    for (final ability in PitAbilities.all) {
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: PitStage(2), seed: 6),
        heroStats: ActionStats.gereift,
        stage: PitStage(2),
        abilityIds: <String>[ability.id],
        seed: 6,
      );
      PitBot.play(welt);
      expect(welt.isOver, isTrue, reason: ability.id);
    }
  });
}

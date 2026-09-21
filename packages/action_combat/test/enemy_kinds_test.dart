import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Kobold und Troll — die zwei Gegnerarten neben Fussvolk, Schütze und
/// Wächter. Geprüft wird das **Verhalten**, nicht der Katalogeintrag
/// (`gotchas.md`: ein Feld, das nur geschrieben wird, meldet sich nie).
void main() {
  group('Karten lesen', () {
    test('k ist ein Kobold, t ein Troll', () {
      final level = Level.parse('Probe', const <String>[
        '#######',
        '#@.k.t#',
        '#....B#',
        '#######',
      ]);

      expect(
        level.spawns.map((s) => s.kind),
        containsAll(<EnemyKind>[EnemyKind.flink, EnemyKind.brocken]),
      );
      expect(level.problems, isEmpty);
    });
  });

  group('Der Kobold', () {
    test('ist schneller als der Held', () {
      expect(ActionBalance.flinkSpeed, greaterThan(ActionBalance.heroSpeed));
    });

    test('holt einen weglaufenden Helden ein', () {
      // Ein langer Gang: Der Held läuft nach rechts davon, der Kobold
      // kommt von links. Fussvolk bliebe zurück, der Kobold nicht.
      final welt = ActionWorld(
        level: Level.parse('Gang', <String>[
          '#' * 60,
          '#k.@${'.' * 54}B#',
          '#' * 60,
        ]),
        heroStats: const ActionStats(
          attack: 1,
          maxHp: 9999,
          defense: 0,
          energy: 8,
        ),
      );

      var getroffen = false;
      for (var i = 0; i < 60 * 8 && !getroffen; i++) {
        welt.step(const Vec2(1, 0));
        getroffen = welt.drainEvents().any(
              (e) => e is HitLanded && e.targetFaction == Faction.held,
            );
      }
      expect(getroffen, isTrue);
    });
  });

  group('Der Troll', () {
    ActionWorld mitTroll() {
      return ActionWorld(
        level: Level.parse('Höhle', const <String>[
          '#########',
          '#@t....B#',
          '#########',
        ]),
        heroStats: ActionStats.gereift,
        seed: 2,
      );
    }

    test('hält einiges aus — mehr als ein Schlag', () {
      final welt = mitTroll();
      welt.step(Vec2.zero);
      final troll = welt.views.firstWhere((v) => v.kind == EnemyKind.brocken);
      expect(troll.isAlive, isTrue);
      expect(troll.hpRatio, greaterThan(0.5));
    });

    test('lässt sich nicht zurückstossen', () {
      final welt = mitTroll();
      final vorher =
          welt.views.firstWhere((v) => v.kind == EnemyKind.brocken).position;
      // Er steht in Reichweite; der erste Schlag fällt sofort.
      welt.step(Vec2.zero);
      final nachher =
          welt.views.firstWhere((v) => v.kind == EnemyKind.brocken).position;
      expect(nachher.x, lessThanOrEqualTo(vorher.x));
    });

    test('lässt immer eine Heilkugel fallen', () {
      for (var seed = 0; seed < 5; seed++) {
        final welt = ActionWorld(
          level: Level.parse('Höhle', const <String>[
            '#########',
            '#@t....B#',
            '#########',
          ]),
          heroStats: const ActionStats(
            attack: 400,
            maxHp: 9999,
            defense: 99,
            energy: 8,
          ),
          seed: seed,
        );

        var kugel = false;
        for (var i = 0; i < 120 && !kugel; i++) {
          welt.step(Vec2.zero);
          kugel = welt.drainEvents().any((e) => e is OrbDropped);
        }
        expect(kugel, isTrue, reason: 'Startwert $seed');
      }
    });
  });

  group('Der Zufallsbau setzt Trolle', () {
    int trolle(int stufe) {
      var summe = 0;
      for (var seed = 0; seed < 80; seed++) {
        summe += LevelBuilder.build(stage: PitStage(stufe), seed: seed)
            .spawns
            .where((s) => s.kind == EnemyKind.brocken)
            .length;
      }
      return summe;
    }

    test('schon auf Stufe 1 gelegentlich', () {
      expect(trolle(1), greaterThan(0));
    });

    test('auf Stufe 30 deutlich öfter', () {
      expect(trolle(30), greaterThan(trolle(1) * 2));
    });

    test('er ersetzt Fussvolk, statt dazuzukommen', () {
      // Dieselbe Karte ohne Troll-Regel gibt es nicht zu bauen — also
      // umgekehrt: Kein gebauter Raum hat mehr Gegner als sein Baustein.
      final groesster = RoomCatalog.rooms
          .map((r) => r.join().split('').where('ekst'.contains).length)
          .reduce((a, b) => a > b ? a : b);
      for (var seed = 0; seed < 40; seed++) {
        final level = LevelBuilder.build(stage: PitStage(30), seed: seed);
        final raeume = PitStage(30).roomCount;
        final bossRaum = RoomCatalog.bossRooms
            .map((r) => r.join().split('').where('ekstB'.contains).length)
            .reduce((a, b) => a > b ? a : b);
        expect(
          level.spawns.length,
          lessThanOrEqualTo(groesster * raeume + bossRaum),
          reason: 'Startwert $seed',
        );
      }
    });
  });
}

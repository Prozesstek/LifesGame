import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

void main() {
  group('Die Raumbausteine', () {
    test('jeder Raum hat genau die vereinbarte Grösse', () {
      for (final raum in RoomCatalog.all) {
        expect(raum, hasLength(RoomCatalog.height));
        for (final zeile in raum) {
          expect(zeile, hasLength(RoomCatalog.width), reason: zeile);
        }
      }
    });

    test('nur Wächterräume tragen einen Wächter, und jeder genau einen', () {
      int waechter(List<String> raum) =>
          raum.join().split('').where((c) => c == 'B').length;

      for (final raum in RoomCatalog.bossRooms) {
        expect(waechter(raum), 1);
      }
      for (final raum in <List<String>>[
        RoomCatalog.startRoom,
        ...RoomCatalog.rooms,
      ]) {
        expect(waechter(raum), 0);
      }
    });

    test('der Startraum ist leer', () {
      expect(RoomCatalog.startRoom.join(), matches(RegExp(r'^[.#]+$')));
    });
  });

  group('Der Zufallsbau', () {
    // Über alle Stufen und viele Startwerte: Das ist die Prüfung, dass
    // **jeder** Raum in **jeder** Lage trägt — kein Gegner eingemauert,
    // genau ein Wächter, geschlossen nach aussen.
    test('jede gebaute Grube trägt', () {
      for (var stufe = 1; stufe <= PitStage.count; stufe++) {
        for (var seed = 0; seed < 40; seed++) {
          final level = LevelBuilder.build(stage: PitStage(stufe), seed: seed);
          expect(
            level.problems,
            isEmpty,
            reason: 'Stufe $stufe, Startwert $seed',
          );
        }
      }
    });

    test('derselbe Startwert ergibt dieselbe Karte', () {
      final a = LevelBuilder.build(stage: PitStage(12), seed: 99);
      final b = LevelBuilder.build(stage: PitStage(12), seed: 99);

      expect(a.tiles, b.tiles);
      expect(
        a.spawns.map((s) => '${s.kind}${s.tileX},${s.tileY}'),
        b.spawns.map((s) => '${s.kind}${s.tileX},${s.tileY}'),
      );
    });

    test('verschiedene Startwerte ergeben verschiedene Karten', () {
      final karten = <String>{
        for (var seed = 0; seed < 20; seed++)
          LevelBuilder.build(stage: PitStage(5), seed: seed)
              .tiles
              .map((z) => z.map((t) => t.index).join())
              .join('|'),
      };

      expect(karten.length, greaterThan(10));
    });

    test('tiefere Stufen haben mehr Räume und damit mehr Gegner', () {
      double schnitt(int stufe) {
        var summe = 0;
        for (var seed = 0; seed < 60; seed++) {
          summe += LevelBuilder.build(stage: PitStage(stufe), seed: seed)
              .spawns
              .length;
        }
        return summe / 60;
      }

      expect(schnitt(30), greaterThan(schnitt(1)));
    });

    test('ein ganzer Lauf auf einer gebauten Karte endet', () {
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: PitStage(1), seed: 3),
        heroStats: ActionStats.gereift,
        stage: PitStage(1),
        seed: 3,
      );

      PitBot.play(welt);

      expect(welt.isOver, isTrue);
    });
  });

  group('Die Stufen', () {
    test('Stufen ausserhalb werden auf den Rand gezogen', () {
      expect(PitStage(0).number, 1);
      expect(PitStage(99).number, PitStage.count);
    });

    test('kein Wert fällt von einer Stufe zur nächsten', () {
      for (var n = 2; n <= PitStage.count; n++) {
        final vorher = PitStage(n - 1);
        final jetzt = PitStage(n);
        expect(jetzt.hpFactor, greaterThan(vorher.hpFactor));
        expect(jetzt.attackFactor, greaterThan(vorher.attackFactor));
        expect(jetzt.defenseBonus, greaterThanOrEqualTo(vorher.defenseBonus));
        expect(jetzt.roomCount, greaterThanOrEqualTo(vorher.roomCount));
      }
    });

    // Ein Test aufs **Verhalten**, nicht auf den Faktor: Ein Feld, das
    // Verhalten steuern soll und nirgends gelesen wird, meldet sich nie
    // (`gotchas.md`, `EnemyBlueprint.loadout`).
    test('dieselbe Halle ist auf Stufe 30 härter als auf Stufe 1', () {
      ActionWorld lauf(int stufe) {
        final welt = ActionWorld(
          level: LevelCatalog.grube,
          heroStats: ActionStats.gereift,
          stage: PitStage(stufe),
          seed: 7,
        );
        PitBot.play(welt);
        return welt;
      }

      final leicht = lauf(1);
      final schwer = lauf(30);

      expect(leicht.isWon, isTrue);
      final leichterDurch = !schwer.isWon ||
          schwer.elapsed > leicht.elapsed ||
          schwer.heroHpRatio < leicht.heroHpRatio;
      expect(leichterDurch, isTrue);
    });
  });

  group('Der Wächter wird gewürfelt (ADR-0062)', () {
    /// Die Karte als Text — Wände, Boden und wo wer steht.
    String bild(Level level) {
      final zeilen = <String>[
        for (var y = 0; y < level.height; y++)
          <String>[
            for (var x = 0; x < level.width; x++)
              level.tileAt(x, y) == Tile.wand ? '#' : '.',
          ].join(),
        for (final s in level.spawns) '${s.kind.name}@${s.tileX},${s.tileY}',
      ];
      return zeilen.join('\n');
    }

    test('derselbe Startwert ergibt denselben Wächter', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(LevelBuilder.bossFor(seed), LevelBuilder.bossFor(seed));
        expect(
          LevelBuilder.build(stage: PitStage(1), seed: seed).boss,
          LevelBuilder.bossFor(seed),
        );
      }
    });

    test('schon auf Stufe 1 kommt jeder der vier vor', () {
      // Frederik, 01.10.: alles ab Stufe 1. Die Tiefe regelt, was ein
      // Wächter kann, nicht, welcher kommt.
      final gesehen = <BossKind>{
        for (var seed = 0; seed < 60; seed++)
          LevelBuilder.build(stage: PitStage(1), seed: seed).boss,
      };
      expect(gesehen, BossKind.values.toSet());
    });

    test('keiner kommt viel öfter als die anderen', () {
      final zaehler = <BossKind, int>{};
      const wuerfe = 4000;
      for (var seed = 0; seed < wuerfe; seed++) {
        zaehler.update(
          LevelBuilder.bossFor(seed),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
      const erwartet = wuerfe / 4;
      for (final boss in BossKind.values) {
        expect(
          zaehler[boss],
          inInclusiveRange(erwartet * 0.85, erwartet * 1.15),
          reason: boss.name,
        );
      }
    });

    test('der Wächter verschiebt die Karte nicht', () {
      // Er hat einen eigenen Würfel. Zöge er aus dem der Karte, ergäbe
      // derselbe Startwert je Wächter eine andere Grube — und jeder
      // Startwert eine andere als vor ADR-0062.
      for (var seed = 0; seed < 20; seed++) {
        Level mit(BossKind boss) =>
            LevelBuilder.build(stage: PitStage(12), seed: seed, boss: boss);
        final karten = <String>{
          for (final boss in BossKind.values) bild(mit(boss)),
        };
        expect(karten, hasLength(1), reason: 'Startwert $seed');
      }
    });

    test('das Tor zu schliessen ändert den Wächter nicht', () {
      // `withGates` baut eine zweite Karte; ein vergessenes Feld fiele
      // dort still auf den Zyklopen zurück (`gotchas.md`).
      for (final boss in BossKind.values) {
        final level =
            LevelBuilder.build(stage: PitStage(1), seed: 1, boss: boss);
        expect(level.withGates(closed: true).boss, boss);
      }
    });

    test('jeder Wächter steht in einer Grube, die trägt', () {
      for (final boss in BossKind.values) {
        for (var seed = 0; seed < 10; seed++) {
          final level = LevelBuilder.build(
            stage: PitStage(30),
            seed: seed,
            boss: boss,
          );
          expect(level.problems, isEmpty, reason: '$boss, Startwert $seed');
        }
      }
    });
  });
}

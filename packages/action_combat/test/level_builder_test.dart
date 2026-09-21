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
}

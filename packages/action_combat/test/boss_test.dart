import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein Raum mit dem Wächter allein. Der Held steht [abstand] Felder links
/// von ihm und schlägt nicht zu (Angriff 0 → Mindestschaden 1), damit der
/// Wächter lange genug lebt, um alles zu zeigen.
ActionWorld _arena({int abstand = 2}) {
  final zeile = '#${'.' * 3}@${'.' * (abstand - 1)}B${'.' * 12}#';
  return ActionWorld(
    level: Level.parse('Arena', <String>[
      '#' * zeile.length,
      '#${'.' * (zeile.length - 2)}#',
      '#${'.' * (zeile.length - 2)}#',
      zeile,
      '#${'.' * (zeile.length - 2)}#',
      '#${'.' * (zeile.length - 2)}#',
      '#' * zeile.length,
    ]),
    heroStats: const ActionStats(
      attack: 0,
      maxHp: 99999,
      defense: 0,
      energy: 8,
    ),
  );
}

List<ActionEvent> _laufen(ActionWorld welt, int schritte, [Vec2? eingabe]) {
  final alle = <ActionEvent>[];
  for (var i = 0; i < schritte; i++) {
    welt.step(eingabe ?? Vec2.zero);
    alle.addAll(welt.drainEvents());
  }
  return alle;
}

int _schadenAmHelden(List<ActionEvent> events) => events
    .whereType<HitLanded>()
    .where((e) => e.targetFaction == Faction.held)
    .fold<int>(0, (s, e) => s + e.amount);

void main() {
  group('Der Wächter ist allein', () {
    test('kein Wächterraum hat Begleiter', () {
      for (final raum in RoomCatalog.bossRooms) {
        final gegner = raum.join().split('').where('eskt'.contains);
        expect(gegner, isEmpty);
        expect(raum.join().split('').where((c) => c == 'B'), hasLength(1));
      }
    });
  });

  group('Bodenstoss', () {
    test('kündigt sich an, bevor er trifft', () {
      final welt = _arena();
      final ereignisse = <ActionEvent>[];
      var angekuendigt = false;
      for (var i = 0; i < 60 * 6 && !angekuendigt; i++) {
        welt.step(Vec2.zero);
        ereignisse.addAll(welt.drainEvents());
        angekuendigt = welt.telegraphs.any((t) => t.isRing);
      }

      expect(angekuendigt, isTrue);
      // In dem Moment, in dem der Ring erscheint, ist noch kein Stoss
      // gefallen.
      expect(ereignisse.whereType<BossSlammed>(), isEmpty);
    });

    test('wer drinbleibt, wird getroffen — wer hinausläuft, nicht', () {
      int schaden({required bool weglaufen}) {
        final welt = _arena();
        // Bis zur Ankündigung warten.
        while (!welt.telegraphs.any((t) => t.isRing)) {
          welt.step(Vec2.zero);
        }
        welt.drainEvents();
        final ereignisse = _laufen(
          welt,
          (ActionBalance.bossSlamWindup * 60).round() + 2,
          weglaufen ? const Vec2(-1, 0) : Vec2.zero,
        );
        expect(ereignisse.whereType<BossSlammed>(), hasLength(1));
        return _schadenAmHelden(ereignisse);
      }

      final drin = schaden(weglaufen: false);
      final draussen = schaden(weglaufen: true);

      expect(drin, greaterThan(draussen));
    });

    test('die Ankündigung ist lang genug, um hinauszulaufen', () {
      // Aus der Mitte des Rings bis über seinen Rand, mit Heldentempo.
      const noetig = (ActionBalance.bossSlamRadius + ActionBalance.heroRadius) /
          ActionBalance.heroSpeed;
      expect(ActionBalance.bossSlamWindup, greaterThan(noetig));
    });
  });

  group('Felswurf', () {
    test('auf Abstand wirft er einen grossen Brocken', () {
      final welt = _arena(abstand: 6);
      var brocken = false;
      for (var i = 0; i < 60 * 5 && !brocken; i++) {
        welt.step(Vec2.zero);
        brocken = welt.projectiles.any(
          (p) =>
              p.faction == Faction.gegner &&
              p.radius == ActionBalance.bossBoulderRadius,
        );
      }
      expect(brocken, isTrue);
    });
  });

  group('Er lernt mit der Tiefe', () {
    ActionWorld aufStufe(int stufe) {
      const zeile = '#...@.....B............#';
      return ActionWorld(
        level: Level.parse('Arena', <String>[
          '#' * zeile.length,
          '#${'.' * (zeile.length - 2)}#',
          zeile,
          '#${'.' * (zeile.length - 2)}#',
          '#' * zeile.length,
        ]),
        heroStats: const ActionStats(
          attack: 0,
          maxHp: 99999,
          defense: 0,
          energy: 8,
        ),
        stage: PitStage(stufe),
      );
    }

    bool wirft(ActionWorld welt) {
      for (var i = 0; i < 60 * 4; i++) {
        welt.step(Vec2.zero);
        if (welt.projectiles.any(
          (p) => p.radius == ActionBalance.bossBoulderRadius,
        )) {
          return true;
        }
      }
      return false;
    }

    test('auf Stufe 1 wirft er nicht', () {
      expect(wirft(aufStufe(1)), isFalse);
    });

    test('ab seiner Stufe wirft er', () {
      expect(wirft(aufStufe(ActionBalance.bossThrowFromStage)), isTrue);
    });

    test('der Ansturm kommt nach dem Wurf', () {
      expect(
        ActionBalance.bossChargeFromStage,
        greaterThan(ActionBalance.bossThrowFromStage),
      );
    });
  });

  group('Wut und Ansturm', () {
    test('ohne Wut kein Ansturm', () {
      final welt = _arena(abstand: 6);
      var linie = false;
      for (var i = 0; i < 60 * 12 && !linie; i++) {
        welt.step(Vec2.zero);
        linie = welt.telegraphs.any((t) => !t.isRing);
      }
      expect(linie, isFalse);
      expect(welt.isBossEnraged, isFalse);
    });

    test('unter halbem Leben wird er wütend und stürmt an', () {
      // Ein paar harte Schläge bringen ihn unter die Hälfte, dann läuft
      // der Held davon. Auf Abstand und wütend muss er anstürmen.
      //
      // Seit der Held breit streut (60–140 %) reicht ein einziger Schlag
      // nicht mehr sicher — und einer, der sicher reicht, könnte mit
      // einem kritischen Treffer den Wächter gleich ganz fällen.
      final welt = ActionWorld(
        level: Level.parse('Halle', <String>[
          '#' * 42,
          '#${'.' * 40}#',
          '#${'.' * 29}@B${'.' * 9}#',
          '#${'.' * 40}#',
          '#' * 42,
        ]),
        heroStats: const ActionStats(
          attack: 150,
          maxHp: 99999,
          defense: 0,
          energy: 8,
        ),
      );

      final ereignisse = <ActionEvent>[];
      for (var i = 0;
          i < 60 * 3 &&
              (welt.bossView?.hpRatio ?? 0) >= ActionBalance.bossEnrageAt;
          i++) {
        welt.step(Vec2.zero);
        ereignisse.addAll(welt.drainEvents());
      }
      expect(welt.bossView?.hpRatio, lessThan(ActionBalance.bossEnrageAt));

      var linie = false;
      for (var i = 0; i < 60 * 8 && !linie && !welt.isOver; i++) {
        welt.step(const Vec2(-1, 0));
        ereignisse.addAll(welt.drainEvents());
        linie = welt.telegraphs.any((t) => !t.isRing);
      }

      expect(ereignisse.whereType<BossEnraged>(), hasLength(1));
      expect(welt.isBossEnraged, isTrue);
      expect(linie, isTrue);
    });
  });

  test('die Ankündigung sagt, wer drinsteht', () {
    const ring = TelegraphView(
      move: BossMove.bodenstoss,
      origin: Vec2(0, 0),
      radius: 50,
      direction: Vec2.zero,
      length: 0,
      progress: 0.5,
    );
    expect(ring.covers(const Vec2(40, 0), 5), isTrue);
    expect(ring.covers(const Vec2(80, 0), 5), isFalse);

    const linie = TelegraphView(
      move: BossMove.ansturm,
      origin: Vec2(0, 0),
      radius: 20,
      direction: Vec2(1, 0),
      length: 200,
      progress: 0.5,
    );
    expect(linie.covers(const Vec2(150, 10), 5), isTrue);
    expect(linie.covers(const Vec2(150, 60), 5), isFalse);
    expect(linie.covers(const Vec2(-60, 0), 5), isFalse);
  });

  test('ein Lauf mit dem Wächter endet, auch für den Bot', () {
    for (var seed = 0; seed < 5; seed++) {
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: PitStage(1), seed: seed),
        heroStats: ActionStats.gereift,
        stage: PitStage(1),
        weaponMoveId: 'sword_strike',
        seed: seed,
      );
      PitBot.play(welt);
      expect(welt.isOver, isTrue, reason: 'Startwert $seed');
    }
  });
}

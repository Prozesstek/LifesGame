import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/kampfgefuehl.dart';
import 'package:lifes_game/audio/sound_effects.dart';

/// Merkt sich, was gespielt werden sollte, statt es zu spielen.
class _Mitschrift implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

const double _bild = 1 / 60;

void main() {
  group('Trefferstopp', () {
    test('hält die Welt fünfzig Millisekunden an', () {
      final stopp = Trefferstopp()..ausloesen();

      expect(stopp.haelt, isTrue);
      expect(stopp.zeit(0.03), 0);
      // Der Stopp endet mitten im Bild: Der Rest gehört der Welt.
      expect(stopp.zeit(0.03), closeTo(0.01, 1e-9));
      expect(stopp.haelt, isFalse);
      expect(stopp.zeit(0.03), 0.03);
    });

    test('ein zweiter Grund während des Stopps verlängert ihn nicht', () {
      final stopp = Trefferstopp()..ausloesen();
      stopp.zeit(0.04);
      stopp.ausloesen();

      expect(stopp.zeit(0.02), closeTo(0.01, 1e-9));
      expect(stopp.haelt, isFalse);
    });

    test('gleich danach folgt keiner, nach der Pause wieder', () {
      final stopp = Trefferstopp()..ausloesen();
      stopp.zeit(Trefferstopp.dauer);

      stopp.ausloesen();
      expect(stopp.haelt, isFalse, reason: 'sonst stottert das Bild');

      stopp.zeit(Trefferstopp.pause + 0.001);
      stopp.ausloesen();
      expect(stopp.haelt, isTrue);
    });

    test('ohne vergangene Zeit geschieht nichts', () {
      // Flame ruft `update(0)` aus dem Bau heraus (`gotchas.md`).
      final stopp = Trefferstopp()..ausloesen();

      expect(stopp.zeit(0), 0);
      expect(stopp.haelt, isTrue);
    });
  });

  group('Beben', () {
    test('klingt ab und hört auf', () {
      final beben = Beben()
        ..stoss(dauer: Beben.trefferDauer, staerke: Beben.trefferStaerke);

      expect(beben.staerke, closeTo(Beben.trefferStaerke, 1e-9));
      beben.advance(Beben.trefferDauer / 2);
      expect(beben.staerke, closeTo(Beben.trefferStaerke / 2, 1e-9));
      beben.advance(Beben.trefferDauer);
      expect(beben.staerke, 0);
      expect(beben.versatz, ui.Offset.zero);
    });

    test('ein Treffer kürzt die Landung des Wächters nicht ab', () {
      final beben = Beben()
        ..stoss(dauer: Beben.landungDauer, staerke: Beben.landungStaerke)
        ..stoss(dauer: Beben.trefferDauer, staerke: Beben.trefferStaerke);

      expect(beben.staerke, closeTo(Beben.landungStaerke, 1e-9));
    });

    test('der Versatz bleibt innerhalb der Stärke', () {
      final beben = Beben()
        ..stoss(dauer: Beben.landungDauer, staerke: Beben.landungStaerke);

      for (var i = 0; i < 20; i++) {
        beben.advance(Beben.landungDauer / 20);
        expect(beben.versatz.dx.abs(), lessThanOrEqualTo(beben.staerke + 1e-9));
        expect(beben.versatz.dy.abs(), lessThanOrEqualTo(beben.staerke + 1e-9));
      }
    });
  });

  group('Der rote Rand', () {
    test('steht nur unter einem Viertel Leben', () {
      expect(LebensRand.deckkraft(1, 3), 0);
      expect(LebensRand.deckkraft(LebensRand.schwelle, 3), 0);
      expect(LebensRand.deckkraft(0.24, 3), greaterThan(0));
    });

    test('ein gefallener Held hat keinen mehr', () {
      expect(LebensRand.deckkraft(0, 3), 0);
    });

    test('wird kräftiger, je weniger Leben bleibt', () {
      // Zur selben Zeit gemessen, damit der Puls nicht mitredet.
      expect(
        LebensRand.deckkraft(0.05, 0),
        greaterThan(LebensRand.deckkraft(0.2, 0)),
      );
    });

    test('bleibt zu jeder Zeit sichtbar und nie über voll', () {
      for (var zeit = 0.0; zeit < 3; zeit += 0.05) {
        final wert = LebensRand.deckkraft(0.2, zeit);
        expect(wert, greaterThan(0.2));
        expect(wert, lessThanOrEqualTo(1));
      }
    });
  });

  group('KampfKlang', () {
    test('zehn Treffer in einem Bild sind ein Klang', () {
      final klaenge = KampfKlang();
      for (var i = 0; i < 10; i++) {
        klaenge.melde(SoundEffect.treffer);
      }

      expect(klaenge.abholen(_bild), <SoundEffect>[SoundEffect.treffer]);
      expect(klaenge.abholen(_bild), isEmpty);
    });

    test('ein Kill schluckt den Treffer, der ihn gebracht hat', () {
      final klaenge = KampfKlang()
        ..melde(SoundEffect.treffer)
        ..melde(SoundEffect.gefallen);

      expect(klaenge.abholen(_bild), <SoundEffect>[SoundEffect.gefallen]);
    });

    test('derselbe Klang folgt nie dichter als der Abstand', () {
      final klaenge = KampfKlang()..melde(SoundEffect.treffer);
      klaenge.abholen(_bild);

      klaenge.melde(SoundEffect.treffer);
      expect(klaenge.abholen(_bild), isEmpty);

      klaenge.melde(SoundEffect.treffer);
      expect(klaenge.abholen(KampfKlang.abstand), <SoundEffect>[
        SoundEffect.treffer,
      ]);
    });

    test('verschiedene Klänge halten einander nicht auf', () {
      final klaenge = KampfKlang()..melde(SoundEffect.treffer);
      klaenge.abholen(_bild);

      klaenge.melde(SoundEffect.faehigkeit);
      expect(klaenge.abholen(_bild), <SoundEffect>[SoundEffect.faehigkeit]);
    });
  });

  group('In der Grube', () {
    /// Zwei Gegner in Reichweite: Fällt der erste, läuft der Lauf weiter.
    final gedraenge = Level.parse('Gedränge', const <String>[
      '########',
      '#......#',
      '#..e@e.#',
      '#......#',
      '########',
    ]);

    /// Acht Gegner um einen frischen Helden: Er verliert, und zwar in
    /// kleinen Schritten.
    final umzingelt = Level.parse('Umzingelt', const <String>[
      '#########',
      '#.......#',
      '#..eee..#',
      '#..e@e..#',
      '#..eee..#',
      '#.......#',
      '#########',
    ]);

    (ActionGame, _Mitschrift) lauf(
      ActionStats werte, {
      List<String>? plaetze,
      Level? level,
    }) {
      final mitschrift = _Mitschrift();
      final game = ActionGame(
        klang: mitschrift,
        startXp: null,
        sim: ActionWorld(
          level: level ?? gedraenge,
          heroStats: werte,
          abilityIds: plaetze ?? const <String>[],
        ),
      );
      addTearDown(game.frame.dispose);
      return (game, mitschrift);
    }

    /// Lässt Bilder laufen, bis [fertig] gilt — höchstens zwanzig Sekunden.
    void bis(ActionGame game, bool Function() fertig) {
      for (var i = 0; i < 1200 && !fertig(); i++) {
        game.update(_bild);
      }
      expect(fertig(), isTrue, reason: 'in zwanzig Sekunden nicht erreicht');
    }

    test('ein Treffer des Helden klingt', () {
      final (game, mitschrift) = lauf(ActionStats.gereift);

      bis(game, () => mitschrift.gespielt.contains(SoundEffect.treffer));
    });

    test('fällt ein Gegner, klingt es, und das Bild steht', () {
      final (game, mitschrift) = lauf(ActionStats.gereift);

      bis(game, () => mitschrift.gespielt.contains(SoundEffect.gefallen));

      expect(game.haelt, isTrue);
      expect(game.sim.isOver, isFalse);
      // Solange das Bild steht, vergeht in der Welt keine Zeit — die Uhr
      // des Laufs zahlt den Stopp nicht.
      final vorher = game.sim.elapsed;
      game.update(Trefferstopp.dauer / 2);
      expect(game.sim.elapsed, vorher);
      expect(game.haelt, isTrue);

      // Danach läuft sie weiter. Die Welt rechnet in festen Schritten,
      // deshalb „mehr als vorher“ statt einer genauen Zahl.
      game.update(Trefferstopp.dauer);
      expect(game.haelt, isFalse);
      expect(game.sim.elapsed, greaterThan(vorher));
    });

    test('wird der Held getroffen, klingt es anders, und das Bild bebt', () {
      final (game, mitschrift) = lauf(ActionStats.frisch);

      bis(game, () => mitschrift.gespielt.contains(SoundEffect.getroffen));

      expect(game.bebenStaerke, greaterThan(0));
      expect(game.bebenStaerke, lessThanOrEqualTo(Beben.trefferStaerke + 1e-9));
    });

    test('eine gewirkte Fähigkeit klingt', () {
      final (game, mitschrift) = lauf(
        ActionStats.gereift,
        plaetze: const <String>['steinhaut'],
      );

      expect(game.sim.cast('steinhaut'), isTrue);
      game.update(_bild);

      expect(mitschrift.gespielt, contains(SoundEffect.faehigkeit));
    });

    test('holt der Wächter aus, klingt die Ankündigung', () {
      final halle = Level.parse('Halle', const <String>[
        '##########',
        '#........#',
        '#..@..B..#',
        '#........#',
        '##########',
      ]);
      final (game, mitschrift) = lauf(ActionStats.gereift, level: halle);

      bis(game, () => game.sim.telegraphs.isNotEmpty);

      expect(mitschrift.gespielt, contains(SoundEffect.ankuendigung));
    });

    test('der rote Rand lässt sich zeichnen', () {
      final (game, _) = lauf(ActionStats.frisch, level: umzingelt);
      game.onGameResize(Vector2(390, 844));

      bis(
        game,
        () =>
            game.sim.isOver || game.sim.heroView.hpRatio < LebensRand.schwelle,
      );
      expect(
        game.sim.heroView.hpRatio,
        inExclusiveRange(0, LebensRand.schwelle),
        reason: 'der Held soll wenig Leben haben, nicht keines',
      );

      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    });
  });
}

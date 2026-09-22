import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein Vorraum oben, der Wächterraum unten, dazwischen ein Tor aus zwei
/// Feldern. Der Held steht genau darüber.
final Level _halle = Level.parse('Tor', const <String>[
  '##############',
  '#......@.....#',
  '#............#',
  '#######==#####',
  '#............#',
  '#............#',
  '#......B.....#',
  '##############',
]);

/// Dasselbe mit einem Gegner im Vorraum. Er bemerkt den Helden sofort,
/// ist aber zu weit weg, um vor dem Tor bei ihm zu sein.
final Level _mitVerfolger = Level.parse('Tor mit Verfolger', const <String>[
  '################',
  '#......@.....e.#',
  '#..............#',
  '#######==#######',
  '#............#',
  '#............#',
  '#......B.....#',
  '##############',
]);

/// Stark genug, um den Wächter sicher zu fällen, und zäh genug, um dabei
/// nicht zu fallen.
const _riese = ActionStats(attack: 400, maxHp: 9000, defense: 200, energy: 16);

const _tor = (7, 3);

/// Läuft [schritte] lang in Richtung [eingabe] und sammelt die Ereignisse.
List<ActionEvent> _laufe(ActionWorld welt, Vec2 eingabe, int schritte) {
  final ereignisse = <ActionEvent>[];
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(eingabe);
    ereignisse.addAll(welt.drainEvents());
  }
  return ereignisse;
}

/// Läuft hinunter, bis das Tor zu ist, und gibt die Schritte zurück.
int _hinein(ActionWorld welt) {
  var schritte = 0;
  while (!welt.level.gatesClosed && schritte < 300) {
    welt.step(const Vec2(0, 1));
    schritte++;
  }
  expect(welt.level.gatesClosed, isTrue, reason: 'Das Tor fiel nie zu.');
  return schritte;
}

const _auftritt = ActionBalance.bossEntranceSeconds;
final int _auftrittSchritte = (_auftritt / ActionBalance.stepSeconds).ceil();

void main() {
  group('Die Karte', () {
    test('das Tor ist Boden, bis es zufällt', () {
      expect(
        _mitVerfolger.isHealthy,
        isTrue,
        reason: _mitVerfolger.problems.join('\n'),
      );
      expect(_halle.isGateAt(_tor.$1, _tor.$2), isTrue);
      expect(_halle.isWallAt(_tor.$1, _tor.$2), isFalse);
      expect(
        _halle.withGates(closed: true).isWallAt(_tor.$1, _tor.$2),
        isTrue,
      );
    });

    test('der Wächterraum endet am Tor', () {
      expect(_halle.isArenaAt(7, 6), isTrue); // der Wächter
      expect(_halle.isArenaAt(1, 4), isTrue);
      expect(_halle.isArenaAt(_tor.$1, _tor.$2), isFalse);
      expect(_halle.isArenaAt(7, 1), isFalse); // der Held
    });

    test('ein Held hinter dem Tor ist ein Fehler der Karte', () {
      final falsch = Level.parse('falsch', const <String>[
        '########',
        '#..e...#',
        '###==###',
        '#.@..B.#',
        '########',
      ]);
      expect(falsch.problems, isNotEmpty);
    });

    test('jede gebaute Grube hat ein Tor vor dem Wächter', () {
      for (var stufe = 1; stufe <= PitStage.count; stufe += 7) {
        for (var seed = 0; seed < 10; seed++) {
          final level = LevelBuilder.build(
            stage: PitStage(stufe),
            seed: seed,
          );
          expect(level.hasGates, isTrue, reason: 'Stufe $stufe, $seed');
          expect(level.isHealthy, isTrue, reason: level.problems.join('\n'));
        }
      }
    });
  });

  group('In der Grube', () {
    test('das Tor fällt zu, sobald der Held ganz drin ist', () {
      final welt = ActionWorld(level: _halle, heroStats: ActionStats.gereift);

      // Ein Stück hinunter: im Tor, noch nicht drin.
      final erst = _laufe(welt, const Vec2(0, 1), 30);
      expect(erst.whereType<GateClosed>(), isEmpty);
      expect(welt.level.gatesClosed, isFalse);

      final dann = _laufe(welt, const Vec2(0, 1), 60);
      expect(dann.whereType<GateClosed>(), hasLength(1));
      expect(welt.level.isWallAt(_tor.$1, _tor.$2), isTrue);
    });

    test('zurück geht es nicht, solange der Wächter lebt', () {
      final welt = ActionWorld(level: _halle, heroStats: ActionStats.gereift);
      _laufe(welt, const Vec2(0, 1), 90);
      expect(welt.level.gatesClosed, isTrue);

      _laufe(welt, const Vec2(0, -1), 120);
      const size = ActionBalance.tileSize;
      expect(welt.heroView.position.y, greaterThan(4 * size));
    });

    test('wer draussen ist, bleibt draussen', () {
      final welt = ActionWorld(
        level: _mitVerfolger,
        heroStats: ActionStats.gereift,
      );
      EntityView verfolger() =>
          welt.views.firstWhere((v) => v.kind == EnemyKind.fussvolk);
      final start = verfolger().position;

      _laufe(welt, const Vec2(0, 1), 90);
      expect(welt.level.gatesClosed, isTrue);

      // Der Held wartet unten; der Verfolger kommt nicht durch, solange
      // das Tor zu ist.
      const size = ActionBalance.tileSize;
      for (var i = 0; i < 60 * 3 && welt.level.gatesClosed; i++) {
        welt.step(Vec2.zero);
        final draussen = welt.views.where((v) => v.kind == EnemyKind.fussvolk);
        expect(draussen, isNotEmpty);
        expect(draussen.first.position.y, lessThan(3 * size));
      }
      // Er ist losgelaufen — sonst bewiese der Test nichts. Seit das Tor
      // zu ist, steht er, statt gegen die Wand zu drücken.
      expect(verfolger().position.x, lessThan(start.x - size));
    });

    test('fällt der Wächter, ist der Lauf gewonnen — draussen egal', () {
      // Der Verfolger bleibt vor dem Tor stehen und lebt. Die Grube ist
      // trotzdem geschafft: Sie endet mit dem Wächter.
      final welt = ActionWorld(level: _mitVerfolger, heroStats: _riese);
      final ereignisse = _laufe(welt, const Vec2(0, 1), 60 * 10);

      expect(welt.isOver, isTrue);
      expect(welt.bossView, isNull);
      expect(welt.views.where((v) => v.kind == EnemyKind.fussvolk), isNotEmpty);
      final ende = ereignisse.whereType<RunEnded>().single;
      expect(ende.won, isTrue);
      // Das Tor bleibt zu — es gibt keinen Grund mehr, es zu öffnen.
      expect(welt.level.gatesClosed, isTrue);
    });
  });

  group('Der Auftritt des Wächters', () {
    test('solange er schläft, ist er weder zu sehen noch im Balken', () {
      final welt = ActionWorld(level: _halle, heroStats: ActionStats.gereift);
      welt.step(Vec2.zero);

      expect(welt.views.where((v) => v.kind == EnemyKind.endgegner), isEmpty);
      expect(welt.bossView, isNull);
      expect(welt.bossEntrance, isNull);
      expect(welt.sleepingBossAt, isNotNull);
    });

    test('er fällt von oben herab und landet auf seinem Platz', () {
      final welt = ActionWorld(level: _halle, heroStats: ActionStats.gereift);
      final platz = welt.sleepingBossAt!;
      _hinein(welt);

      welt.step(Vec2.zero);
      final fallend =
          welt.views.firstWhere((v) => v.kind == EnemyKind.endgegner);
      expect(fallend.position.y, lessThan(platz.y - 100));
      expect(welt.bossView, isNull, reason: 'Noch nicht gelandet.');

      final ereignisse = _laufe(welt, Vec2.zero, _auftrittSchritte ~/ 2);
      expect(ereignisse.whereType<BossLanded>(), hasLength(1));
      final gelandet =
          welt.views.firstWhere((v) => v.kind == EnemyKind.endgegner);
      expect(gelandet.position.y, closeTo(platz.y, 0.001));
    });

    test('Name und Balken erst ab der Landung, der Balken läuft voll', () {
      final welt = ActionWorld(level: _halle, heroStats: ActionStats.gereift);
      _hinein(welt);
      expect(welt.bossBarFill, 0);

      var vorher = 0.0;
      for (var i = 0; i < _auftrittSchritte; i++) {
        welt.step(Vec2.zero);
        if (welt.bossView == null) continue;
        expect(welt.bossBarFill, greaterThanOrEqualTo(vorher));
        vorher = welt.bossBarFill;
      }
      expect(welt.bossView, isNotNull);
      expect(welt.bossBarFill, 1);
      expect(welt.bossEntrance, isNull, reason: 'Der Auftritt ist vorbei.');
    });

    test('während des Auftritts ist er unverwundbar und tut nichts', () {
      // Der Riese steht direkt unter ihm und schlägt von selbst zu.
      final welt = ActionWorld(level: _halle, heroStats: _riese);
      _hinein(welt);
      final ereignisse = _laufe(welt, const Vec2(0, 1), _auftrittSchritte - 2);

      expect(welt.bossEntrance, isNotNull);
      expect(welt.heroHp, welt.heroMaxHp);
      expect(
        ereignisse.whereType<HitLanded>(),
        isEmpty,
        reason: 'Niemand trifft, solange er auftritt.',
      );
      expect(welt.bossView?.hpRatio, 1);
    });

    test('danach kämpft er', () {
      final welt = ActionWorld(level: _halle, heroStats: _riese);
      _hinein(welt);
      final ereignisse = _laufe(welt, const Vec2(0, 1), _auftrittSchritte * 3);

      expect(ereignisse.whereType<HitLanded>(), isNotEmpty);
    });

    test('ohne Tor ist er von Anfang an da, wie bisher', () {
      final offen = Level.parse('offen', const <String>[
        '##########',
        '#@..e...B#',
        '##########',
      ]);
      final welt = ActionWorld(level: offen, heroStats: ActionStats.gereift);
      expect(welt.bossView, isNotNull);
      expect(welt.sleepingBossAt, isNull);
    });
  });
}

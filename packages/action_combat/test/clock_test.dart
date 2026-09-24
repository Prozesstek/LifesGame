import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die Uhr der Grube: ein Limit je Stufe, auffüllbar über Zeitkugeln.
/// Sie soll das Kiten beenden, nicht das Spielen.
void main() {
  const unverwundbar = ActionStats(
    attack: 0,
    maxHp: 9999999,
    defense: 999,
    energy: 8,
  );

  group('Das Limit', () {
    test('wächst mit den Räumen einer Stufe', () {
      expect(PitStage(1).timeLimitSeconds, 120);
      expect(PitStage(30).timeLimitSeconds, 170);
      for (var n = 2; n <= PitStage.count; n++) {
        expect(
          PitStage(n).timeLimitSeconds,
          greaterThanOrEqualTo(PitStage(n - 1).timeLimitSeconds),
        );
      }
    });

    test('lässt dem direkten Weg reichlich Luft', () {
      // Der Bot brauchte gemessen höchstens rund 17 s je Raum (samt
      // Wächterraum). Das Limit soll deutlich darüber liegen.
      for (var n = 1; n <= PitStage.count; n++) {
        final stufe = PitStage(n);
        expect(
          stufe.timeLimitSeconds,
          greaterThan(17 * (stufe.roomCount + 1) * 1.5),
          reason: 'Stufe $n',
        );
      }
    });
  });

  group('Ohne Stufe', () {
    test('gibt es keine Uhr', () {
      final welt = ActionWorld(
        level: LevelCatalog.grube,
        heroStats: unverwundbar,
      );
      expect(welt.timeLimit, isNull);
      expect(welt.timeLeft, isNull);
    });
  });

  group('Wenn die Uhr abläuft', () {
    test('ist der Lauf verloren, und das Ende sagt warum', () {
      // Ein Held, der nichts tut und dem nichts passiert: Er steht im
      // Startraum, niemand sieht ihn, der Wächter schläft.
      final stufe = PitStage(1);
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: stufe, seed: 1),
        heroStats: unverwundbar,
        stage: stufe,
        seed: 1,
      );

      RunEnded? ende;
      final schritte = (stufe.timeLimitSeconds + 1) * 60;
      for (var i = 0; i < schritte && ende == null; i++) {
        welt.step(Vec2.zero);
        ende = welt.drainEvents().whereType<RunEnded>().firstOrNull;
      }

      expect(ende, isNotNull);
      expect(ende!.won, isFalse);
      expect(ende.timedOut, isTrue);
      expect(ende.seconds, closeTo(stufe.timeLimitSeconds, 0.05));
      expect(welt.isTimedOut, isTrue);
      expect(welt.timeLeft, 0);
    });

    test('ein Tod ist kein Ablaufen', () {
      final welt = ActionWorld(
        level: Level.parse('Falle', const <String>[
          '#######',
          '#@eeeB#',
          '#######',
        ]),
        heroStats: const ActionStats(
          attack: 0,
          maxHp: 1,
          defense: 0,
          energy: 8,
        ),
        stage: PitStage(30),
      );
      RunEnded? ende;
      for (var i = 0; i < 60 * 20 && ende == null; i++) {
        welt.step(Vec2.zero);
        ende = welt.drainEvents().whereType<RunEnded>().firstOrNull;
      }
      expect(ende, isNotNull);
      expect(ende!.timedOut, isFalse);
    });
  });

  group('Zeitkugeln', () {
    /// Ein Saal voller Fussvolk direkt am Helden: Es wird viel gestorben,
    /// also fällt auch Zeit.
    ActionWorld schlachtfeld() {
      return ActionWorld(
        level: Level.parse('Saal', <String>[
          '#' * 14,
          '#${'e' * 12}#',
          '#${'e' * 5}@${'e' * 6}#',
          '#${'e' * 12}#',
          '#${'.' * 11}B#',
          '#' * 14,
        ]),
        heroStats: const ActionStats(
          attack: 30,
          maxHp: 9999999,
          defense: 999,
          energy: 8,
        ),
        stage: PitStage(1),
        seed: 4,
      );
    }

    test('fallen, bringen Sekunden und füllen nie über das Limit', () {
      final welt = schlachtfeld();
      final gewonnen = <double>[];
      var zeitkugelGesehen = false;

      for (var i = 0; i < 60 * 60 && !welt.isOver; i++) {
        welt.step(Vec2.zero);
        zeitkugelGesehen |= welt.orbs.any((o) => o.kind == OrbKind.zeit);
        gewonnen.addAll(
          welt.drainEvents().whereType<TimeGained>().map((e) => e.seconds),
        );
        expect(welt.timeLeft, lessThanOrEqualTo(welt.timeLimit!));
      }

      expect(zeitkugelGesehen, isTrue);
      expect(gewonnen, isNotEmpty);
      for (final s in gewonnen) {
        expect(s, greaterThan(0));
        expect(s, lessThanOrEqualTo(ActionBalance.timeDropSeconds));
      }
    });

    test('ohne Uhr fällt keine', () {
      final welt = ActionWorld(
        level: Level.parse('Saal', <String>[
          '#' * 14,
          '#${'e' * 5}@${'e' * 6}#',
          '#${'.' * 11}B#',
          '#' * 14,
        ]),
        heroStats: const ActionStats(
          attack: 30,
          maxHp: 9999999,
          defense: 999,
          energy: 8,
        ),
        seed: 4,
      );
      for (var i = 0; i < 60 * 30 && !welt.isOver; i++) {
        welt.step(Vec2.zero);
        expect(welt.orbs.where((o) => o.kind == OrbKind.zeit), isEmpty);
      }
    });
  });
}

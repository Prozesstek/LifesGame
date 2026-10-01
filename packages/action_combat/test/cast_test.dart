import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die Besetzung einer Grube (ADR-0062): welche Arten in einem Lauf
/// vorkommen, und dass sie die Karte nicht anfasst.

/// Wo wer steht, ohne die Art — und die Karte darunter.
String _geruest(Level level) {
  return <String>[
    for (var y = 0; y < level.height; y++)
      <String>[
        for (var x = 0; x < level.width; x++)
          level.tileAt(x, y) == Tile.wand ? '#' : '.',
      ].join(),
    for (final s in level.spawns) '${s.tileX},${s.tileY}',
  ].join('\n');
}

Set<EnemyKind> _arten(Level level) =>
    <EnemyKind>{for (final s in level.spawns) s.kind};

void main() {
  group('Die Besetzung wird gewürfelt', () {
    test('derselbe Startwert ergibt dieselbe Besetzung', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(PitCast.forSeed(seed), PitCast.forSeed(seed));
      }
    });

    test('jede Wahl kommt vor', () {
      final besetzungen = <PitCast>[
        for (var seed = 0; seed < 200; seed++) PitCast.forSeed(seed),
      ];

      expect(
        besetzungen.map((c) => c.secondMelee).toSet(),
        PitCast.secondMelees.toSet(),
      );
      expect(
        besetzungen.map((c) => c.ranged).toSet(),
        PitCast.rangeds.toSet(),
      );
      expect(besetzungen.map((c) => c.swarm).toSet(), PitCast.swarms.toSet());
      expect(
        besetzungen.map((c) => c.special).toSet(),
        PitCast.specials.toSet(),
      );
    });

    test('gleich auf jeder Stufe — alles ab Stufe 1', () {
      // Frederik, 01.10.2026. Die Stufe regelt, wie stark ein Gegner ist,
      // nicht, wer vorkommt: Die Besetzung hängt nur am Startwert.
      for (var seed = 0; seed < 30; seed++) {
        final oben = LevelBuilder.build(stage: PitStage(1), seed: seed);
        final wahl = PitCast.forSeed(seed);
        final erlaubt = <EnemyKind>{
          EnemyKind.fussvolk,
          EnemyKind.brocken,
          EnemyKind.endgegner,
          wahl.ranged,
          if (wahl.secondMelee != null) wahl.secondMelee!,
          if (wahl.swarm != null) wahl.swarm!,
          if (wahl.special != null) wahl.special!,
        };
        expect(
          erlaubt,
          containsAll(_arten(oben)),
          reason: 'Startwert $seed: $wahl',
        );
      }
    });

    test('jede Art, die gewählt werden kann, hat ein Zeichen', () {
      // Sonst wirft der Bau erst in dem Lauf, der sie zieht.
      for (final kind in <EnemyKind?>[
        ...PitCast.secondMelees,
        ...PitCast.rangeds,
        ...PitCast.swarms,
        ...PitCast.specials,
      ]) {
        if (kind == null) continue;
        expect(Level.symbolOf(kind), hasLength(1), reason: kind.name);
      }
    });
  });

  group('Sie besetzt um, sie stellt nicht dazu', () {
    test('die Karte bleibt, wie sie war — nur wer darin steht, wechselt', () {
      for (var seed = 0; seed < 25; seed++) {
        for (final stufe in <int>[1, 17, 30]) {
          final wie = LevelBuilder.build(
            stage: PitStage(stufe),
            seed: seed,
            cast: PitCast.classic,
          );
          final neu = LevelBuilder.build(stage: PitStage(stufe), seed: seed);

          expect(
            _geruest(neu),
            _geruest(wie),
            reason: 'Stufe $stufe, Startwert $seed',
          );
        }
      }
    });

    test('die klassische Besetzung lässt jeden Raum, wie er geschrieben ist',
        () {
      const alt = <EnemyKind>{
        EnemyKind.fussvolk,
        EnemyKind.schuetze,
        EnemyKind.flink,
        EnemyKind.flatterer,
        EnemyKind.brocken,
        EnemyKind.endgegner,
      };
      for (var seed = 0; seed < 40; seed++) {
        final level = LevelBuilder.build(
          stage: PitStage(30),
          seed: seed,
          cast: PitCast.classic,
        );
        expect(alt, containsAll(_arten(level)), reason: 'Startwert $seed');
      }
    });

    test('der Troll und der Wächter gehören nicht zur Besetzung', () {
      for (var seed = 0; seed < 40; seed++) {
        final wie = LevelBuilder.build(
          stage: PitStage(30),
          seed: seed,
          cast: PitCast.classic,
        );
        final neu = LevelBuilder.build(stage: PitStage(30), seed: seed);
        int zahl(Level l, EnemyKind k) =>
            l.spawns.where((s) => s.kind == k).length;

        expect(zahl(neu, EnemyKind.brocken), zahl(wie, EnemyKind.brocken));
        expect(zahl(neu, EnemyKind.endgegner), 1);
      }
    });
  });

  group('Wer in einer Grube steht', () {
    PitCast mit({
      EnemyKind? zweiter,
      EnemyKind schuetze = EnemyKind.schuetze,
      EnemyKind? rudel,
      EnemyKind? sonder,
    }) =>
        PitCast(
          secondMelee: zweiter,
          ranged: schuetze,
          swarm: rudel,
          special: sonder,
        );

    int zahl(EnemyKind kind, PitCast cast, {int gruben = 40}) {
      var summe = 0;
      for (var seed = 0; seed < gruben; seed++) {
        final level = LevelBuilder.build(
          stage: PitStage(30),
          seed: seed,
          cast: cast,
        );
        summe += level.spawns.where((s) => s.kind == kind).length;
      }
      return summe;
    }

    test('das Fussvolk bleibt neben dem zweiten Nahkämpfer', () {
      // **Der Grund ist der Grimlock:** Er ist blind. Eine Grube nur aus
      // Grimlocks liesse sich bis zum Wächter durchschleichen, und der
      // zahlt dann den ganzen Topf.
      final cast = mit(zweiter: EnemyKind.grimlock);
      final orks = zahl(EnemyKind.fussvolk, cast);
      final blinde = zahl(EnemyKind.grimlock, cast);

      expect(orks, greaterThan(0));
      expect(blinde, greaterThan(0));
      expect(blinde / (orks + blinde), closeTo(0.5, 0.12));
    });

    test('wer schiesst, ist in einer Grube immer derselbe', () {
      final cast = mit(schuetze: EnemyKind.strahler);

      expect(zahl(EnemyKind.schuetze, cast), 0);
      expect(zahl(EnemyKind.strahler, cast), greaterThan(0));
    });

    test('das Rudel ist in einer Grube immer dasselbe', () {
      final cast = mit(rudel: EnemyKind.flatterer);

      expect(zahl(EnemyKind.flink, cast), 0);
      expect(zahl(EnemyKind.flatterer, cast), greaterThan(0));
    });

    test('der Sondergegner steht in manchen Räumen, höchstens einer je Raum',
        () {
      final cast = mit(sonder: EnemyKind.kreischer);
      var raeume = 0;
      var pilze = 0;
      for (var seed = 0; seed < 60; seed++) {
        final stage = PitStage(30);
        final level = LevelBuilder.build(stage: stage, seed: seed, cast: cast);
        final hier =
            level.spawns.where((s) => s.kind == EnemyKind.kreischer).length;
        expect(hier, lessThanOrEqualTo(stage.roomCount));
        raeume += stage.roomCount;
        pilze += hier;
      }

      expect(pilze, greaterThan(0));
      // Nicht jeder Raum hat Fussvolk, auf dessen Platz er stehen könnte;
      // der Anteil liegt deshalb unter der eingestellten Chance.
      final anteil = pilze / raeume;
      expect(anteil, lessThanOrEqualTo(ActionBalance.castSpecialChance));
      expect(anteil, greaterThan(ActionBalance.castSpecialChance / 2));
    });

    test('ohne Sondergegner steht keiner da', () {
      expect(zahl(EnemyKind.kreischer, mit()), 0);
      expect(zahl(EnemyKind.heiler, mit()), 0);
    });

    test('jede Grube trägt, mit jeder Besetzung', () {
      for (final zweiter in PitCast.secondMelees) {
        for (final schuetze in PitCast.rangeds) {
          for (final rudel in PitCast.swarms) {
            for (final sonder in PitCast.specials) {
              final cast = mit(
                zweiter: zweiter,
                schuetze: schuetze,
                rudel: rudel,
                sonder: sonder,
              );
              for (var seed = 0; seed < 6; seed++) {
                final level = LevelBuilder.build(
                  stage: PitStage(30),
                  seed: seed,
                  cast: cast,
                );
                expect(level.problems, isEmpty, reason: '$cast, $seed');
              }
            }
          }
        }
      }
    });
  });
}

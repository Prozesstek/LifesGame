import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die Gegner der Besetzung (ADR-0062): Schleim, Grimlock, Kreischpilz,
/// Sporenpilz, Wächterauge. Geprüft wird das **Verhalten** — der Grund,
/// den jede Art im Kommentar ihres Eintrags trägt (`EnemyKind`).

/// Ein Held, der kaum Schaden macht und nicht stirbt.
const ActionStats _zaeh = ActionStats(
  attack: 1,
  maxHp: 999999,
  defense: 0,
  energy: 8,
);

/// Einer, der mit einem Schlag fällt, was Fussvolk-Leben hat.
const ActionStats _stark = ActionStats(
  attack: 400,
  maxHp: 999999,
  defense: 0,
  energy: 8,
);

ActionWorld _welt(
  List<String> karte, {
  ActionStats held = _zaeh,
  ({int xp, int gold}) topf = const (xp: 0, gold: 0),
}) {
  return ActionWorld(
    level: Level.parse('Probe', karte),
    heroStats: held,
    rewardPot: topf,
    weaponMoveId: 'sword_strike',
  );
}

List<ActionEvent> _laufen(ActionWorld welt, int schritte, [Vec2? eingabe]) {
  final alle = <ActionEvent>[];
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(eingabe ?? Vec2.zero);
    alle.addAll(welt.drainEvents());
  }
  return alle;
}

int _schadenAmHelden(List<ActionEvent> events) => events
    .whereType<HitLanded>()
    .where((e) => e.targetFaction == Faction.held)
    .fold<int>(0, (s, e) => s + e.amount);

Iterable<EntityView> _von(ActionWorld welt, EnemyKind kind) =>
    welt.views.where((v) => v.kind == kind);

void main() {
  group('Karten lesen', () {
    test('jede Art der Besetzung hat ein Zeichen', () {
      final level = Level.parse('Probe', const <String>[
        '#########',
        '#@.jgpmo#',
        '#......B#',
        '#########',
      ]);

      expect(
        level.spawns.map((s) => s.kind),
        containsAll(<EnemyKind>[
          EnemyKind.schleim,
          EnemyKind.grimlock,
          EnemyKind.kreischer,
          EnemyKind.heiler,
          EnemyKind.strahler,
        ]),
      );
      expect(level.problems, isEmpty);
    });

    test('Zeichen und Art gehen in beide Richtungen', () {
      for (final eintrag in Level.symbols.entries) {
        expect(Level.symbolOf(eintrag.value), eintrag.key);
      }
    });

    test('der Schleimling steht in keinem Raum', () {
      // Er entsteht nur aus einem Schleim. Liesse er sich setzen, zahlte
      // er auch — und genau das soll er nicht.
      expect(Level.symbols.values, isNot(contains(EnemyKind.schleimling)));
      expect(() => Level.symbolOf(EnemyKind.schleimling), throwsArgumentError);
    });
  });

  group('Der Schleim', () {
    const karte = <String>[
      '########',
      '#@j....#',
      '#......#',
      '########',
    ];

    test('zerfällt beim Tod in zwei Schleimlinge', () {
      final welt = _welt(karte, held: _stark);
      expect(welt.totalEnemies, 1);

      final ereignisse = <ActionEvent>[];
      while (_von(welt, EnemyKind.schleim).isNotEmpty) {
        ereignisse.addAll(_laufen(welt, 1));
      }

      expect(
        _von(welt, EnemyKind.schleimling),
        hasLength(ActionBalance.schleimSplit),
      );
      expect(welt.totalEnemies, 1 + ActionBalance.schleimSplit);
      expect(welt.isOver, isFalse, reason: 'Die Kleinen stehen noch.');
    });

    test('die Schleimlinge sind schon wach und greifen an', () {
      final welt = _welt(karte, held: _stark);
      while (_von(welt, EnemyKind.schleim).isNotEmpty) {
        welt.step(Vec2.zero);
      }
      welt.drainEvents();

      // Der Held läuft weg; nur wer wach ist, kommt hinterher.
      final vorher = _von(welt, EnemyKind.schleimling).first.position;
      _laufen(welt, 20, const Vec2(1, 0));
      final kleine = _von(welt, EnemyKind.schleimling);
      if (kleine.isNotEmpty) {
        expect(kleine.first.position.x, greaterThan(vorher.x));
      }
    });

    test('die Halle ist erst leer, wenn auch die Kleinen liegen', () {
      final welt = _welt(karte, held: _stark);
      _laufen(welt, 60 * 20);

      expect(welt.isWon, isTrue);
      expect(welt.kills, 1 + ActionBalance.schleimSplit);
    });

    test('die Schleimlinge zahlen nichts — der Topf geht nie über', () {
      // Der Schleim zahlt seinen Teil wie jeder andere. Zahlten die
      // Kleinen mit, wäre ein Schleim drei Gegner wert, und der Topf
      // einer Stufe hinge daran, wie oft etwas zerfällt (ADR-0041).
      final welt = _welt(
        const <String>[
          '##########',
          '#@j.e....#',
          '#........#',
          '##########',
        ],
        held: _stark,
        topf: (xp: 100, gold: 100),
      );
      final beute = _laufen(welt, 60 * 30).whereType<LootDropped>().toList();

      expect(welt.isWon, isTrue);
      expect(beute, hasLength(2), reason: 'Schleim und Ork, sonst niemand.');
      expect(welt.runXp, lessThanOrEqualTo(100));
      expect(welt.runGold, lessThanOrEqualTo(100));
    });

    test('ist langsamer als Fussvolk, der Schleimling schneller', () {
      expect(ActionBalance.schleimSpeed, lessThan(ActionBalance.trashSpeed));
      expect(
        ActionBalance.schleimlingSpeed,
        greaterThan(ActionBalance.trashSpeed),
      );
    });
  });

  group('Der Grimlock', () {
    // Fünf Felder Abstand, freie Sicht: 160 Punkte. Fussvolk bemerkt den
    // Helden dort (210), der Grimlock nicht (70).
    List<String> gang(String wer) => <String>[
          '############',
          '#@....$wer....#',
          '############',
        ];

    test('bemerkt den Helden nicht, wo Fussvolk ihn längst sähe', () {
      final ork = _welt(gang('e'));
      final blind = _welt(gang('g'));

      expect(_laufen(ork, 30).whereType<EnemyNoticed>(), isNotEmpty);
      expect(_laufen(blind, 120).whereType<EnemyNoticed>(), isEmpty);
    });

    test('bemerkt ihn, wenn er ihm fast auf den Füssen steht', () {
      final welt = _welt(gang('g'));
      final bemerkt = <EnemyNoticed>[];
      for (var i = 0; i < 60 * 4 && bemerkt.isEmpty; i++) {
        welt.step(const Vec2(1, 0));
        bemerkt.addAll(welt.drainEvents().whereType<EnemyNoticed>());
      }

      expect(bemerkt, isNotEmpty);
      final grimlock = _von(welt, EnemyKind.grimlock).first;
      expect(
        grimlock.position.distanceTo(welt.heroView.position),
        lessThanOrEqualTo(ActionBalance.grimlockNoticeRadius + 2),
      );
    });

    test('wer ihn trifft, hat ihn am Hals', () {
      // Aus der Ferne getroffen: Er weiss, woher es kam, wie jeder andere.
      final welt = ActionWorld(
        level: Level.parse('Gang', gang('g')),
        heroStats: _zaeh,
        abilityIds: const <String>['funkenstoss'],
      );
      expect(welt.cast('funkenstoss'), isTrue);
      final ereignisse = _laufen(welt, 90);

      expect(ereignisse.whereType<EnemyNoticed>(), isNotEmpty);
    });

    test('schlägt härter zu als Fussvolk', () {
      expect(
        ActionBalance.grimlockAttack,
        greaterThan(ActionBalance.trashAttack * 1.5),
      );
    });
  });

  group('Der Kreischpilz', () {
    // Der Held sieht den Pilz; der Ork steht hinter einer Mauer und sähe
    // den Helden nie.
    const karte = <String>[
      '##############',
      '#@...p.......#',
      '#.############',
      '#............#',
      '######.#######',
      '#.....e......#',
      '##############',
    ];

    test('steht still und tut dem Helden nichts', () {
      // Allein: Sonst käme, wen er weckt, und der täte dem Helden etwas.
      final welt = _welt(const <String>[
        '##############',
        '#@...p.......#',
        '##############',
      ]);
      final start = _von(welt, EnemyKind.kreischer).first.position;
      final ereignisse = _laufen(welt, 60 * 6);

      expect(_von(welt, EnemyKind.kreischer).first.position, start);
      expect(_schadenAmHelden(ereignisse), 0);
    });

    test('kündigt den Schrei an, bevor er schreit', () {
      final welt = _welt(karte);
      final ereignisse = <ActionEvent>[];
      while (welt.alarms.isEmpty) {
        ereignisse.addAll(_laufen(welt, 1));
      }

      expect(ereignisse.whereType<EnemyScreamed>(), isEmpty);
      expect(
        welt.alarms.single.radius,
        ActionBalance.kreischerRadiusOfScream,
      );
      // Ein Schrei schadet nicht — er gehört nicht zu dem, woraus man
      // hinauslaufen muss.
      expect(welt.telegraphs, isEmpty);
    });

    test('der Schrei weckt, wer den Helden nie gesehen hätte', () {
      final ruhig = _welt(const <String>[
        '##############',
        '#@...........#',
        '#.############',
        '#............#',
        '######.#######',
        '#.....e......#',
        '##############',
      ]);
      expect(_laufen(ruhig, 60 * 4).whereType<EnemyNoticed>(), isEmpty);

      final welt = _welt(karte);
      final ereignisse = _laufen(welt, 60 * 4);
      final schrei = ereignisse.whereType<EnemyScreamed>();
      final ork = _von(welt, EnemyKind.fussvolk).first;

      expect(schrei, hasLength(1));
      expect(
        ereignisse.whereType<EnemyNoticed>().map((e) => e.id),
        contains(ork.id),
      );
    });

    test('er schreit nur einmal', () {
      final welt = _welt(karte);
      final ereignisse = _laufen(welt, 60 * 15);

      expect(ereignisse.whereType<EnemyScreamed>(), hasLength(1));
      expect(welt.alarms, isEmpty);
    });

    test('wer ihn vorher fällt, hat Ruhe', () {
      // Die Ankündigung ist die Aufgabe: hinlaufen und zuschlagen, bevor
      // sie voll ist.
      final welt = _welt(
        const <String>[
          '##############',
          '#@p..........#',
          '#.############',
          '#............#',
          '######.#######',
          '#.....e......#',
          '##############',
        ],
        held: _stark,
      );
      final ereignisse = _laufen(welt, 60 * 5);

      expect(_von(welt, EnemyKind.kreischer), isEmpty);
      expect(ereignisse.whereType<EnemyScreamed>(), isEmpty);
    });

    test('die Ankündigung lässt Zeit, hinzulaufen', () {
      // Von dort, wo er den Helden bemerkt, bis zu ihm.
      const weg = ActionBalance.aggroRadius / ActionBalance.heroSpeed;
      expect(ActionBalance.kreischerWindup, greaterThan(weg * 0.9));
    });
  });

  group('Der Sporenpilz', () {
    // Der Held schlägt auf den Ork ein; der Pilz steht drei Felder dahinter.
    const karte = <String>[
      '##############',
      '#@e..m.......#',
      '#............#',
      '##############',
    ];

    test('heilt, wer in seiner Nähe verletzt ist', () {
      final welt = _welt(karte);
      final ork = _von(welt, EnemyKind.fussvolk).first.id;
      final heilungen = _laufen(welt, 60 * 8).whereType<EnemyHealed>();

      expect(heilungen, isNotEmpty);
      expect(heilungen.map((e) => e.targetId).toSet(), <int>{ork});
      expect(heilungen.every((e) => e.amount > 0), isTrue);
    });

    test('nie sich selbst und nie einen anderen Sporenpilz', () {
      // Zwei Pilze, beide verletzt, niemand sonst: Heilten sie einander,
      // endete der Lauf nie.
      final welt = ActionWorld(
        level: Level.parse('Probe', const <String>[
          '##############',
          '#@...m.m.....#',
          '##############',
        ]),
        heroStats: _zaeh,
        abilityIds: const <String>['funkenstoss'],
      );
      final ereignisse = <ActionEvent>[];
      for (var i = 0; i < 60 * 12; i++) {
        if (welt.canCast('funkenstoss')) welt.cast('funkenstoss');
        ereignisse.addAll(_laufen(welt, 1));
      }

      expect(
        ereignisse.whereType<HitLanded>().where(
              (e) => e.targetFaction == Faction.gegner,
            ),
        isNotEmpty,
        reason: 'Der Funke muss getroffen haben, sonst prüft das nichts.',
      );
      expect(ereignisse.whereType<EnemyHealed>(), isEmpty);
    });

    test('heilt einen Anteil des Lebens, keine feste Zahl', () {
      final welt = _welt(karte);
      final heilung = _laufen(welt, 60 * 8).whereType<EnemyHealed>().first;
      const voll = ActionBalance.trashHp * ActionBalance.powerScale;

      expect(
        heilung.amount,
        lessThanOrEqualTo((voll * ActionBalance.heilerHealShare).round()),
      );
    });

    test('weicht zurück, wenn der Held herankommt', () {
      final welt = _welt(const <String>[
        '##################',
        '#@..m............#',
        '##################',
      ]);
      final start = _von(welt, EnemyKind.heiler).first.position;
      _laufen(welt, 60);

      expect(
        _von(welt, EnemyKind.heiler).first.position.x,
        greaterThan(start.x),
      );
    });

    test('ein Held trägt schneller ab, als er nachheilt', () {
      // **Ein Lauf muss enden.** Der Troll hat das meiste Leben; steht
      // ein Sporenpilz dabei, muss er trotzdem fallen — auch für einen,
      // der den Pilz stehen lässt.
      const jeSekunde = ActionBalance.brockenHp *
          ActionBalance.heilerHealShare /
          ActionBalance.heilerCooldown;
      // Ein frischer Held: 12 Angriff alle 0,55 Sekunden, minus die halbe
      // Verteidigung des Trolls.
      const held = (12 - ActionBalance.brockenDefense / 2) /
          ActionBalance.heroAttackCooldown;

      expect(jeSekunde, lessThan(held / 2));
    });
  });

  group('Das Wächterauge', () {
    const karte = <String>[
      '##############',
      '#............#',
      '#@.....o.....#',
      '#............#',
      '##############',
    ];

    ActionWorld bisZurLinie() {
      final welt = _welt(karte);
      while (welt.telegraphs.isEmpty) {
        welt.step(Vec2.zero);
      }
      welt.drainEvents();
      return welt;
    }

    test('kündigt den Strahl als Linie an', () {
      final welt = bisZurLinie();
      final linie = welt.telegraphs.single;

      expect(linie.move, BossMove.strahl);
      expect(linie.isRing, isFalse);
      final held = welt.heroView;
      expect(linie.covers(held.position, held.radius), isTrue);
    });

    test('wer stehen bleibt, wird getroffen — wer zur Seite geht, nicht', () {
      int schaden(Vec2 eingabe) {
        final welt = bisZurLinie();
        final ereignisse = _laufen(
          welt,
          (ActionBalance.strahlerWindup * 60).round() + 2,
          eingabe,
        );
        expect(ereignisse.whereType<BeamFired>(), hasLength(1));
        return _schadenAmHelden(ereignisse);
      }

      expect(schaden(Vec2.zero), greaterThan(0));
      expect(schaden(const Vec2(0, 1)), 0);
    });

    test('die Linie folgt dem Helden nicht', () {
      final welt = bisZurLinie();
      final vorher = welt.telegraphs.single.direction;
      _laufen(welt, 20, const Vec2(0, 1));

      final danach = welt.telegraphs.single.direction;
      expect(danach.x, closeTo(vorher.x, 1e-9));
      expect(danach.y, closeTo(vorher.y, 1e-9));
    });

    test('die Ankündigung dauert länger als der Schritt zur Seite', () {
      const seitwaerts =
          (ActionBalance.strahlerBeamHalfWidth + ActionBalance.heroRadius) /
              ActionBalance.heroSpeed;
      expect(ActionBalance.strahlerWindup, greaterThan(seitwaerts * 2));
    });

    test('der Strahl endet an der Wand', () {
      final welt = _welt(const <String>[
        '##############',
        '#............#',
        '#@.o.........#',
        '#............#',
        '##############',
      ]);
      while (welt.telegraphs.isEmpty) {
        welt.step(Vec2.zero);
      }
      // Er zeigt nach links, auf den Helden; dahinter ist nach drei
      // Feldern die Wand.
      expect(
        welt.telegraphs.single.length,
        lessThan(ActionBalance.strahlerBeamLength),
      );
      expect(
        welt.telegraphs.single.length,
        lessThan(4 * ActionBalance.tileSize),
      );
    });

    test('ohne Sicht lädt es nicht', () {
      final welt = _welt(const <String>[
        '##############',
        '#@..#..o.....#',
        '#...#........#',
        '#............#',
        '##############',
      ]);
      // Es wird getroffen, weiss also vom Helden — sieht ihn aber nicht.
      for (var i = 0; i < 60 * 3; i++) {
        welt.step(Vec2.zero);
        expect(welt.telegraphs, isEmpty);
      }
    });
  });

  group('Ein Lauf endet gegen jede Besetzung', () {
    test('der Bot kommt durch oder fällt, aber er hängt nicht', () {
      for (final zweiter in PitCast.secondMelees) {
        for (final schuetze in PitCast.rangeds) {
          for (final sonder in PitCast.specials) {
            final cast = PitCast(
              secondMelee: zweiter,
              ranged: schuetze,
              swarm: EnemyKind.flink,
              special: sonder,
            );
            for (final stufe in <int>[1, 30]) {
              final stage = PitStage(stufe);
              final welt = ActionWorld(
                level: LevelBuilder.build(stage: stage, seed: 5, cast: cast),
                heroStats: ActionStats.gereift,
                stage: stage,
                weaponMoveId: 'sword_strike',
                seed: 5,
              );
              PitBot.play(welt);
              expect(welt.isOver, isTrue, reason: '$cast auf Stufe $stufe');
            }
          }
        }
      }
    });
  });
}

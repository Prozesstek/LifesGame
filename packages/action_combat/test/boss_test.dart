import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein Raum mit dem Wächter allein. Der Held steht [abstand] Felder links
/// von ihm und schlägt nicht zu (Angriff 0 → Mindestschaden 1), damit der
/// Wächter lange genug lebt, um alles zu zeigen.
///
/// [boss] wählt den Wächter, [stufe] die Tiefe; ohne Stufe kann er alles.
ActionWorld _arena({
  int abstand = 2,
  BossKind boss = BossKind.zyklop,
  int? stufe,
  int angriff = 0,
}) {
  final zeile = '#${'.' * 8}@${'.' * (abstand - 1)}B${'.' * 12}#';
  final frei = '#${'.' * (zeile.length - 2)}#';
  return ActionWorld(
    level: Level.parse(
      'Arena',
      <String>[
        '#' * zeile.length,
        for (var i = 0; i < 6; i++) frei,
        zeile,
        for (var i = 0; i < 6; i++) frei,
        '#' * zeile.length,
      ],
      boss: boss,
    ),
    heroStats: ActionStats(
      attack: angriff,
      maxHp: 99999,
      defense: 0,
      energy: 8,
    ),
    stage: stufe == null ? null : PitStage(stufe),
  );
}

/// Läuft, bis [bedingung] gilt, höchstens [sekunden] lang. Gibt zurück,
/// ob sie eingetreten ist.
bool _bis(
  ActionWorld welt,
  bool Function() bedingung, {
  double sekunden = 8,
  Vec2 eingabe = Vec2.zero,
}) {
  for (var i = 0; i < 60 * sekunden; i++) {
    if (bedingung()) return true;
    welt.step(eingabe);
  }
  return bedingung();
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

    test('der Brocken sagt dem Renderer, dass er ein Brocken ist', () {
      // Sonst zeichnet die Grube ihn als roten Punkt wie einen Pfeil.
      final welt = _arena(abstand: 6);
      final wuerfe = <ProjectileView>[];
      for (var i = 0; i < 60 * 5 && wuerfe.isEmpty; i++) {
        welt.step(Vec2.zero);
        wuerfe.addAll(welt.projectiles.where((p) => p.isBoulder));
      }
      expect(wuerfe, isNotEmpty);
      expect(wuerfe.first.radius, ActionBalance.bossBoulderRadius);
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

  group('Vier Wächter, jeder mit eigenem Angriff (ADR-0062)', () {
    test('ohne Angabe wartet der Zyklop', () {
      // Handgeschriebene Hallen und alle älteren Tests bleiben damit,
      // was sie waren.
      expect(_arena().bossKind, BossKind.zyklop);
    });

    test('jede Ankündigung dauert länger als der Weg hinaus', () {
      // Die Regel des Bodenstosses gilt für jeden Ring: Aus seiner Mitte
      // bis über den Rand, mit Heldentempo.
      double weg(double radius) =>
          (radius + ActionBalance.heroRadius) / ActionBalance.heroSpeed;

      expect(
        ActionBalance.slaadJumpWindup,
        greaterThan(weg(ActionBalance.slaadJumpRadius)),
      );
      expect(
        ActionBalance.swampPuddleWindup,
        greaterThan(weg(ActionBalance.swampPuddleRadius)),
      );
      // Der zweite Ring des Ettins: Wer beim ersten losläuft, hat beide
      // Ankündigungen Zeit.
      expect(
        ActionBalance.bossSlamWindup + ActionBalance.ettinSecondWindup,
        greaterThan(weg(ActionBalance.ettinSecondRadius)),
      );
    });

    test('jeder Ring lässt im Wächterraum ringsum Platz', () {
      // Der Wächter steht in der Mitte eines Raums von vierzehn mal zehn
      // Feldern. Reicht ein Ring um ihn bis an die Wand, gibt es in
      // dieser Richtung kein Hinaus mehr.
      const halbeHoehe = RoomCatalog.height * ActionBalance.tileSize / 2;
      for (final radius in <double>[
        ActionBalance.bossSlamRadius,
        ActionBalance.ettinSecondRadius,
      ]) {
        expect(
          radius + 2 * ActionBalance.heroRadius,
          lessThan(halbeHoehe),
          reason: 'Ring mit $radius',
        );
      }
    });

    group('Der Ettin', () {
      test('nach dem ersten Ring kommt ein zweiter, grösserer', () {
        final welt = _arena(boss: BossKind.ettin);
        expect(_bis(welt, () => welt.telegraphs.isNotEmpty), isTrue);
        expect(welt.telegraphs.single.move, BossMove.bodenstoss);
        expect(welt.telegraphs.single.radius, ActionBalance.bossSlamRadius);

        // Der erste schlägt ein, und sofort steht der zweite da.
        final stoesse = <BossSlammed>[];
        expect(
          _bis(welt, () {
            stoesse.addAll(welt.drainEvents().whereType<BossSlammed>());
            return welt.telegraphs.any((t) => t.move == BossMove.nachstoss);
          }),
          isTrue,
        );
        expect(stoesse, hasLength(1));
        expect(
          welt.telegraphs.single.radius,
          ActionBalance.ettinSecondRadius,
        );
        expect(
          ActionBalance.ettinSecondRadius,
          greaterThan(ActionBalance.bossSlamRadius),
        );
      });

      test('wer nach dem ersten wegläuft, entgeht dem zweiten', () {
        int schaden({required bool weglaufen}) {
          final welt = _arena(boss: BossKind.ettin);
          _bis(welt, () => welt.telegraphs.isNotEmpty);
          welt.drainEvents();
          const dauer = ActionBalance.bossSlamWindup +
              ActionBalance.ettinSecondWindup +
              0.1;
          return _schadenAmHelden(
            _laufen(
              welt,
              (dauer * 60).round(),
              weglaufen ? const Vec2(-1, 0) : Vec2.zero,
            ),
          );
        }

        expect(schaden(weglaufen: true), 0);
        expect(schaden(weglaufen: false), greaterThan(0));
      });

      test('er wirft zweimal kurz hintereinander, einmal je Kopf', () {
        final welt = _arena(abstand: 6, boss: BossKind.ettin);
        expect(
          _bis(welt, () => welt.projectiles.any((p) => p.isBoulder)),
          isTrue,
        );
        expect(welt.projectiles.where((p) => p.isBoulder), hasLength(1));

        // Der zweite kommt, bevor der erste angekommen ist.
        _laufen(
          welt,
          (ActionBalance.ettinSecondThrowDelay * 60).round() + 2,
        );
        expect(welt.projectiles.where((p) => p.isBoulder), hasLength(2));
      });

      test('der zweite Brocken zielt neu', () {
        // Wer dem ersten ausweicht und dann stehen bleibt, steht im
        // zweiten: Er fliegt dorthin, wo der Held inzwischen ist.
        final welt = _arena(abstand: 6, boss: BossKind.ettin);
        _bis(welt, () => welt.projectiles.any((p) => p.isBoulder));
        _laufen(
          welt,
          (ActionBalance.ettinSecondThrowDelay * 60).round() + 2,
          const Vec2(0, 1),
        );
        final brocken = welt.projectiles.where((p) => p.isBoulder).toList();
        expect(brocken, hasLength(2));
        expect(
          brocken.last.direction.y,
          greaterThan(brocken.first.direction.y),
        );
      });

      test('er stürmt nie an', () {
        final welt = _arena(abstand: 6, boss: BossKind.ettin);
        expect(
          _bis(welt, () => welt.telegraphs.any((t) => !t.isRing), sekunden: 12),
          isFalse,
        );
      });
    });

    group('Der Slaad', () {
      test('der Ring liegt dort, wo der Held steht — nicht um ihn selbst', () {
        final welt = _arena(abstand: 6, boss: BossKind.slaad);
        expect(_bis(welt, () => welt.telegraphs.isNotEmpty), isTrue);

        final ring = welt.telegraphs.single;
        expect(ring.move, BossMove.sprung);
        expect(ring.isRing, isTrue);
        expect(ring.covers(welt.heroView.position, 0), isTrue);
        expect(
          ring.origin.distanceTo(welt.heroView.position),
          lessThan(ActionBalance.tileSize),
        );
      });

      test('er landet auf dem Ring, und der Ring bleibt, wo er war', () {
        final welt = _arena(abstand: 6, boss: BossKind.slaad);
        _bis(welt, () => welt.telegraphs.isNotEmpty);
        final landeplatz = welt.telegraphs.single.origin;

        // Der Held läuft weg; der Ring folgt ihm nicht.
        final ereignisse = _laufen(
          welt,
          (ActionBalance.slaadJumpWindup * 60).round() + 2,
          const Vec2(0, 1),
        );
        final stoss = ereignisse.whereType<BossSlammed>().single;

        expect(stoss.at.distanceTo(landeplatz), lessThan(1));
        expect(stoss.radius, ActionBalance.slaadJumpRadius);
        expect(_schadenAmHelden(ereignisse), 0);
      });

      test('wer stehen bleibt, wird getroffen', () {
        final welt = _arena(abstand: 6, boss: BossKind.slaad);
        _bis(welt, () => welt.telegraphs.isNotEmpty);
        welt.drainEvents();
        final ereignisse = _laufen(
          welt,
          (ActionBalance.slaadJumpWindup * 60).round() + 2,
        );
        expect(_schadenAmHelden(ereignisse), greaterThan(0));
      });

      test('im Flug steht er über dem Boden', () {
        // Die Höhe ist nur fürs Bild: Der Renderer bekommt ihn höher
        // gezeigt, als er für die Rechnung steht.
        final welt = _arena(abstand: 6, boss: BossKind.slaad);
        _bis(welt, () => welt.telegraphs.isNotEmpty);
        final start = welt.bossView!.position;
        _laufen(welt, (ActionBalance.slaadJumpWindup * 30).round());

        final gezeigt = welt.views.firstWhere(
          (v) => v.kind == EnemyKind.endgegner,
        );
        expect(gezeigt.position.y, lessThan(start.y - 20));
      });

      test('auf Stufe 1 spuckt er nicht, ab seiner Stufe schon', () {
        bool spuckt(int stufe) {
          final welt = _arena(abstand: 6, boss: BossKind.slaad, stufe: stufe);
          return _bis(
            welt,
            () => welt.projectiles.any((p) => p.faction == Faction.gegner),
            eingabe: const Vec2(-1, 0),
          );
        }

        expect(spuckt(1), isFalse);
        expect(spuckt(ActionBalance.bossThrowFromStage), isTrue);
      });

      test('in Wut springt er zweimal hintereinander', () {
        final welt = _arena(boss: BossKind.slaad, angriff: 60);
        expect(
          _bis(welt, () => welt.isBossEnraged, sekunden: 20),
          isTrue,
          reason: 'Der Held bringt ihn nicht unter die Hälfte.',
        );
        // Den nächsten Sprung abwarten, dann seine Landung: Gleich danach
        // muss wieder ein Ring liegen.
        _bis(welt, () => welt.telegraphs.isEmpty, eingabe: const Vec2(-1, 0));
        expect(
          _bis(
            welt,
            () => welt.telegraphs.any((t) => t.move == BossMove.sprung),
            eingabe: const Vec2(-1, 0),
          ),
          isTrue,
        );
        welt.drainEvents();
        var gelandet = false;
        expect(
          _bis(
            welt,
            () {
              gelandet = gelandet ||
                  welt.drainEvents().whereType<BossSlammed>().isNotEmpty;
              return gelandet;
            },
            eingabe: const Vec2(-1, 0),
          ),
          isTrue,
        );
        expect(
          welt.telegraphs.any((t) => t.move == BossMove.sprung),
          isTrue,
          reason: 'Nach der Landung folgt in Wut sofort der zweite Sprung.',
        );
      });
    });

    group('Der Sumpftroll', () {
      test('das Gift landet, wo der Held steht, und bleibt liegen', () {
        final welt = _arena(abstand: 6, boss: BossKind.sumpftroll);
        expect(_bis(welt, () => welt.telegraphs.isNotEmpty), isTrue);
        final ring = welt.telegraphs.single;
        expect(ring.move, BossMove.pfuetze);
        expect(ring.covers(welt.heroView.position, 0), isTrue);
        expect(welt.zones, isEmpty);

        _laufen(welt, (ActionBalance.swampPuddleWindup * 60).round() + 2);

        final pfuetze = welt.zones.single;
        expect(pfuetze.hostile, isTrue);
        expect(pfuetze.center.distanceTo(ring.origin), lessThan(1));
        expect(pfuetze.radius, ActionBalance.swampPuddleRadius);
      });

      test('wer in der Pfütze steht, nimmt Schaden — wer draussen, nicht', () {
        int schaden({required bool weglaufen}) {
          final welt = _arena(abstand: 6, boss: BossKind.sumpftroll, stufe: 1);
          _bis(welt, () => welt.zones.isNotEmpty);
          welt.drainEvents();
          // Zwei Sekunden lang, weg vom Wächter — der kommt sonst heran
          // und schlägt zu, und das wäre ein anderer Schaden.
          return _schadenAmHelden(
            _laufen(welt, 120, weglaufen ? const Vec2(0, 1) : Vec2.zero),
          );
        }

        expect(
          schaden(weglaufen: false),
          greaterThan(schaden(weglaufen: true)),
        );
      });

      test('die Pfütze trifft die Gegner nicht', () {
        // Sie gehört dem Wächter. Stünde er in seinem eigenen Gift und
        // litte, wäre Stehenbleiben die beste Antwort.
        final welt = _arena(boss: BossKind.sumpftroll);
        _bis(welt, () => welt.zones.isNotEmpty);
        _laufen(welt, 180);
        expect(welt.bossView!.hpRatio, 1);
      });

      test('es liegen nie mehr als zwei', () {
        // Auf Stufe 1 wirft er alle fünf Sekunden, die Pfütze liegt
        // sechs. Blieben sie liegen, wäre der Raum nach einer Minute zu.
        final welt = _arena(abstand: 6, boss: BossKind.sumpftroll, stufe: 1);
        _bis(welt, () => welt.zones.isNotEmpty);
        var hoechstens = 0;
        for (var i = 0; i < 60 * 20; i++) {
          welt.step(Vec2.zero);
          if (welt.zones.length > hoechstens) hoechstens = welt.zones.length;
        }
        expect(hoechstens, lessThanOrEqualTo(2));
      });

      test('auf Stufe 1 stampft er nicht', () {
        final welt = _arena(boss: BossKind.sumpftroll, stufe: 1);
        expect(
          _bis(
            welt,
            () => welt.telegraphs.any((t) => t.move == BossMove.bodenstoss),
          ),
          isFalse,
        );
      });

      test('in Wut wirft er drei Pfützen, die sich nicht berühren', () {
        final welt = _arena(abstand: 1, boss: BossKind.sumpftroll, angriff: 60);
        expect(_bis(welt, () => welt.isBossEnraged, sekunden: 20), isTrue);
        expect(
          _bis(
            welt,
            () =>
                welt.telegraphs
                    .where((t) => t.move == BossMove.pfuetze)
                    .length ==
                3,
            eingabe: const Vec2(-1, 0),
            sekunden: 12,
          ),
          isTrue,
        );
        final ringe = welt.telegraphs;
        for (var i = 0; i < ringe.length; i++) {
          for (var j = i + 1; j < ringe.length; j++) {
            expect(
              ringe[i].origin.distanceTo(ringe[j].origin),
              greaterThan(2 * ActionBalance.swampPuddleRadius),
            );
          }
        }
      });
    });

    test('jeder Wächter lässt den Lauf enden, auf jeder Stufe der Treppe', () {
      // **Ein Lauf muss enden** — auch gegen einen, der springt, und
      // einen, der Gift legt.
      for (final boss in BossKind.values) {
        for (final stufe in <int>[1, 4, 8, 30]) {
          final stage = PitStage(stufe);
          final welt = ActionWorld(
            level: LevelBuilder.build(stage: stage, seed: 3, boss: boss),
            heroStats: ActionStats.gereift,
            stage: stage,
            weaponMoveId: 'sword_strike',
            seed: 3,
          );
          PitBot.play(welt);
          expect(welt.isOver, isTrue, reason: '$boss auf Stufe $stufe');
        }
      }
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

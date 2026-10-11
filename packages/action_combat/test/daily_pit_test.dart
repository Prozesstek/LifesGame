import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die Tagesgrube (ADR-0072): dieselbe Grube für alle, ein Versuch am
/// Tag, ein Held für alle.
void main() {
  const sonntag = DailyPit.firstDay; // 11.10.2026
  const montag = sonntag + 1;

  /// Die Karte als ein Text — zwei gleiche Karten sind derselbe Text.
  String karte(Level level) {
    final zeilen = <String>[
      for (final reihe in level.tiles)
        reihe.map((t) => t == Tile.wand ? '#' : '.').join(),
    ];
    final gegner = <String>[
      for (final s in level.spawns) '${s.kind.name}@${s.tileX},${s.tileY}',
    ];
    return '${zeilen.join('\n')}\n${gegner.join(' ')}\n${level.boss.name}';
  }

  /// Eine Zahl für eine Karte — klein gehalten, damit sie im Browser
  /// dasselbe ergibt: Dort rechnet Dart mit Gleitkommazahlen, und ein
  /// Produkt über 2⁵³ wäre nicht mehr genau.
  int pruefsumme(String text) {
    var h = 7;
    for (final code in text.codeUnits) {
      h = (h * 31 + code) % 1000000007;
    }
    return h;
  }

  group('Derselbe Tag ist dieselbe Grube', () {
    test('auf jedem Gerät — festgehalten für den 12.10.2026', () {
      // **Festgehalten, nicht berechnet.** „Dieselbe Grube für alle“ gilt
      // nur, wenn der Startwert und der Würfel dahinter überall dasselbe
      // ergeben — im Browser wie in einer App. `dart:math` sagt das für
      // seinen gesäten Würfel nicht zu. Deshalb läuft dieser Test auch im
      // Browser (`dart test -p chrome test/daily_pit_test.dart`): Weicht
      // eine Plattform oder eine neue Dart-Version ab, fällt er hier um
      // und nicht erst, wenn zwei Freunde verschiedene Karten vergleichen.
      //
      // Wer die Räume, die Besetzung oder den Bau ändert, ändert die
      // Grube mit — dann gehört hier die neue Zahl hin.
      final level = DailyPit.worldFor(montag, inForm: false).level;

      expect(DailyPit.seedFor(montag), 672008388);
      expect(level.boss, BossKind.sumpftroll);
      expect('${level.width}x${level.height}', '32x48');
      expect(level.spawns, hasLength(31));
      expect(pruefsumme(karte(level)), 332647367);
    });

    test('Karte, Besetzung und Wächter kommen aus dem Datum', () {
      final eine = DailyPit.worldFor(montag, inForm: false).level;
      final andere = DailyPit.worldFor(montag, inForm: true).level;

      expect(karte(andere), karte(eine));
    });

    test('jeder Tag einer Woche ist eine andere', () {
      final woche = <String>{
        for (var tag = montag; tag < montag + 7; tag++)
          karte(DailyPit.worldFor(tag, inForm: false).level),
      };

      expect(woche, hasLength(7));
    });

    test('der Startwert bleibt im Bereich, den die Grube sonst würfelt', () {
      for (var tag = sonntag; tag < sonntag + 400; tag++) {
        final seed = DailyPit.seedFor(tag);
        expect(seed, inInclusiveRange(0, (1 << 30) - 1), reason: '$tag');
      }
    });

    test('vierhundert Tage ergeben vierhundert Startwerte', () {
      final werte = <int>{
        for (var tag = sonntag; tag < sonntag + 400; tag++)
          DailyPit.seedFor(tag),
      };

      expect(werte, hasLength(400));
    });

    test('jede Tagesgrube eines Jahres trägt', () {
      for (var tag = sonntag; tag < sonntag + 365; tag++) {
        final level = DailyPit.worldFor(tag, inForm: false).level;
        expect(level.problems, isEmpty, reason: 'Tag $tag');
      }
    });

    test('die Nummer zählt ab dem ersten Tag', () {
      expect(DailyPit.numberFor(sonntag), 1);
      expect(DailyPit.numberFor(sonntag + 11), 12);
      expect(DailyPit.numberFor(sonntag - 5), 1, reason: 'nie null');
    });
  });

  group('Sieben Sätze, Montag bis Sonntag', () {
    test('der 11.10.2026 ist ein Sonntag, der Tag danach ein Montag', () {
      expect(DailyPit.weekdayOf(sonntag), 6);
      expect(DailyPit.weekdayOf(montag), 0);
      expect(DailyPit.loadoutFor(montag), same(DailyPit.loadouts.first));
      expect(
        DailyPit.loadoutFor(montag + 7),
        same(DailyPit.loadouts.first),
        reason: 'Eine Woche später derselbe Satz.',
      );
    });

    test('jeder trägt eine Waffe und drei Fähigkeiten, die die Grube kennt',
        () {
      expect(DailyPit.loadouts, hasLength(7));
      for (final satz in DailyPit.loadouts) {
        expect(
          PitWeapons.byMoveId(satz.weaponMoveId),
          isNotNull,
          reason: satz.weaponMoveId,
        );
        expect(satz.abilityIds, hasLength(ActionBalance.maxAbilitySlots));
        expect(satz.abilityIds.toSet(), hasLength(satz.abilityIds.length));
        for (final id in satz.abilityIds) {
          expect(PitAbilities.byId(id), isNotNull, reason: id);
        }
      }
    });

    test('keine Waffe kommt zweimal', () {
      final waffen = DailyPit.loadouts.map((s) => s.weaponMoveId).toSet();

      expect(waffen, hasLength(7));
    });

    test('über die Woche kommt jede Fähigkeit einmal dran', () {
      final gezeigt = <String>{
        for (final satz in DailyPit.loadouts) ...satz.abilityIds,
      };

      expect(gezeigt, PitAbilities.all.map((a) => a.id).toSet());
    });

    test('der Einheitsheld kann jede seiner Fähigkeiten bezahlen', () {
      final mana = PitPower.dailyHero(inForm: false).maxMana;
      for (final satz in DailyPit.loadouts) {
        for (final id in satz.abilityIds) {
          expect(
            PitAbilities.byId(id)!.manaCost,
            lessThanOrEqualTo(mana),
            reason: '$id kostet mehr, als er hat.',
          );
        }
      }
    });

    test('die Welt des Tages trägt den Satz des Tages', () {
      for (var tag = montag; tag < montag + 7; tag++) {
        final satz = DailyPit.loadoutFor(tag);
        final welt = DailyPit.worldFor(tag, inForm: false);

        expect(welt.weapon.moveId, satz.weaponMoveId);
        expect(welt.slots.map((a) => a.id), satz.abilityIds);
        expect(welt.stage, PitStage(satz.stage));
        expect(welt.rewardPot, (xp: 0, gold: 0), reason: 'Sie zahlt nichts.');
      }
    });
  });

  group('Der Einheitsheld', () {
    test('in Form ist er auf allen vier Werten ein Viertel stärker', () {
      final ohne = PitPower.dailyHero(inForm: false);
      final mit = PitPower.dailyHero(inForm: true);
      const faktor = 1 + ActionBalance.dailyFormBonus;

      expect(mit.combatAttack, closeTo(ohne.combatAttack * faktor, 1));
      expect(mit.combatMaxHp, closeTo(ohne.combatMaxHp * faktor, 1));
      expect(mit.combatDefense, closeTo(ohne.combatDefense * faktor, 1));
      expect(mit.maxMana, closeTo(ohne.maxMana * faktor, 1));
    });

    test('er rechnet im Kampfmassstab, nicht mit festen Zahlen', () {
      final held = PitPower.dailyHero(inForm: false);

      expect(
        held.combatAttack,
        (ActionBalance.dailyHeroAttack *
                ActionBalance.powerScale *
                ActionBalance.dailyHeroPower)
            .round(),
      );
    });
  });

  group('Die Räume einer gesteckten Grube', () {
    test('Start, die Räume der Stufe, der Wächter — in dieser Reihenfolge', () {
      for (var stufe = 1; stufe <= PitStage.count; stufe += 7) {
        final stage = PitStage(stufe);
        final level = LevelBuilder.build(stage: stage, seed: 4711 + stufe);

        expect(level.rooms, hasLength(stage.roomCount + 2));
        expect(level.roomIndexAt(level.heroStart), 0);
        final boss =
            level.spawns.firstWhere((s) => s.kind == EnemyKind.endgegner);
        expect(
          level.roomIndexAt(level.centerOfSpawn(boss)),
          level.rooms.length - 1,
        );
      }
    });

    test('jedes begehbare Feld liegt in genau einem Raum', () {
      for (var seed = 0; seed < 40; seed++) {
        final level = LevelBuilder.build(stage: PitStage(12), seed: seed);
        for (var y = 0; y < level.height; y++) {
          for (var x = 0; x < level.width; x++) {
            if (level.tileAt(x, y) == Tile.wand) continue;
            final treffer = level.rooms.where((r) => r.contains(x, y)).length;
            expect(treffer, 1, reason: 'Startwert $seed, Feld $x,$y');
          }
        }
      }
    });

    test('eine handgeschriebene Halle hat keine', () {
      final halle = Level.parse('Halle', const <String>[
        '#####',
        '#@.B#',
        '#####',
      ]);

      expect(halle.rooms, isEmpty);
      expect(halle.roomIndexAt(halle.heroStart), isNull);
      expect(
        ActionWorld(level: halle, heroStats: ActionStats.frisch).damageByRoom,
        isEmpty,
      );
    });
  });

  group('Die Raumzeile', () {
    /// Ein Lauf, den niemand verliert: so stark, dass der Bot durchgeht.
    ActionWorld gewonnen(int tag) {
      final satz = DailyPit.loadoutFor(tag);
      final stage = PitStage(satz.stage);
      final seed = DailyPit.seedFor(tag);
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: stage, seed: seed),
        heroStats: const ActionStats(
          attack: 400,
          maxHp: 99999,
          defense: 400,
          energy: 16,
        ),
        stage: stage,
        abilityIds: satz.abilityIds,
        weaponMoveId: satz.weaponMoveId,
        seed: seed,
      );
      PitBot.play(welt);
      return welt;
    }

    /// Ein Lauf, den jeder verliert: Der Held fällt beim ersten Schlag.
    ActionWorld gefallen(int tag) {
      final stage = PitStage(DailyPit.loadoutFor(tag).stage);
      final seed = DailyPit.seedFor(tag);
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: stage, seed: seed),
        heroStats: const ActionStats(
          attack: 1,
          maxHp: 1,
          defense: 0,
          energy: 8,
        ),
        stage: stage,
        seed: seed,
      );
      PitBot.play(welt);
      return welt;
    }

    test('ein Sieg: jeder Raum hat eine Farbe, am Ende die Krone', () {
      final welt = gewonnen(montag);
      expect(welt.isWon, isTrue);

      final zeile = DailyRun.marksOf(welt);
      expect(zeile, hasLength(welt.level.rooms.length - 1));
      expect(zeile.last, RoomMark.krone);
      for (final marke in zeile.take(zeile.length - 1)) {
        expect(
          marke,
          anyOf(RoomMark.sauber, RoomMark.angekratzt, RoomMark.blutig),
        );
      }
    });

    test('wer kaum etwas abbekommt, hat lauter grüne Räume', () {
      final zeile = DailyRun.marksOf(gewonnen(montag));

      expect(zeile.take(zeile.length - 1), everyElement(RoomMark.sauber));
    });

    test('eine Niederlage: ein Totenkopf, danach nichts mehr', () {
      final welt = gefallen(montag);
      expect(welt.isWon, isFalse);
      expect(welt.isTimedOut, isFalse);

      final zeile = DailyRun.marksOf(welt);
      final ende = zeile.indexOf(RoomMark.gefallen);
      expect(ende, isNot(-1), reason: '$zeile');
      expect(zeile.where((m) => m == RoomMark.gefallen), hasLength(1));
      expect(zeile.skip(ende + 1), everyElement(RoomMark.offen));
      expect(zeile, isNot(contains(RoomMark.krone)));
    });

    test('wer stehen bleibt, bis die Uhr abläuft, steht im ersten Raum', () {
      final welt = DailyPit.worldFor(montag, inForm: true);
      while (!welt.isOver) {
        welt.step(Vec2.zero);
      }
      expect(welt.isTimedOut, isTrue);

      final zeile = DailyRun.marksOf(welt);
      expect(zeile.first, RoomMark.zeitAus);
      expect(zeile.skip(1), everyElement(RoomMark.offen));
    });

    test('gezählt wird, was im Raum ankam — Heilung zieht nichts ab', () {
      final welt = gewonnen(montag);

      expect(welt.damageByRoom, hasLength(welt.level.rooms.length));
      expect(welt.damageByRoom, everyElement(greaterThanOrEqualTo(0)));
      expect(welt.deepestRoom, welt.level.rooms.length - 1);
      expect(welt.currentRoom, welt.level.rooms.length - 1);
    });
  });

  group('Ein Versuch am Tag', () {
    const log = DailyPitLog.empty();

    test('mit dem Start ist er gebraucht — und gilt als abgebrochen', () {
      final begonnen = log.start(montag, condition: DailyCondition.inForm);

      expect(begonnen.hasStarted(montag), isTrue);
      expect(begonnen.runOn(montag)!.outcome, DailyOutcome.abgebrochen);
      expect(begonnen.runOn(montag)!.isFinished, isFalse);
      expect(begonnen.hasStarted(montag + 1), isFalse);
    });

    test('ein zweiter Start am selben Tag ändert nichts', () {
      final einmal = log.start(montag, condition: DailyCondition.ohneForm);
      final zweimal = einmal.start(montag, condition: DailyCondition.inForm);

      expect(zweimal, same(einmal));
      expect(zweimal.runOn(montag)!.condition, DailyCondition.ohneForm);
    });

    test('das Ende trägt Ausgang, Zeit und Raumzeile ein', () {
      final welt = DailyPit.worldFor(montag, inForm: true);
      while (!welt.isOver) {
        welt.step(Vec2.zero);
      }
      final fertig = log
          .start(montag, condition: DailyCondition.inForm)
          .finish(montag, welt);
      final lauf = fertig.runOn(montag)!;

      expect(lauf.outcome, DailyOutcome.zeitAus);
      expect(lauf.seconds, closeTo(welt.elapsed, 0.06));
      expect(lauf.rooms, DailyRun.marksOf(welt));
      expect(lauf.condition, DailyCondition.inForm);
    });

    test('die Verfassung bleibt die vom Start', () {
      final welt = DailyPit.worldFor(montag, inForm: false);
      while (!welt.isOver) {
        welt.step(Vec2.zero);
      }
      final fertig = log
          .start(montag, condition: DailyCondition.ruhetag)
          .finish(montag, welt);

      expect(fertig.runOn(montag)!.condition, DailyCondition.ruhetag);
    });

    test('ein beendeter Versuch lässt sich nicht überschreiben', () {
      final welt = DailyPit.worldFor(montag, inForm: false);
      while (!welt.isOver) {
        welt.step(Vec2.zero);
      }
      final fertig = log
          .start(montag, condition: DailyCondition.ohneForm)
          .finish(montag, welt);

      expect(fertig.finish(montag, welt), same(fertig));
      expect(
        fertig.start(montag, condition: DailyCondition.inForm),
        same(fertig),
      );
    });

    test('ohne Start gibt es kein Ende', () {
      final welt = DailyPit.worldFor(montag, inForm: false);

      expect(log.finish(montag, welt), same(log));
    });
  });

  group('Was sie einbringt: nur Ruhm', () {
    DailyRun lauf(DailyOutcome outcome, DailyCondition condition) {
      return DailyRun(
        outcome: outcome,
        seconds: 61,
        condition: condition,
        rooms: const <RoomMark>[],
      );
    }

    test('antreten 1, Sieg 3, Sieg in Form 5', () {
      expect(lauf(DailyOutcome.gefallen, DailyCondition.inForm).fame, 1);
      expect(lauf(DailyOutcome.zeitAus, DailyCondition.ohneForm).fame, 1);
      expect(lauf(DailyOutcome.abgebrochen, DailyCondition.inForm).fame, 1);
      expect(lauf(DailyOutcome.sieg, DailyCondition.ohneForm).fame, 3);
      expect(lauf(DailyOutcome.sieg, DailyCondition.ruhetag).fame, 3);
      expect(lauf(DailyOutcome.sieg, DailyCondition.inForm).fame, 5);
    });

    test('der Stand zählt jeden Tag einmal', () {
      final stand = DailyPitLog.fromJson(<String, Object?>{
        '$montag': lauf(DailyOutcome.sieg, DailyCondition.inForm).toJson(),
        '${montag + 1}':
            lauf(DailyOutcome.gefallen, DailyCondition.inForm).toJson(),
        '${montag + 2}':
            lauf(DailyOutcome.sieg, DailyCondition.ruhetag).toJson(),
      });

      expect(stand.fame, 5 + 1 + 3);
      expect(stand.attempts, 3);
      expect(stand.wins, 2);
    });

    test('ein begonnener Versuch bringt schon den Ruhm des Antretens', () {
      final stand = const DailyPitLog.empty()
          .start(montag, condition: DailyCondition.ohneForm);

      expect(stand.fame, DailyPitRewards.fameForAttempt);
    });
  });

  group('Speichern', () {
    test('ein Versuch überlebt einen Neustart', () {
      const lauf = DailyRun(
        outcome: DailyOutcome.sieg,
        seconds: 64.2,
        condition: DailyCondition.inForm,
        rooms: <RoomMark>[
          RoomMark.sauber,
          RoomMark.angekratzt,
          RoomMark.blutig,
          RoomMark.krone,
        ],
      );
      final stand = DailyPitLog.fromJson(<String, Object?>{
        '$montag': lauf.toJson(),
      });
      final wieder = DailyPitLog.fromJson(stand.toJson());

      expect(wieder, stand);
      expect(wieder.runOn(montag), lauf);
    });

    test('ein begonnener Versuch auch — er bleibt abgebrochen', () {
      final stand = const DailyPitLog.empty()
          .start(montag, condition: DailyCondition.ruhetag);
      final wieder = DailyPitLog.fromJson(stand.toJson());

      expect(wieder.runOn(montag)!.outcome, DailyOutcome.abgebrochen);
      expect(wieder.runOn(montag)!.condition, DailyCondition.ruhetag);
    });

    test('ein unlesbarer Tag fehlt, die anderen bleiben', () {
      final stand = DailyPitLog.fromJson(<String, Object?>{
        '$montag': <Object?>['s', 64.2, 'f', 'sak'],
        'kein-tag': <Object?>['s', 1, 'f', ''],
        '${montag + 1}': 'Unsinn',
        '${montag + 2}': <Object?>['?', 1, 'f', ''],
        '${montag + 3}': <Object?>['g', -4, 'o', ''],
      });

      expect(stand.attempts, 1);
      expect(stand.runOn(montag)!.won, isTrue);
    });

    test('ein unbekanntes Feld der Raumzeile fällt heraus, der Lauf bleibt',
        () {
      final lauf = DailyRun.fromJson(<Object?>['g', 12, 'o', 's?g'])!;

      expect(lauf.rooms, <RoomMark>[RoomMark.sauber, RoomMark.gefallen]);
    });

    test('ohne den Tag ist der Versuch wieder frei', () {
      final stand = const DailyPitLog.empty()
          .start(montag, condition: DailyCondition.inForm);

      expect(stand.without(montag).hasStarted(montag), isFalse);
      expect(stand.without(montag + 1), same(stand));
    });
  });
}

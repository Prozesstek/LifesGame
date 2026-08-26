import 'package:combat/combat.dart';
import 'package:test/test.dart';

/// Prueft die Mechaniken, die das Faehigkeiten-Set gebraucht hat.
///
/// Bewusst gegen die **Engine**, nicht gegen einzelne Faehigkeiten: Der
/// Katalog kann sich aendern, diese Regeln nicht. Wer eine Zahl in einer
/// Faehigkeit dreht, soll hier nichts kaputt machen koennen.
void main() {
  /// Zwei gleich starke Kaempfer. Reicht fuer jede Frage hier -- es geht
  /// um Mechanik, nicht um Balance.
  CombatState freshState({int playerEnergy = 10}) {
    return CombatState.start(
      player: Combatant.fresh(
        name: 'Du',
        maxHp: 200,
        attack: 16,
        defense: 10,
        maxEnergy: 10,
      ).withEnergyDelta(playerEnergy),
      enemy: Combatant.fresh(
        name: 'Gegner',
        maxHp: 200,
        attack: 16,
        defense: 10,
        maxEnergy: 10,
      ),
    );
  }

  /// Ein Gegner, der garantiert nichts tut -- so bleibt in den Zahlen nur
  /// das stehen, was der Spieler ausgeloest hat.
  CombatEngine idleEngine() {
    return CombatEngine(
      seed: 1,
      balance: const Balance(damageVariance: 0),
      enemyLoadout: const <Move>[
        Move(id: 'wait', name: 'Warten', power: 0, energyDelta: 0),
      ],
    );
  }

  group('Eigener Perfect-Faktor je Faehigkeit', () {
    test('eine Faehigkeit mit eigenem Faktor schlaegt haerter zu', () {
      const schwach = Move(
        id: 'a',
        name: 'A',
        power: 1.0,
        energyDelta: 0,
      );
      const stark = Move(
        id: 'b',
        name: 'B',
        power: 1.0,
        energyDelta: 0,
        perfectFactor: 1.5,
      );

      final mitDeckel = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(move: schwach, timedHit: TimedHit.perfect),
      );
      final mitEigenem = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(move: stark, timedHit: TimedHit.perfect),
      );

      expect(
        mitEigenem.state.enemy.hp,
        lessThan(mitDeckel.state.enemy.hp),
      );
    });

    test('ohne eigenen Faktor gilt weiter der Deckel aus Balance', () {
      // Das ist die Zusage an ADR-0009: Basisangriff und Waffenmoves
      // bleiben bei +20 %, egal was der Katalog sonst tut.
      expect(Moves.basicAttack.perfectFactor, isNull);
      expect(Moves.basicAttack.missFactor, isNull);

      // Die Waffenmoves ebenso -- sie werden jede Runde gedrueckt, und
      // genau dort galt die Messung aus ADR-0009.
      const waffen = <String>[
        'sword_strike',
        'dagger_double',
        'mace_bash',
        'staff_gather',
      ];
      for (final id in waffen) {
        final move = Moves.byId(id);
        expect(move, isNotNull, reason: id);
        expect(move?.perfectFactor, isNull, reason: id);
      }
    });

    test('Verfehlen bestraft nur, wo missFactor gesetzt ist', () {
      const ohne = Move(id: 'a', name: 'A', power: 2.0, energyDelta: 0);
      const mit = Move(
        id: 'b',
        name: 'B',
        power: 2.0,
        energyDelta: 0,
        missFactor: 0.4,
      );

      final voll = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(move: ohne),
      );
      final gestraft = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(move: mit),
      );

      expect(gestraft.state.enemy.hp, greaterThan(voll.state.enemy.hp));
    });
  });

  group('Perfect-Wirkungen', () {
    const funke = Move(
      id: 'funke',
      name: 'Funke',
      power: 0.75,
      energyDelta: -1,
      perfectEffects: <MoveEffect>[ApplyBurn(chance: 1)],
    );

    test('greifen nur bei perfektem Timing', () {
      final daneben = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(move: funke),
      );
      final perfekt = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(move: funke, timedHit: TimedHit.perfect),
      );

      expect(daneben.state.enemy.statuses, isEmpty);
      expect(perfekt.state.enemy.statuses.map((s) => s.id), contains('burn'));
    });

    test('Brand richtet danach Schaden an', () {
      var state = freshState();
      final engine = idleEngine();

      state = engine
          .resolveRound(
            state,
            const PlayerAction(move: funke, timedHit: TimedHit.perfect),
          )
          .state;
      final nachBrand = state.enemy.hp;

      state = engine.resolveRound(state, const PlayerAction(move: funke)).state;

      // Zwei Quellen: der zweite Treffer und der Brand.
      expect(state.enemy.hp, lessThan(nachBrand));
    });
  });

  group('Schutz und Reflexion', () {
    test('Schadensminderung senkt den Treffer', () {
      const schutz = Move(
        id: 'schutz',
        name: 'Schutz',
        power: 0,
        energyDelta: 0,
        effects: <MoveEffect>[ReduceIncoming(factor: 0.6, turns: 3)],
      );

      final state = idleEngine()
          .resolveRound(freshState(), const PlayerAction(move: schutz))
          .state;

      expect(
        state.player.statuses.map((s) => s.id),
        contains('damage_reduction'),
      );
    });

    test('Reflexion trifft den Angreifer', () {
      // Der Gegner schlaegt zu, waehrend beim Spieler Reflexion liegt.
      const spiegel = Move(
        id: 'spiegel',
        name: 'Spiegel',
        power: 0,
        energyDelta: 0,
        effects: <MoveEffect>[ReflectIncoming(share: 0.5, turns: 3)],
      );
      const schlag = Move(
        id: 'schlag',
        name: 'Schlag',
        power: 1.5,
        energyDelta: 0,
      );

      final engine = CombatEngine(
        seed: 1,
        balance: const Balance(damageVariance: 0),
        enemyLoadout: const <Move>[schlag],
      );

      final state = engine
          .resolveRound(freshState(), const PlayerAction(move: spiegel))
          .state;

      expect(state.enemy.hp, lessThan(state.enemy.maxHp));
    });

    test('Schutz ignorieren geht durch Schild und Minderung', () {
      const durchschlag = Move(
        id: 'durch',
        name: 'Durch',
        power: 1.0,
        energyDelta: 0,
        effects: <MoveEffect>[IgnoreProtection()],
      );
      const normal = Move(id: 'norm', name: 'Norm', power: 1.0, energyDelta: 0);

      // Gegner mit Schild vorbereiten.
      final geschuetzt = freshState();
      final mitSchild = geschuetzt.copyWith(
        enemy: geschuetzt.enemy.withStatus(
          const Shield(absorb: 500, remainingTurns: 5),
        ),
      );

      final blockiert = idleEngine().resolveRound(
        mitSchild,
        const PlayerAction(move: normal),
      );
      final durch = idleEngine().resolveRound(
        mitSchild,
        const PlayerAction(move: durchschlag),
      );

      expect(blockiert.state.enemy.hp, mitSchild.enemy.hp);
      expect(durch.state.enemy.hp, lessThan(mitSchild.enemy.hp));
    });
  });

  group('Lebensraub und Energiediebstahl', () {
    test('Lebensraub heilt anteilig zum Schaden', () {
      const zehrung = Move(
        id: 'zehr',
        name: 'Zehrung',
        power: 1.2,
        energyDelta: 0,
        effects: <MoveEffect>[LifeSteal(share: 1.0)],
      );

      final verletzt = freshState();
      final angeschlagen = verletzt.copyWith(
        player: verletzt.player.withHpDelta(-100),
      );

      final state = idleEngine()
          .resolveRound(angeschlagen, const PlayerAction(move: zehrung))
          .state;

      expect(state.player.hp, greaterThan(angeschlagen.player.hp));
    });

    test('Energiediebstahl nimmt nur, was da ist', () {
      const raub = Move(
        id: 'raub',
        name: 'Raub',
        power: 0,
        energyDelta: 0,
        effects: <MoveEffect>[StealEnergy(amount: 5)],
      );

      // Der Gegner startet ohne Energie.
      final state = idleEngine()
          .resolveRound(freshState(), const PlayerAction(move: raub))
          .state;

      expect(state.enemy.energy, 0);
    });
  });

  group('Umgebungen', () {
    const lava = Move(
      id: 'lava',
      name: 'Lava',
      power: 0,
      energyDelta: 0,
      effects: <MoveEffect>[SetEnvironment('lava')],
    );
    const frost = Move(
      id: 'frost',
      name: 'Frost',
      power: 0,
      energyDelta: 0,
      effects: <MoveEffect>[SetEnvironment('frost')],
    );

    test('eine Faehigkeit legt sie, und sie liegt', () {
      final state = idleEngine()
          .resolveRound(freshState(), const PlayerAction(move: lava))
          .state;

      expect(state.environment?.id, 'lava');
      expect(state.environment?.owner, Side.player);
    });

    test('sie richtet Schaden beim Gegner an', () {
      final state = idleEngine()
          .resolveRound(freshState(), const PlayerAction(move: lava))
          .state;

      expect(state.enemy.hp, lessThan(state.enemy.maxHp));
    });

    test('eine neue ueberschreibt die alte sofort', () {
      var state = freshState();
      final engine = idleEngine();

      state = engine.resolveRound(state, const PlayerAction(move: lava)).state;
      state = engine.resolveRound(state, const PlayerAction(move: frost)).state;

      expect(state.environment?.id, 'frost');
    });

    test('sie klingt nach ihren Runden aus', () {
      var state = freshState();
      final engine = idleEngine();
      const warten = Move(id: 'w', name: 'W', power: 0, energyDelta: 0);

      state = engine.resolveRound(state, const PlayerAction(move: lava)).state;
      expect(state.environment, isNotNull);

      // Lavafeld haelt drei Runden; nach der dritten ist Schluss.
      for (var i = 0; i < 3; i++) {
        state =
            engine.resolveRound(state, const PlayerAction(move: warten)).state;
      }

      expect(state.environment, isNull);
    });

    test('der Ersteller leidet nicht unter dem Dauerschaden', () {
      final state = idleEngine()
          .resolveRound(freshState(), const PlayerAction(move: lava))
          .state;

      expect(state.player.hp, state.player.maxHp);
    });
  });

  group('Mehrfachtreffer', () {
    const wirbel = Move(
      id: 'wirbel',
      name: 'Wirbel',
      power: 0.45,
      energyDelta: 0,
      hits: 3,
    );

    test('drei Tipps ergeben drei Treffer', () {
      final step = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(
          move: wirbel,
          extraHits: <TimedHit>[TimedHit.none, TimedHit.none],
        ),
      );

      expect(step.eventsOfType<DamageDealt>().length, 3);
    });

    test('alle drei perfekt geben einen vierten Treffer', () {
      final step = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(
          move: wirbel,
          timedHit: TimedHit.perfect,
          extraHits: <TimedHit>[TimedHit.perfect, TimedHit.perfect],
        ),
      );

      expect(step.eventsOfType<DamageDealt>().length, 4);
    });

    test('fehlende Tipps zaehlen als verfehlt, nicht als Absturz', () {
      final step = idleEngine().resolveRound(
        freshState(),
        const PlayerAction(move: wirbel),
      );

      expect(step.eventsOfType<DamageDealt>().length, 3);
    });
  });

  group('Timing-Werte', () {
    test('Faktoren bleiben in ihren Grenzen', () {
      const eng = TimingSpec(speed: 3.0, perfectWindow: 0.04);
      final verschaerft = eng.scaled(speedFactor: 5, windowFactor: 0.1);

      expect(verschaerft.speed, TimingSpec.maxSpeed);
      expect(verschaerft.perfectWindow, TimingSpec.minWindow);
    });

    test('die Good-Zone ist doppelt so breit wie die perfekte', () {
      const spec = TimingSpec(perfectWindow: 0.1);

      expect(spec.goodWindow, closeTo(0.2, 0.0001));
    });
  });
}

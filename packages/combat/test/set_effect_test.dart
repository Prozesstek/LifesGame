import 'package:combat/combat.dart';
import 'package:test/test.dart';

/// Was ein vollstaendiges Ausruestungs-Set im Kampf aendert.
///
/// **Die Engine kennt keine Ausruestung.** Sie bekommt nur das Ergebnis
/// — „auf Zuege dieser Art wirkt das" — und dieser Test prueft genau
/// diese Naht. Woraus ein Set besteht, prueft `package:gear`; dass beide
/// Seiten zusammenpassen, prueft `test/gear_sets_seam_test.dart` in der
/// App.
void main() {
  Combatant frisch({int energy = 20}) {
    return Combatant.fresh(
      name: 'Du',
      maxHp: 200,
      attack: 16,
      defense: 8,
      maxEnergy: 20,
      startEnergy: energy,
    );
  }

  CombatState startMit(Move move, {int energy = 20}) {
    return CombatState.start(
      player: frisch(energy: energy),
      enemy: Combatant.fresh(
        name: 'Gegner',
        maxHp: 2000,
        attack: 1,
        defense: 0,
        maxEnergy: 0,
      ),
    );
  }

  group('Die Art eines Zuges', () {
    test('wird abgeleitet, und jede Art kommt vor', () {
      final arten = <MoveKind>{
        for (final move in AbilityMoves.all) move.kind,
      };

      expect(arten, hasLength(MoveKind.values.length));
    });

    test('eine Umgebung zaehlt als Umgebung, auch wenn sie Schaden macht', () {
      // Vulkanbruch ist der einzige Grenzfall im ganzen Katalog: Er legt
      // Lava **und** richtet 38 Schaden an. Zaehlte er als Angriff, waere
      // ein Set fuer Umgebungen ausgerechnet um die staerkste Umgebung
      // aermer.
      final vulkan = Moves.byId('vulkanbruch')!;

      expect(vulkan.dealsDamage, isTrue);
      expect(vulkan.kind, MoveKind.umgebung);
    });

    test('was nur den Anwender staerkt, ist Schutz', () {
      expect(Moves.byId('steinhaut')!.kind, MoveKind.schutz);
      expect(Moves.byId('bluetentau')!.kind, MoveKind.schutz);
      expect(Moves.byId('prisma_barriere')!.kind, MoveKind.schutz);
    });

    test('jeder Waffenzug ist ein Angriff', () {
      for (final move in <Move>[
        Moves.basicAttack,
        Moves.swordStrike,
        Moves.daggerDouble,
        Moves.maceBash,
        Moves.staffGather,
      ]) {
        expect(move.kind, MoveKind.angriff, reason: move.id);
      }
    });
  });

  group('Ein Set wirkt nur auf seine Art', () {
    const angriffsSet = SetEffect(
      kind: MoveKind.angriff,
      damageFactor: 1.25,
    );

    test('es greift bei einer Angriffs-Faehigkeit', () {
      expect(angriffsSet.appliesTo(Moves.byId('donnerkeil')!), isTrue);
    });

    test('es greift nicht bei einer Umgebung', () {
      expect(angriffsSet.appliesTo(Moves.byId('frostnebel')!), isFalse);
    });

    test('es greift nicht beim Waffenzug, obwohl der ein Angriff ist', () {
      // **Die Regel aus ADR-0009, in einer zweiten Auflage.** Ein Faktor
      // auf den Zug, den man jede Runde drueckt, entscheidet den Kampf
      // allein — genau deshalb hat der Basisangriff auch keinen eigenen
      // Perfect-Faktor.
      for (final move in <Move>[
        Moves.basicAttack,
        Moves.swordStrike,
        Moves.staffGather,
      ]) {
        expect(move.kind, MoveKind.angriff, reason: move.id);
        expect(angriffsSet.appliesTo(move), isFalse, reason: move.id);
      }
    });
  });

  group('Schaden', () {
    test('ein Angriffs-Set laesst eine Faehigkeit haerter treffen', () {
      final move = Moves.byId('donnerkeil')!;

      int schaden(List<SetEffect> sets) {
        final engine = CombatEngine(seed: 7, playerSets: sets);
        final step = engine.resolveRound(
          startMit(move),
          PlayerAction(move: move, timedHit: TimedHit.none),
        );
        return step.state.enemy.maxHp - step.state.enemy.hp;
      }

      final ohne = schaden(const <SetEffect>[]);
      final mit = schaden(const <SetEffect>[
        SetEffect(kind: MoveKind.angriff, damageFactor: 1.5),
      ]);

      expect(mit, greaterThan(ohne));
    });

    test('ein Umgebungs-Set aendert am Donnerkeil nichts', () {
      final move = Moves.byId('donnerkeil')!;

      int schaden(List<SetEffect> sets) {
        final engine = CombatEngine(seed: 7, playerSets: sets);
        final step = engine.resolveRound(
          startMit(move),
          PlayerAction(move: move, timedHit: TimedHit.none),
        );
        return step.state.enemy.maxHp - step.state.enemy.hp;
      }

      expect(
        schaden(const <SetEffect>[
          SetEffect(kind: MoveKind.umgebung, damageFactor: 1.5),
        ]),
        schaden(const <SetEffect>[]),
      );
    });
  });

  group('Energie', () {
    final giftmoor = Moves.byId('giftmoor')!;

    int energieNach(List<SetEffect> sets, {int start = 20}) {
      final engine = CombatEngine(seed: 7, playerSets: sets);
      final step = engine.resolveRound(
        startMit(giftmoor, energy: start),
        PlayerAction(move: giftmoor, timedHit: TimedHit.none),
      );
      return step.state.player.energy;
    }

    test('ein Umgebungs-Set macht die Umgebung billiger', () {
      expect(
        energieNach(const <SetEffect>[
          SetEffect(kind: MoveKind.umgebung, energyDiscount: 2),
        ]),
        energieNach(const <SetEffect>[]) + 2,
      );
    });

    test('der Rabatt macht einen Zug bezahlbar, der es sonst nicht waere', () {
      // Giftmoor kostet 6. Mit vier Energie und zwei Rabatt geht er.
      final ohne = CombatEngine(seed: 7).resolveRound(
        startMit(giftmoor, energy: 4),
        PlayerAction(move: giftmoor, timedHit: TimedHit.none),
      );
      final mit = CombatEngine(
        seed: 7,
        playerSets: const <SetEffect>[
          SetEffect(kind: MoveKind.umgebung, energyDiscount: 2),
        ],
      ).resolveRound(
        startMit(giftmoor, energy: 4),
        PlayerAction(move: giftmoor, timedHit: TimedHit.none),
      );

      expect(ohne.state.environment, isNull);
      expect(mit.state.environment?.id, 'poison_bog');
    });

    test('ein Rabatt ueber den Kosten bringt keine Energie ein', () {
      // Sonst waere ein grosszuegiges Set eine Energiequelle statt einer
      // Erleichterung.
      const vorher = 20;
      final nachher = energieNach(const <SetEffect>[
        SetEffect(kind: MoveKind.umgebung, energyDiscount: 99),
      ]);

      expect(nachher, vorher);
    });

    test('das Set verbraucht sich nicht — es liegt jede Runde an', () {
      // Der Statuseffekt `CostReduction` verschwindet nach einem Zug. Ein
      // Set haengt an getragenen Stuecken; wuerde es mitgeloescht, wirkte
      // es genau einmal je Kampf.
      const sets = <SetEffect>[
        SetEffect(kind: MoveKind.umgebung, energyDiscount: 2),
      ];
      final engine = CombatEngine(seed: 7, playerSets: sets);

      var state = startMit(giftmoor, energy: 20);
      final ersteKosten = state.player.energy;
      state = engine
          .resolveRound(
            state,
            PlayerAction(move: giftmoor, timedHit: TimedHit.none),
          )
          .state;
      final nachErster = state.player.energy;

      state = engine
          .resolveRound(
            state,
            PlayerAction(move: giftmoor, timedHit: TimedHit.none),
          )
          .state;

      expect(ersteKosten - nachErster, 4);
      expect(nachErster - state.player.energy, 4);
    });
  });

  group('Timing', () {
    test('ein Schutz-Set macht die Leiste breiter und langsamer', () {
      final steinhaut = Moves.byId('steinhaut')!;
      final state = startMit(steinhaut);

      final ohne = timingForSide(state, Side.player, steinhaut);
      final mit = timingForSide(
        state,
        Side.player,
        steinhaut,
        sets: const <SetEffect>[
          SetEffect(
            kind: MoveKind.schutz,
            timingSpeedFactor: 0.7,
            timingWindowFactor: 1.6,
          ),
        ],
      );

      expect(mit.speed, lessThan(ohne.speed));
      expect(mit.perfectWindow, greaterThan(ohne.perfectWindow));
    });

    test('dieselbe Leiste bleibt fuer eine Faehigkeit anderer Art gleich', () {
      final donnerkeil = Moves.byId('donnerkeil')!;
      final state = startMit(donnerkeil);

      expect(
        timingForSide(
          state,
          Side.player,
          donnerkeil,
          sets: const <SetEffect>[
            SetEffect(kind: MoveKind.schutz, timingWindowFactor: 1.6),
          ],
        ),
        timingForSide(state, Side.player, donnerkeil),
      );
    });
  });

  group('Der Gegner traegt keine Sets', () {
    test('sie gelten nur fuer den Spieler', () {
      const sets = <SetEffect>[
        SetEffect(kind: MoveKind.angriff, damageFactor: 3),
      ];

      // Beide Seiten spielen denselben Zug; nur der Spieler profitiert.
      final engine = CombatEngine(
        seed: 11,
        enemyLoadout: <Move>[Moves.heavyAttack],
        playerSets: sets,
      );
      final ohneSets = CombatEngine(
        seed: 11,
        enemyLoadout: <Move>[Moves.heavyAttack],
      );

      final state = CombatState.start(
        player: frisch(),
        enemy: Combatant.fresh(
          name: 'Gegner',
          maxHp: 2000,
          attack: 16,
          defense: 8,
          maxEnergy: 20,
        ),
      );
      const action = PlayerAction(
        move: Moves.heavyAttack,
        timedHit: TimedHit.none,
      );

      final mit = engine.resolveRound(state, action).state;
      final ohne = ohneSets.resolveRound(state, action).state;

      // Der Spieler richtet mehr an ...
      expect(mit.enemy.hp, lessThan(ohne.enemy.hp));
      // ... und steckt genauso viel ein wie vorher.
      expect(mit.player.hp, ohne.player.hp);
    });
  });
}

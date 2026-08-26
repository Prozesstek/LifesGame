import 'package:combat/combat.dart';
import 'package:test/test.dart';

import 'test_fixtures.dart';

/// Gegner, der immer denselben Move spielt. Isoliert das Timing.
class FixedEnemyPolicy implements EnemyPolicy {
  const FixedEnemyPolicy(this.move);

  final Move move;

  @override
  Move chooseMove({
    required Combatant self,
    required Combatant opponent,
    required List<Move> loadout,
  }) {
    return move;
  }
}

/// Ein Zug, der nichts tut -- damit im Test nur der Gegner handelt.
const Move nichtsTun = Move(
  id: 'nichts',
  name: 'Nichts',
  power: 0,
  energyDelta: 0,
);

/// Spielt [runden] Runden und gibt die Timing-Faktoren zurueck, mit denen
/// der Gegner den Spieler getroffen hat.
List<double> gegnerFaktoren(
  Move gegnerMove, {
  int runden = 400,
  int seed = 7,
  Move spielerMove = nichtsTun,
  Combatant? spieler,
}) {
  final engine = CombatEngine(
    seed: seed,
    balance: deterministicBalance,
    enemyPolicy: FixedEnemyPolicy(gegnerMove),
  );

  // Genug HP und Energie, damit der Kampf nicht vorher endet.
  var state = CombatState.start(
    player: spieler ?? hero(maxHp: 1000000, defense: 0, energy: 10),
    enemy: dummy(maxHp: 1000000, attack: 10, energy: 10, maxEnergy: 10),
  );

  final faktoren = <double>[];
  for (var i = 0; i < runden && !state.isOver; i++) {
    final step = engine.resolveRound(state, PlayerAction(move: spielerMove));
    for (final event in step.events) {
      if (event is DamageDealt && event.target == Side.player) {
        faktoren.add(event.timedHitFactor);
      }
    }
    state = step.state;
  }
  return faktoren;
}

void main() {
  group('Die Fensterregel steht in TimingSpec', () {
    test('die Mitte ist perfekt, der Rand daneben', () {
      const spec = TimingSpec(perfectWindow: 0.2);

      expect(spec.judgeAt(0.5), TimedHit.perfect);
      expect(spec.judgeAt(0.0), TimedHit.none);
      expect(spec.judgeAt(1.0), TimedHit.none);
    });

    test('die Fenster sind ueber die ganze Breite gemessen', () {
      const spec = TimingSpec(perfectWindow: 0.2);

      // 20 % perfekt heisst: von 0.4 bis 0.6.
      expect(spec.judgeAt(0.401), TimedHit.perfect);
      expect(spec.judgeAt(0.599), TimedHit.perfect);

      // Die Good-Zone ist doppelt so breit: 0.3 bis 0.7.
      expect(spec.judgeAt(0.35), TimedHit.good);
      expect(spec.judgeAt(0.65), TimedHit.good);
      expect(spec.judgeAt(0.29), TimedHit.none);
    });

    test('ein engeres Fenster wertet dieselbe Stelle schlechter', () {
      const breit = TimingSpec(perfectWindow: 0.5);
      expect(breit.judgeAt(0.6), TimedHit.perfect);
      // Bei 10 % Perfect ist die Good-Zone 20 % breit und endet bei 0.6 --
      // knapp daneben liegt deshalb erst 0.65.
      expect(const TimingSpec(perfectWindow: 0.1).judgeAt(0.6), TimedHit.good);
      expect(const TimingSpec(perfectWindow: 0.1).judgeAt(0.65), TimedHit.none);
    });
  });

  group('Der Gegner tippt auch', () {
    test('er trifft nicht immer daneben', () {
      // Funkenstoss hat ein breites Fenster (24 %). Ueber vierhundert
      // Runden muss darunter etwas Besseres als "daneben" sein.
      final faktoren = gegnerFaktoren(AbilityMoves.funkenstoss);

      expect(faktoren, isNotEmpty);
      expect(
        faktoren.any((f) => f > 1.0),
        isTrue,
        reason: 'Vor der Aenderung bekam der Gegner immer TimedHit.none.',
      );
    });

    test('ein breites Fenster wird oefter perfekt getroffen als ein enges', () {
      // Funkenstoss 24 % gegen Sternenfall 4 %. Beide haben einen eigenen
      // Perfect-Faktor, deshalb wird ueber den Anteil verglichen, nicht
      // ueber den Wert.
      final breit = gegnerFaktoren(AbilityMoves.funkenstoss);
      final eng = gegnerFaktoren(
        AbilityMoves.sternenfall,
        spieler: hero(maxHp: 1000000, defense: 0, energy: 10),
      );

      final anteilBreit = _perfektAnteil(breit, AbilityMoves.funkenstoss);
      final anteilEng = _perfektAnteil(eng, AbilityMoves.sternenfall);

      expect(anteilBreit, greaterThan(anteilEng));
    });

    test('ein Zug ohne Zeitfenster wuerfelt gar nicht', () {
      // Zwei Laeufe mit demselben Seed muessen gleich sein -- das ist die
      // Zusage der Engine. Wuerde ein Zug ohne Fenster trotzdem wuerfeln,
      // verschoebe er alle folgenden Zufallszahlen.
      final a = gegnerFaktoren(Moves.basicAttack, runden: 50);
      final b = gegnerFaktoren(Moves.basicAttack, runden: 50);

      expect(a, b);
    });
  });

  group('Wurzelgriff wirkt jetzt wirklich', () {
    test('das verengte Fenster senkt die Trefferqualitaet des Gegners', () {
      // Ohne Wurzelgriff: der Gegner trifft mit seinem vollen Fenster.
      final ohne = _perfektAnteil(
        gegnerFaktoren(AbilityMoves.funkenstoss),
        AbilityMoves.funkenstoss,
      );

      // Mit Wurzelgriff: der Spieler verengt es jede Runde auf 75 %.
      final mit = _perfektAnteil(
        gegnerFaktoren(
          AbilityMoves.funkenstoss,
          spielerMove: AbilityMoves.wurzelgriff,
          spieler: hero(maxHp: 1000000, defense: 0, energy: 10, maxEnergy: 10),
        ),
        AbilityMoves.funkenstoss,
      );

      expect(
        mit,
        lessThan(ohne),
        reason: 'Vor der Aenderung war Wurzelgriff gegen Gegner wirkungslos.',
      );
    });
  });

  group('Mehrfachtreffer gelten fuer beide Seiten', () {
    test('der Klingenwirbel des Gegners trifft dreimal', () {
      final engine = CombatEngine(
        seed: 3,
        balance: deterministicBalance,
        enemyPolicy: const FixedEnemyPolicy(AbilityMoves.klingenwirbel),
      );

      final step = engine.resolveRound(
        CombatState.start(
          player: hero(maxHp: 100000, defense: 0),
          enemy: dummy(maxHp: 100000, attack: 10, energy: 10, maxEnergy: 10),
        ),
        const PlayerAction(move: nichtsTun),
      );

      final treffer = step.events
          .whereType<DamageDealt>()
          .where((e) => e.target == Side.player)
          .length;

      expect(
        treffer,
        greaterThanOrEqualTo(3),
        reason: 'Vorher kam nur ein Tipp an, also traf er ein einziges Mal.',
      );
    });
  });
}

/// Anteil der Treffer, die mit dem Perfect-Faktor dieses Moves kamen.
double _perfektAnteil(List<double> faktoren, Move move) {
  if (faktoren.isEmpty) return 0;
  final perfekt = move.perfectFactor ?? 1.2;
  final treffer = faktoren.where((f) => (f - perfekt).abs() < 0.001).length;
  return treffer / faktoren.length;
}

import 'environment.dart';
import 'move.dart';
import 'timing_spec.dart';

/// Die fuenfzehn Faehigkeiten aus der Vorlage.
///
/// **Alle Zahlen stehen hier, keine im Kampfcode.** Gleiche Regel wie in
/// [Balance] und [Environments]: Wer eine Faehigkeit aendert, aendert eine
/// Zeile.
///
/// **Umrechnung fester Zahlen in Multiplikatoren.** Die Vorlage nennt
/// festen Schaden (12, 34, 60). Die Engine rechnet
/// `Schaden = power x Angriffswert`, und der Angriffswert kommt aus den
/// Gewohnheiten (13 bis 20). Feste Zahlen wuerden diese Kopplung kappen --
/// eine Faehigkeit waere dann gleich stark, egal ob jemand dreissig Tage
/// abgehakt hat oder null. Genau das ist die Kernaussage des Spiels, also
/// wird umgerechnet:
///
/// ```
/// power = Wert der Vorlage / referenceAttack
/// ```
///
/// Bei genau [Environments.referenceAttack] trifft jede Faehigkeit die
/// Zahl der Vorlage auf den Punkt. Die **Rangfolge** der fuenfzehn bleibt
/// bei jedem Angriffswert erhalten, weil alle denselben Faktor teilen.
///
/// Die Timing-Werte sind unveraendert uebernommen: Geschwindigkeit als
/// Vielfaches, Fenster als Anteil der Leiste.
abstract final class AbilityMoves {
  static const int _ref = Environments.referenceAttack;

  // --- Common ---

  /// 12 Schaden. Perfect: 18 und 20 % Brandchance.
  static const Move funkenstoss = Move(
    id: 'funkenstoss',
    name: 'Funkenstoß',
    power: 12 / _ref,
    energyDelta: -1,
    timing: TimingSpec(speed: 1.0, perfectWindow: 0.24),
    perfectFactor: 18 / 12,
    perfectEffects: <MoveEffect>[
      ApplyBurn(chance: 0.2, damageFactor: 3 / _ref, turns: 2),
    ],
  );

  /// Eingehender Schaden minus 40 % fuer eine Runde.
  /// Perfect: minus 60 % und 5 Schaden zurueck.
  ///
  /// Die Perfect-Wirkung ersetzt die Grundwirkung, statt sie zu ergaenzen:
  /// `withStatus` tauscht nach Id, also gewinnt die staerkere.
  static const Move steinhaut = Move(
    id: 'steinhaut',
    name: 'Steinhaut',
    power: 0,
    energyDelta: -2,
    timing: TimingSpec(speed: 0.8, perfectWindow: 0.28),
    effects: <MoveEffect>[ReduceIncoming(factor: 0.6, turns: 1)],
    perfectEffects: <MoveEffect>[
      ReduceIncoming(factor: 0.4, turns: 1),
      ReflectIncoming(share: 0, flatBonus: 5, turns: 1),
    ],
  );

  /// 9 Schaden, verengt das gegnerische Fenster. Perfect: eine Runde mehr.
  static const Move wurzelgriff = Move(
    id: 'wurzelgriff',
    name: 'Wurzelgriff',
    power: 9 / _ref,
    energyDelta: -2,
    timing: TimingSpec(speed: 1.1, perfectWindow: 0.20),
    effects: <MoveEffect>[ShrinkEnemyWindow(factor: 0.75, turns: 2)],
    perfectEffects: <MoveEffect>[ShrinkEnemyWindow(factor: 0.75, turns: 3)],
  );

  /// Plus 3 Energie. Perfect: plus 5 und der naechste Zug kostet 1 weniger.
  static const Move aurastrom = Move(
    id: 'aurastrom',
    name: 'Aurastrom',
    power: 0,
    energyDelta: 3,
    timing: TimingSpec(speed: 1.3, perfectWindow: 0.18),
    perfectEffects: <MoveEffect>[
      GainEnergy(amount: 2),
      CheapenNext(amount: 1, turns: 2),
    ],
  );

  // --- Uncommon ---

  /// 20 Heilung. Perfect: 28 und entfernt einen negativen Effekt.
  static const Move bluetentau = Move(
    id: 'bluetentau',
    name: 'Blütentau',
    power: 0,
    energyDelta: -3,
    timing: TimingSpec(speed: 1.2, perfectWindow: 0.18),
    effects: <MoveEffect>[HealSelfBy(factor: 20 / _ref)],
    perfectEffects: <MoveEffect>[
      HealSelfBy(factor: 8 / _ref),
      CleanseSelf(),
    ],
  );

  /// Drei Treffer zu je 7 Schaden, drei Tipps.
  ///
  /// Der vierte Bonustreffer bei drei perfekten Tipps steckt in der
  /// Engine, nicht hier -- er ist eine Regel des Mehrfachtreffers.
  static const Move klingenwirbel = Move(
    id: 'klingenwirbel',
    name: 'Klingenwirbel',
    power: 7 / _ref,
    energyDelta: -4,
    hits: 3,
    timing: TimingSpec(speed: 1.4, perfectWindow: 0.14),
    perfectFactor: 1.5,
  );

  /// Legt das Eisfeld: beide Leisten langsamer, der Gegner blutet und
  /// bekommt weniger Energie.
  static const Move frostnebel = Move(
    id: 'frostnebel',
    name: 'Frostnebel',
    power: 0,
    energyDelta: -4,
    timing: TimingSpec(speed: 0.9, perfectWindow: 0.22),
    effects: <MoveEffect>[SetEnvironment('frost')],
  );

  /// Wirft 30 % des erlittenen Schadens zurueck. Perfect: 50 %.
  static const Move prismaBarriere = Move(
    id: 'prisma_barriere',
    name: 'Prisma-Barriere',
    power: 0,
    energyDelta: -4,
    timing: TimingSpec(speed: 1.0, perfectWindow: 0.16),
    effects: <MoveEffect>[ReflectIncoming(share: 0.3, turns: 2)],
    perfectEffects: <MoveEffect>[ReflectIncoming(share: 0.5, turns: 2)],
  );

  // --- Rare ---

  /// 34 Schaden. Perfect: 48 und der Gegner bekommt eine Runde lang
  /// keinen Timing-Bonus.
  static const Move donnerkeil = Move(
    id: 'donnerkeil',
    name: 'Donnerkeil',
    power: 34 / _ref,
    energyDelta: -5,
    timing: TimingSpec(speed: 1.8, perfectWindow: 0.09),
    perfectFactor: 48 / 34,
    perfectEffects: <MoveEffect>[LockEnemyTiming(turns: 1)],
  );

  /// Legt den Sandsturm: engeres Gegnerfenster, Dauerschaden, eigene
  /// Angriffe staerker.
  static const Move sandsturm = Move(
    id: 'sandsturm',
    name: 'Sandsturm',
    power: 0,
    energyDelta: -5,
    timing: TimingSpec(speed: 1.5, perfectWindow: 0.15),
    effects: <MoveEffect>[SetEnvironment('sandstorm')],
  );

  /// 18 Schaden, heilt in voller Hoehe mit. Perfect: 150 % und 2 Energie.
  static const Move seelenraub = Move(
    id: 'seelenraub',
    name: 'Seelenraub',
    power: 18 / _ref,
    energyDelta: -5,
    timing: TimingSpec(speed: 1.6, perfectWindow: 0.12),
    effects: <MoveEffect>[LifeSteal(share: 1.0)],
    perfectEffects: <MoveEffect>[
      LifeSteal(share: 0.5),
      StealEnergy(amount: 2),
    ],
  );

  /// Legt den Giftboden: steigender Dauerschaden, halbierte Heilung.
  static const Move giftmoor = Move(
    id: 'giftmoor',
    name: 'Giftmoor',
    power: 0,
    energyDelta: -6,
    timing: TimingSpec(speed: 1.4, perfectWindow: 0.14),
    effects: <MoveEffect>[SetEnvironment('poison_bog')],
  );

  // --- Epic ---

  /// Die eigene Leiste laeuft zwei Runden halb so schnell, und Perfect
  /// gibt zusaetzlich 15 % Schaden.
  static const Move zeitdehnung = Move(
    id: 'zeitdehnung',
    name: 'Zeitdehnung',
    power: 0,
    energyDelta: -6,
    timing: TimingSpec(speed: 2.0, perfectWindow: 0.10),
    effects: <MoveEffect>[
      DilateTime(speedFactor: 0.5, perfectBonus: 0.15, turns: 2),
    ],
  );

  /// 38 Schaden und das Lavafeld obendrauf.
  static const Move vulkanbruch = Move(
    id: 'vulkanbruch',
    name: 'Vulkanbruch',
    power: 38 / _ref,
    energyDelta: -8,
    timing: TimingSpec(speed: 2.2, perfectWindow: 0.07),
    effects: <MoveEffect>[SetEnvironment('lava')],
  );

  // --- Legendary ---

  /// 60 Schaden. Perfect: 85 und ignoriert jeden Schutz.
  /// Verfehlt: nur 24 -- die einzige Faehigkeit, die das tut.
  static const Move sternenfall = Move(
    id: 'sternenfall',
    name: 'Sternenfall',
    power: 60 / _ref,
    energyDelta: -10,
    timing: TimingSpec(speed: 3.0, perfectWindow: 0.04),
    perfectFactor: 85 / 60,
    missFactor: 24 / 60,
    perfectEffects: <MoveEffect>[IgnoreProtection()],
  );

  /// Alle fuenfzehn, in der Reihenfolge der Vorlage.
  static const List<Move> all = <Move>[
    funkenstoss,
    steinhaut,
    wurzelgriff,
    aurastrom,
    bluetentau,
    klingenwirbel,
    frostnebel,
    prismaBarriere,
    donnerkeil,
    sandsturm,
    seelenraub,
    giftmoor,
    zeitdehnung,
    vulkanbruch,
    sternenfall,
  ];

  static Move? byId(String id) {
    for (final move in all) {
      if (move.id == id) return move;
    }
    return null;
  }
}

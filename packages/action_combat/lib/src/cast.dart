import 'dart:math' as math;

import 'entity.dart';

/// Die Besetzung einer Grube: welche Gegnerarten in diesem Lauf
/// vorkommen (ADR-0062).
///
/// **Je Lauf gezogen, nicht je Platz.** Würfelte jeder Platz für sich,
/// sähe jede Grube gleich bunt aus. So hat ein Lauf ein Gesicht: diesmal
/// Schleime, Fledermäuse und ein Kreischpilz, das nächste Mal Grimlocks,
/// Kobolde und Sporenpilze.
///
/// Die Räume im Katalog schreiben weiter in **Rollen**: `e` ist „wer
/// heranläuft“, `s` „wer schiesst“, `k` und `f` „was im Rudel kommt“.
/// Die Besetzung sagt, wer die Rolle in diesem Lauf spielt
/// (`LevelBuilder`). Der Troll (`t`) und der Wächter gehören nicht dazu.
class PitCast {
  const PitCast({
    required this.secondMelee,
    required this.ranged,
    required this.swarm,
    required this.special,
  });

  /// Wer neben dem Fussvolk heranläuft, oder `null` für Fussvolk allein.
  ///
  /// **Das Fussvolk bleibt immer dabei**, der zweite teilt sich die
  /// Plätze mit ihm. Der Grund ist der Grimlock: Er ist blind, und eine
  /// Grube nur aus Grimlocks liesse sich bis zum Wächter durchschleichen
  /// — der dann den ganzen Topf auszahlt (ADR-0041).
  final EnemyKind? secondMelee;

  /// Wer schiesst.
  final EnemyKind ranged;

  /// Was im Rudel kommt, oder `null` für „wie der Raum es schreibt“.
  final EnemyKind? swarm;

  /// Wer in manchen Räumen dazusteht und nicht selbst kämpft, oder
  /// `null` für niemanden.
  final EnemyKind? special;

  /// Die Grube, wie sie vor ADR-0062 war: Jeder Raum so, wie er im
  /// Katalog steht. Für Tests, die eine bestimmte Art erwarten, und für
  /// handgeschriebene Hallen.
  static const PitCast classic = PitCast(
    secondMelee: null,
    ranged: EnemyKind.schuetze,
    swarm: null,
    special: null,
  );

  /// Wer als Zweiter heranlaufen kann. `null` steht mit drin: Eine Grube
  /// nur mit Fussvolk ist auch eine Besetzung.
  static const List<EnemyKind?> secondMelees = <EnemyKind?>[
    null,
    EnemyKind.schleim,
    EnemyKind.grimlock,
  ];

  static const List<EnemyKind> rangeds = <EnemyKind>[
    EnemyKind.schuetze,
    EnemyKind.strahler,
  ];

  static const List<EnemyKind> swarms = <EnemyKind>[
    EnemyKind.flink,
    EnemyKind.flatterer,
  ];

  static const List<EnemyKind> specials = <EnemyKind>[
    EnemyKind.kreischer,
    EnemyKind.heiler,
  ];

  /// Die Besetzung zu [seed] — auf jeder Stufe aus demselben Topf
  /// (Frederik, 01.10.2026: alles ab Stufe 1).
  ///
  /// **Ein eigener Würfel**, wie beim Wächter: Die Karte zu einem
  /// Startwert bleibt, wie sie war, nur wer darin steht, wechselt.
  static PitCast forSeed(int seed) {
    final rng = math.Random(seed ^ _salt);
    return PitCast(
      secondMelee: secondMelees[rng.nextInt(secondMelees.length)],
      ranged: rangeds[rng.nextInt(rangeds.length)],
      swarm: swarms[rng.nextInt(swarms.length)],
      special: specials[rng.nextInt(specials.length)],
    );
  }

  static const int _salt = 0xca57;

  /// Der Würfel für die einzelnen Plätze dieser Besetzung — getrennt von
  /// dem, der die Besetzung zieht, und von dem der Karte.
  static math.Random diceFor(int seed) => math.Random(seed ^ _salt ^ 0x9e37);

  @override
  bool operator ==(Object other) =>
      other is PitCast &&
      other.secondMelee == secondMelee &&
      other.ranged == ranged &&
      other.swarm == swarm &&
      other.special == special;

  @override
  int get hashCode => Object.hash(secondMelee, ranged, swarm, special);

  @override
  String toString() =>
      'PitCast(${secondMelee?.name ?? 'nur Fussvolk'}, ${ranged.name}, '
      '${swarm?.name ?? 'wie geschrieben'}, ${special?.name ?? 'niemand'})';
}

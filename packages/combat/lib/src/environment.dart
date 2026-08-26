import 'combatant.dart';

/// Eine Umgebung, die ueber mehrere Runden auf das ganze Feld wirkt.
///
/// **Es ist immer nur eine aktiv.** Eine neue ueberschreibt die alte
/// sofort -- so steht es in der Vorlage, und es hat einen praktischen
/// Grund: Zwei Umgebungen, die beide an der Leiste drehen, waeren im
/// Kopf nicht mehr auszurechnen.
///
/// **Warum eine Datenklasse und keine Unterklassen.** Die vier Umgebungen
/// unterscheiden sich nur in Zahlen, nicht im Verhalten. Als Felder stehen
/// alle Werte an einer Stelle und sind aenderbar, ohne dass jemand Code
/// anfasst -- dieselbe Bauart wie [Balance].
class Environment {
  const Environment({
    required this.id,
    required this.name,
    required this.owner,
    required this.remainingTurns,
    this.dotFactorOnEnemy = 0,
    this.dotGrowthPerTurn = 0,
    this.speedFactorBoth = 1.0,
    this.windowFactorOnEnemy = 1.0,
    this.damageFactorOwner = 1.0,
    this.damageFactorBoth = 1.0,
    this.healFactorOnEnemy = 1.0,
    this.healFactorBoth = 1.0,
    this.energyPenaltyOnEnemy = 0,
  });

  /// Stabiler Bezeichner fuer Events und Darstellung.
  final String id;

  /// Wortlaut fuer den Log: „Lavafeld".
  final String name;

  /// Wer sie gelegt hat. Entscheidet, wen „Gegner" in den Feldern meint --
  /// laut Vorlage profitiert der Ersteller, der andere leidet.
  final Side owner;

  final int remainingTurns;

  /// Schaden je Runde an den Gegner des Erstellers, als Vielfaches von
  /// dessen Angriffswert.
  ///
  /// **Nicht als feste HP und nicht als Anteil der maximalen HP.** Feste
  /// Zahlen wirken bei 120 und bei 230 HP voellig verschieden, Anteile der
  /// maximalen HP haben schon einmal dafuer gesorgt, dass Kaempfe nicht
  /// mehr endeten (`docs/context/gotchas.md`). Gift rechnet seit jeher so.
  final double dotFactorOnEnemy;

  /// Steigerung des Dauerschadens je Runde. Nur das Giftmoor benutzt das.
  final double dotGrowthPerTurn;

  /// Geschwindigkeit der Timing-Leiste, fuer beide Seiten.
  final double speedFactorBoth;

  /// Perfect-Fenster des Gegners.
  final double windowFactorOnEnemy;

  /// Schadensbonus nur fuer den Ersteller.
  final double damageFactorOwner;

  /// Schadensfaktor fuer beide Seiten -- das Lavafeld macht den Kampf fuer
  /// alle toedlicher, auch fuer den, der es gelegt hat.
  final double damageFactorBoth;

  /// Heilung des Gegners, 0.5 = halbiert.
  final double healFactorOnEnemy;

  /// Heilung beider Seiten.
  final double healFactorBoth;

  /// So viel weniger Energie bekommt der Gegner je Runde gutgeschrieben.
  final int energyPenaltyOnEnemy;

  bool get isOver => remainingTurns <= 0;

  /// Die Seite, die unter dieser Umgebung leidet.
  Side get victim => owner == Side.player ? Side.enemy : Side.player;

  /// Der Dauerschaden dieser Runde, als Faktor. Waechst bei Bedarf mit.
  double dotFactorInTurn(int turnsElapsed) {
    return dotFactorOnEnemy + dotGrowthPerTurn * turnsElapsed;
  }

  /// Eine Runde weiterzaehlen. Gibt `null` zurueck, wenn sie ausklingt.
  Environment? ticked() {
    if (remainingTurns <= 1) return null;
    return copyWith(remainingTurns: remainingTurns - 1);
  }

  /// Wie viele Runden sie schon liegt. Grundlage fuer [dotFactorInTurn].
  int elapsedOf(int totalTurns) => totalTurns - remainingTurns;

  Environment copyWith({Side? owner, int? remainingTurns}) {
    return Environment(
      id: id,
      name: name,
      owner: owner ?? this.owner,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      dotFactorOnEnemy: dotFactorOnEnemy,
      dotGrowthPerTurn: dotGrowthPerTurn,
      speedFactorBoth: speedFactorBoth,
      windowFactorOnEnemy: windowFactorOnEnemy,
      damageFactorOwner: damageFactorOwner,
      damageFactorBoth: damageFactorBoth,
      healFactorOnEnemy: healFactorOnEnemy,
      healFactorBoth: healFactorBoth,
      energyPenaltyOnEnemy: energyPenaltyOnEnemy,
    );
  }

  /// Wie stark der Schaden dieser Seite ausfaellt.
  double damageFactorFor(Side side) {
    final owned = side == owner ? damageFactorOwner : 1.0;
    return owned * damageFactorBoth;
  }

  /// Wie stark Heilung dieser Seite wirkt.
  double healFactorFor(Side side) {
    final punished = side == victim ? healFactorOnEnemy : 1.0;
    return punished * healFactorBoth;
  }

  /// Fensterfaktor der Timing-Leiste fuer diese Seite.
  double windowFactorFor(Side side) {
    return side == victim ? windowFactorOnEnemy : 1.0;
  }
}

/// Die vier Umgebungen aus der Vorlage.
///
/// Alle Zahlen an einer Stelle -- gleiche Regel wie in [Balance]: Steht
/// eine davon im Kampfcode, ist das ein Bug.
///
/// Die Dauerschaden-Faktoren sind aus den festen HP-Werten der Vorlage
/// umgerechnet, Bezugspunkt ist ein Angriffswert von
/// [Environments.referenceAttack]. Bei genau diesem Wert trifft die
/// Vorlage auf die Zahl; darueber und darunter skaliert sie mit dem
/// Charakter.
abstract final class Environments {
  /// Mittlerer Angriffswert eines Spielers (13 bis 20 aus `habits`).
  ///
  /// Er uebersetzt die festen Zahlen der Vorlage in Vielfache: „6 HP je
  /// Runde" wird zu 6/16 = 0.375 mal Angriff.
  static const int referenceAttack = 16;

  static const Environment frost = Environment(
    id: 'frost',
    name: 'Eisfeld',
    owner: Side.player,
    remainingTurns: 3,
    dotFactorOnEnemy: 3 / referenceAttack,
    speedFactorBoth: 0.85,
    energyPenaltyOnEnemy: 1,
  );

  static const Environment sandstorm = Environment(
    id: 'sandstorm',
    name: 'Sandsturm',
    owner: Side.player,
    remainingTurns: 3,
    dotFactorOnEnemy: 4 / referenceAttack,
    windowFactorOnEnemy: 0.7,
    damageFactorOwner: 1.15,
  );

  static const Environment poisonBog = Environment(
    id: 'poison_bog',
    name: 'Giftboden',
    owner: Side.player,
    remainingTurns: 4,
    dotFactorOnEnemy: 5 / referenceAttack,
    dotGrowthPerTurn: 2 / referenceAttack,
    healFactorOnEnemy: 0.5,
  );

  static const Environment lava = Environment(
    id: 'lava',
    name: 'Lavafeld',
    owner: Side.player,
    remainingTurns: 3,
    dotFactorOnEnemy: 6 / referenceAttack,
    damageFactorBoth: 1.25,
    healFactorBoth: 0.5,
  );

  static const List<Environment> all = <Environment>[
    frost,
    sandstorm,
    poisonBog,
    lava,
  ];

  static Environment? byId(String id) {
    for (final environment in all) {
      if (environment.id == id) return environment;
    }
    return null;
  }
}

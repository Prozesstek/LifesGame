/// Auf welche Art von Fähigkeit ein Set wirkt.
///
/// **Ein eigener Typ, kein Import aus `package:combat`.** Dieselbe
/// Überlegung wie bei `GearBonus` und `GearRarity`: Die beiden Packages
/// wissen nichts voneinander. Dass die drei Werte hier zu `MoveKind` dort
/// passen, prüft `test/gear_sets_seam_test.dart` in der App — die einzige
/// Stelle, die beide sieht.
enum SetTarget {
  angriff('Angriffs-Fähigkeiten'),
  umgebung('Umgebungen'),
  schutz('Schutz und Heilung');

  const SetTarget(this.label);

  final String label;
}

/// Was eine Stufe eines Sets gibt — zwei getragene Teile oder vier.
///
/// **Drei Hebel, und jeder tut etwas anderes als „mehr Zahlen".** Das ist
/// die Vorgabe aus `konzept.md` 3.1: Ausrüstung soll Entscheidungen
/// ändern. Ein Set, das +3 Angriff gäbe, wäre ein teureres Ausrüstungsteil
/// und sonst nichts.
class SetPerk {
  const SetPerk({
    this.damageFactor = 1.0,
    this.energyDiscount = 0,
    this.timingSpeedFactor = 1.0,
    this.timingWindowFactor = 1.0,
  });

  /// Vielfaches auf den Schaden. 1.25 heißt 25 % mehr.
  final double damageFactor;

  /// Um wie viel die Energiekosten sinken.
  final int energyDiscount;

  /// Vielfaches auf die Markergeschwindigkeit. Kleiner ist langsamer.
  final double timingSpeedFactor;

  /// Vielfaches auf die Breite der Perfect-Zone. Größer ist leichter.
  final double timingWindowFactor;

  bool get isEmpty =>
      damageFactor == 1.0 &&
      energyDiscount == 0 &&
      timingSpeedFactor == 1.0 &&
      timingWindowFactor == 1.0;

  /// Die Wirkung als kurze Liste, wie sie auf einer Kachel steht.
  ///
  /// Abgeleitet statt geschrieben — wer eine Zahl hier ändert, muss den
  /// Text nicht nachziehen. Dieselbe Bauform wie `GearBonus.labels`.
  List<String> get labels {
    return <String>[
      if (damageFactor != 1.0) '+${_prozent(damageFactor)} Schaden',
      if (energyDiscount != 0) '$energyDiscount Energie günstiger',
      if (timingSpeedFactor != 1.0)
        'Leiste ${_prozent(1 / timingSpeedFactor)} langsamer',
      if (timingWindowFactor != 1.0)
        'Fenster ${_prozent(timingWindowFactor)} breiter',
    ];
  }

  static String _prozent(double factor) => '${((factor - 1) * 100).round()} %';
}

/// Ein Ausrüstungs-Set: vier Stücke, zwei Stufen, eine Wirkung.
///
/// **Vier Teile heißt vier Plätze: Waffe, Rüstung, Helm, Schuhe.** Ring
/// und Talisman gehören bewusst zu keinem Set — sonst wäre ein voller Satz
/// gleichbedeutend mit „die ganze Ausrüstung steht fest", und es gäbe
/// nichts mehr zu wählen.
class GearSet {
  const GearSet({
    required this.id,
    required this.name,
    required this.target,
    required this.twoPiece,
    required this.fourPiece,
    required this.why,
  });

  /// Stabiler Bezeichner. Steht an den Stücken, nicht im Spielstand — was
  /// aktiv ist, folgt aus dem, was getragen wird.
  final String id;

  final String name;

  /// Worauf die Wirkung zielt.
  final SetTarget target;

  /// Ab zwei getragenen Teilen.
  final SetPerk twoPiece;

  /// Ab vier getragenen Teilen. Ersetzt [twoPiece], addiert sich nicht.
  final SetPerk fourPiece;

  /// Ein Satz dazu, für wen sich das Set lohnt. Gleiche Rolle wie
  /// `GearItem.why`: Eine Zahl allein erklärt keine Entscheidung.
  final String why;

  /// Wie viele Teile ein volles Set hat.
  static const int fullSize = 4;

  /// Ab wie vielen Teilen die kleine Stufe greift.
  static const int smallSize = 2;

  /// Was bei [pieces] getragenen Teilen anliegt. Null heißt: nichts.
  SetPerk? perkFor(int pieces) {
    if (pieces >= fullSize) return fourPiece;
    if (pieces >= smallSize) return twoPiece;
    return null;
  }
}

/// Ein Set, das gerade wirkt — mit der Zahl, die dazu geführt hat.
class ActiveSet {
  const ActiveSet({
    required this.set,
    required this.pieces,
    required this.perk,
  });

  final GearSet set;

  /// Wie viele Teile davon getragen werden.
  final int pieces;

  /// Was daraus folgt.
  final SetPerk perk;

  bool get isFull => pieces >= GearSet.fullSize;
}

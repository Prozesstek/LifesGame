/// Die sechs Ausrüstungsplätze aus dem Konzept, Abschnitt 3.1.
///
/// Ein Platz trägt genau ein Stück. Das ist die eigentliche Entscheidung
/// beim Ausrüsten: nicht *ob*, sondern *was davon*.
enum GearSlot {
  waffe('Waffe'),
  ruestung('Rüstung'),
  helm('Helm'),
  schuhe('Schuhe'),
  ring('Ring'),
  talisman('Talisman');

  const GearSlot(this.label);

  final String label;
}

/// Was ein Ausrüstungsstück auf die vier Charakterwerte gibt.
///
/// Bewusst dieselben vier Werte wie `package:habits` — aber als eigener
/// Typ, ohne Import. Die beiden Packages wissen nichts voneinander; die App
/// legt die Summen zusammen. Sonst hinge die Preisliste an der Stat-Kurve
/// und umgekehrt.
class GearBonus {
  const GearBonus({
    this.attack = 0,
    this.maxHp = 0,
    this.defense = 0,
    this.maxEnergy = 0,
  });

  final int attack;
  final int maxHp;
  final int defense;
  final int maxEnergy;

  GearBonus operator +(GearBonus other) {
    return GearBonus(
      attack: attack + other.attack,
      maxHp: maxHp + other.maxHp,
      defense: defense + other.defense,
      maxEnergy: maxEnergy + other.maxEnergy,
    );
  }

  bool get isEmpty =>
      attack == 0 && maxHp == 0 && defense == 0 && maxEnergy == 0;

  /// Die Wirkung als kurze Liste, wie sie auf einer Kachel steht.
  List<String> get labels {
    return <String>[
      if (attack != 0) '${_signed(attack)} Angriff',
      if (maxHp != 0) '${_signed(maxHp)} Lebenspunkte',
      if (defense != 0) '${_signed(defense)} Verteidigung',
      if (maxEnergy != 0) '${_signed(maxEnergy)} Energie',
    ];
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}

/// Wie selten ein Ausrüstungsstück ist.
///
/// **Ein eigener Typ, kein Import aus `package:abilities`.** Dieselbe
/// Überlegung wie bei [GearBonus]: Die beiden Packages wissen nichts
/// voneinander, und die Seltenheit einer Fähigkeit ist eine andere Sache
/// als die eines Ausrüstungsstücks — sie hängt dort an der Quelle
/// (Theorieknoten, Streak-Marke), hier am Preis und am Set.
///
/// **Fünf Stufen seit ADR-0034, vorher drei.** Der Grund für drei war:
/// Episch und Legendär sind in `package:abilities` der Lohn für tiefen
/// Fortschritt, und im Laden gab es nichts zu erreichen, nur zu kaufen.
/// Seit der Gegnerreihe (ADR-0032) gibt es dort etwas zu erreichen — die
/// beiden oberen Stufen hängen daran (`GearGates`) und sind damit
/// **verdient**, nicht nur teurer.
enum GearRarity {
  common('Gewöhnlich'),
  uncommon('Ungewöhnlich'),
  rare('Selten'),
  epic('Episch'),
  legendary('Legendär');

  /// Die drei Stufen, die von Anfang an kaufbar sind.
  static const List<GearRarity> open = <GearRarity>[common, uncommon, rare];

  /// Die beiden Stufen, die an der Gegnerreihe hängen.
  static const List<GearRarity> gated = <GearRarity>[epic, legendary];

  bool get isGated => gated.contains(this);

  const GearRarity(this.label);

  final String label;
}

/// Ein kaufbares Ausrüstungsstück.
class GearItem {
  const GearItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.price,
    required this.bonus,
    required this.why,
    this.setId,
    this.legendaryPower,
  });

  /// Stabiler Bezeichner für Speicherstände und Tests.
  final String id;

  final String name;
  final GearSlot slot;

  /// Wie selten das Stück ist.
  ///
  /// **Sie ist kein Etikett auf einer Leiter.** Innerhalb einer Stufe gilt
  /// weiter „teurer heißt besser"; zwischen den Stufen gilt das
  /// ausdrücklich **nicht** — ein seltenes Stück kann in reinen Zahlen
  /// schwächer sein und seinen Wert aus einem Set oder einer Fähigkeit
  /// ziehen (ADR-0029).
  final GearRarity rarity;

  /// Preis in Gold. Alle Preise stehen in `prices.dart` — hier landet nur
  /// das Ergebnis.
  final int price;

  final GearBonus bonus;

  /// Ein Satz dazu, was das Stück im Kampf ändert. Dieselbe Rolle wie
  /// `HabitTemplate.why`: Eine Zahl allein erklärt keine Entscheidung.
  final String why;

  /// Zu welchem Set dieses Stück gehört, oder null.
  ///
  /// **Die Zugehörigkeit steht hier und nicht im Set-Katalog.** Zwei
  /// Listen, die dasselbe behaupten, laufen auseinander — genau der
  /// Fallstrick aus `docs/context/gotchas.md`. `GearCatalog.piecesOf`
  /// liest diese Marke und ist damit die einzige Antwort auf „was gehört
  /// zu diesem Set".
  ///
  /// Set-Teile sind **gewöhnliche Stücke mit einer Marke**, keine eigene
  /// Klasse: Sie kosten dasselbe, wirken dasselbe und stehen an derselben
  /// Stelle im Laden. Nur wer zwei oder vier davon trägt, bekommt etwas
  /// obendrauf.
  final String? setId;

  bool get isSetPiece => setId != null;

  /// Was dieses Stück an Fähigkeiten verändert — nur bei legendären
  /// (ADR-0039).
  ///
  /// **Hier steht nur die Id**, die Wirkung steht in
  /// `package:action_combat` (`PitLegendaries`). Dieses Package kennt die
  /// Grube nicht, dieselbe Trennung wie bei den Waffenzügen. Dass jede Id
  /// dort ankommt, prüft `test/pit_test.dart` in der App.
  final String? legendaryPower;
}

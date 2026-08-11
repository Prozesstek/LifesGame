/// Saemtliche einstellbaren Zahlen des Kampfsystems.
///
/// Regel: Steht eine Zahl im Kampfcode statt hier, ist das ein Bug.
/// Balance-Aenderungen sollen eine Zeile sein, keine Suche.
class Balance {
  const Balance({
    this.timedHitPerfect = 1.5,
    this.timedHitGood = 1.25,
    this.timedHitNone = 1.0,
    this.damageVariance = 0.05,
    this.defenseSoftening = 100,
    this.minimumDamage = 1,
    this.poisonDamageFactor = 0.25,
    this.poisonDurationTurns = 3,
    this.defenseDownFactor = 0.7,
    this.defenseDownDurationTurns = 2,
    this.healFactorOfMaxHp = 0.25,
    this.shieldFactorOfMaxHp = 0.15,
    this.shieldDurationTurns = 2,
  });

  /// Obergrenze des Timed-Hit-Bonus. Das Konzept deckelt bewusst bei etwa
  /// +50 %, damit Habits der Hauptfaktor der Staerke bleiben und nicht
  /// Fingerfertigkeit. Wer diesen Wert erhoeht, kippt die Kernaussage
  /// des Spiels.
  final double timedHitPerfect;
  final double timedHitGood;
  final double timedHitNone;

  /// Zufaellige Streuung des Schadens, plus/minus. 0.05 = plus/minus 5 %.
  final double damageVariance;

  /// Weichzeichner der Verteidigungsformel: schaden * (k / (k + defense)).
  /// Groesserer Wert bedeutet, dass Verteidigung weniger stark wirkt.
  /// Diese Form verhindert negativen Schaden ohne harte Untergrenze.
  final int defenseSoftening;

  /// Ein Treffer landet immer mindestens diesen Schaden. Sonst entstehen
  /// Patt-Situationen gegen hohe Verteidigung.
  final int minimumDamage;

  /// Gift pro Runde, als Anteil des Angriffswerts des Verursachers.
  final double poisonDamageFactor;
  final int poisonDurationTurns;

  /// Verteidigung sinkt auf diesen Anteil. 0.7 = minus 30 %.
  final double defenseDownFactor;
  final int defenseDownDurationTurns;

  final double healFactorOfMaxHp;
  final double shieldFactorOfMaxHp;
  final int shieldDurationTurns;

  Balance copyWith({
    double? timedHitPerfect,
    double? timedHitGood,
    double? timedHitNone,
    double? damageVariance,
    int? defenseSoftening,
    int? minimumDamage,
    double? poisonDamageFactor,
    int? poisonDurationTurns,
    double? defenseDownFactor,
    int? defenseDownDurationTurns,
    double? healFactorOfMaxHp,
    double? shieldFactorOfMaxHp,
    int? shieldDurationTurns,
  }) {
    return Balance(
      timedHitPerfect: timedHitPerfect ?? this.timedHitPerfect,
      timedHitGood: timedHitGood ?? this.timedHitGood,
      timedHitNone: timedHitNone ?? this.timedHitNone,
      damageVariance: damageVariance ?? this.damageVariance,
      defenseSoftening: defenseSoftening ?? this.defenseSoftening,
      minimumDamage: minimumDamage ?? this.minimumDamage,
      poisonDamageFactor: poisonDamageFactor ?? this.poisonDamageFactor,
      poisonDurationTurns: poisonDurationTurns ?? this.poisonDurationTurns,
      defenseDownFactor: defenseDownFactor ?? this.defenseDownFactor,
      defenseDownDurationTurns:
          defenseDownDurationTurns ?? this.defenseDownDurationTurns,
      healFactorOfMaxHp: healFactorOfMaxHp ?? this.healFactorOfMaxHp,
      shieldFactorOfMaxHp: shieldFactorOfMaxHp ?? this.shieldFactorOfMaxHp,
      shieldDurationTurns: shieldDurationTurns ?? this.shieldDurationTurns,
    );
  }
}

/// Offene Balance-Fragen aus `konzept.md` Abschnitt 6.
///
/// Diese Werte gehoeren noch nicht ins Kampfsystem, beeinflussen es aber.
/// Sie stehen hier, damit sie nicht vergessen werden, wenn die
/// Entscheidungen fallen.
///
/// 1. Streak-Multiplikator: Konzept empfiehlt Deckel bei x2. Noch offen,
///    beeinflusst die Stat-Kurve und damit jede Gegnerauslegung.
/// 2. Gold-Abfluesse: Traenke, Wiederbelebung, Streak-Schutz fehlen im
///    Shop. Betrifft die Dungeon-Oekonomie, nicht den Einzelkampf.
/// 3. Niederlagen-Regel: verfallener Dungeon-Eintritt plus Neustart
///    bestraft doppelt. Ohne Wiederbelebung droht eine Abwaertsspirale.
///    Betrifft die Dungeon-Schicht, die auf dieser Kampflogik aufsetzt.
const List<String> openBalanceQuestions = <String>[
  'Streak-Multiplikator-Deckel festlegen (Empfehlung: x2)',
  'Gold-Abfluesse erweitern (Traenke, Wiederbelebung, Streak-Schutz)',
  'Niederlagen-Regel entschaerfen (Wiederbelebungs-Item?)',
];

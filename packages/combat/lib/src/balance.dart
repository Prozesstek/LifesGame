/// Saemtliche einstellbaren Zahlen des Kampfsystems.
///
/// Regel: Steht eine Zahl im Kampfcode statt hier, ist das ein Bug.
/// Balance-Aenderungen sollen eine Zeile sein, keine Suche.
class Balance {
  const Balance({
    this.timedHitPerfect = 1.2,
    this.timedHitGood = 1.1,
    this.timedHitNone = 1.0,
    this.damageVariance = 0.05,
    this.defenseSoftening = 45,
    this.minimumDamage = 1,
    this.poisonDamageFactor = 0.25,
    this.poisonDurationTurns = 3,
    this.defenseDownFactor = 0.7,
    this.defenseDownDurationTurns = 2,
    this.healFactorOfAttack = 1.0,
    this.shieldFactorOfAttack = 0.6,
    this.shieldDurationTurns = 2,
  });

  /// Obergrenze des Timed-Hit-Bonus.
  ///
  /// Das Konzept nannte +50 %. Die Simulation hat gezeigt, dass das nicht
  /// als Bonus wirkt, sondern den Kampf allein entscheidet: gleiche Werte,
  /// 56 % Siegquote ohne Timing gegen 100 % mit perfektem Timing. Ein
  /// pauschaler Schadensfaktor wirkt in einem Rennen linear, egal wie lang
  /// es dauert -- deshalb ist der Deckel auf +20 % gesenkt (ADR-0009).
  ///
  /// Wer diesen Wert erhoeht, kippt die Kernaussage des Spiels: Staerke
  /// kommt aus Gewohnheiten, nicht aus Fingerfertigkeit.
  final double timedHitPerfect;
  final double timedHitGood;
  final double timedHitNone;

  /// Zufaellige Streuung des Schadens, plus/minus. 0.05 = plus/minus 5 %.
  final double damageVariance;

  /// Weichzeichner der Verteidigungsformel: schaden * (k / (k + defense)).
  /// Groesserer Wert bedeutet, dass Verteidigung weniger stark wirkt.
  /// Diese Form verhindert negativen Schaden ohne harte Untergrenze.
  ///
  /// Bei 100 war Verteidigung fast wirkungslos: Der Sprung von 8 auf 14
  /// senkte den erlittenen Schaden um 5 %, Disziplin war damit ein
  /// Zierwert. Bei 45 sind es 11 % -- eine zweite Achse, ueber die der
  /// Charakter waechst, statt nur ueber den Angriff (ADR-0009).
  ///
  /// Noch kleinere Werte sind eine Falle: Bei 20 sinkt der Schaden so
  /// weit, dass Heilung ihn ueberholt und Kaempfe nicht mehr enden.
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

  /// Heilung von "Sammeln", als Vielfaches des eigenen Angriffswerts.
  ///
  /// Frueher ein Anteil der maximalen HP (25 %). Das war ein latenter
  /// Fehler: Waechst der HP-Pool schneller als der Schaden, heilt sich
  /// jede Seite schneller, als die andere zuschlagen kann, und der Kampf
  /// endet nie. In der Simulation trat genau das auf, sobald die
  /// Kampflaenge angehoben wurde -- 94 Runden im Schnitt, Siegquoten die
  /// mit besseren Werten *sanken* (siehe `docs/context/gotchas.md`).
  ///
  /// An den Angriffswert gekoppelt kann das nicht passieren: Heilung und
  /// Schaden sind dann dieselbe Einheit, und das Verhaeltnis bleibt
  /// erhalten, egal wie gross die HP-Pools werden. Gleiche Bauart wie
  /// [poisonDamageFactor], der es schon immer so gemacht hat (ADR-0009).
  final double healFactorOfAttack;

  /// Schild von "Sammeln", ebenfalls als Vielfaches des Angriffswerts.
  /// Zusammen mit [healFactorOfAttack] muss die Summe deutlich unter dem
  /// liegen, was der Gegner in derselben Zeit anrichtet.
  final double shieldFactorOfAttack;

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
    double? healFactorOfAttack,
    double? shieldFactorOfAttack,
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
      healFactorOfAttack: healFactorOfAttack ?? this.healFactorOfAttack,
      shieldFactorOfAttack: shieldFactorOfAttack ?? this.shieldFactorOfAttack,
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
/// 1. Gold-Abfluesse: Traenke, Wiederbelebung, Streak-Schutz fehlen im
///    Shop. Betrifft die Dungeon-Oekonomie, nicht den Einzelkampf.
/// 2. Niederlagen-Regel: verfallener Dungeon-Eintritt plus Neustart
///    bestraft doppelt. Ohne Wiederbelebung droht eine Abwaertsspirale.
///    Betrifft die Dungeon-Schicht, die auf dieser Kampflogik aufsetzt.
///
/// Der Streak-Multiplikator ist mit ADR-0008 entschieden (Deckel x2) und
/// steht in `packages/habits/lib/src/rewards.dart`. Die Spielerwerte kommen
/// seither von dort: Angriff 13 bis 20, HP 100 bis 140. Wer an dieser Datei
/// dreht, muss die Stat-Kurve dort mitdenken.
const List<String> openBalanceQuestions = <String>[
  'Gold-Abfluesse erweitern (Traenke, Wiederbelebung, Streak-Schutz)',
  'Niederlagen-Regel entschaerfen (Wiederbelebungs-Item?)',
];

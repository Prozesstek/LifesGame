/// Die Zahlen, an denen sich entscheidet, ob ein Titel verdient ist.
///
/// **Warum eine eigene kleine Klasse und nicht die echten Objekte.** Dieses
/// Package kennt weder `package:habits` noch `package:theory` — sonst wäre
/// es kein reines Dart-Package mehr und die Schichtregel aus `CLAUDE.md`
/// wäre nur noch Vereinbarung. Die App reicht drei Zahlen herein; woher sie
/// stammen, ist hier gleichgültig.
class TitleStats {
  const TitleStats({
    this.longestStreak = 0,
    this.passedLessons = 0,
    this.totalChecks = 0,
  });

  const TitleStats.empty() : this();

  /// Die längste je gelaufene Kette, **nicht** die laufende. Ein Titel
  /// darf beim Reißen der Streak nicht verschwinden (ADR-0013).
  final int longestStreak;

  /// Bestandene Lektionen über den ganzen Baum.
  final int passedLessons;

  /// Alle je gesetzten Häkchen.
  final int totalChecks;
}

/// Ein Titel, der neben dem Namen steht.
///
/// Titel werden **verdient, nicht gewählt** — das ist der Kern von
/// ADR-0013. Wählbar ist nur, welchen der verdienten man trägt.
class CharacterTitle {
  const CharacterTitle({
    required this.id,
    required this.label,
    required this.requirement,
    this.requiredStreak = 0,
    this.requiredLessons = 0,
    this.requiredChecks = 0,
  });

  /// Stabiler Bezeichner für Speicherstände und Tests.
  final String id;

  /// Der Wortlaut, wie ihn der Spieler sieht — „der Beständige".
  final String label;

  /// Die Bedingung im Klartext, für die Anzeige gesperrter Titel.
  ///
  /// Steht als Text daneben statt aus den Zahlen erzeugt zu werden: Der
  /// Ladenbildschirm zeigt vor, dass eine Bedingung lesbar sein muss, nicht
  /// nur korrekt.
  final String requirement;

  /// Alle drei Schwellen müssen erfüllt sein. In der Praxis setzt jeder
  /// Titel genau eine — mehrere bleiben möglich, ohne dass der Katalog
  /// dafür umgebaut werden müsste.
  final int requiredStreak;
  final int requiredLessons;
  final int requiredChecks;

  bool isEarnedBy(TitleStats stats) {
    return stats.longestStreak >= requiredStreak &&
        stats.passedLessons >= requiredLessons &&
        stats.totalChecks >= requiredChecks;
  }

  /// Wie viel an der Bedingung noch fehlt — 0, wenn der Titel verdient ist.
  ///
  /// Für die Anzeige „noch 12 Tage": Der Laden macht es genauso, und ein
  /// gesperrter Eintrag ohne Abstand zum Ziel ist nur eine Absage.
  int missingFor(TitleStats stats) {
    final gaps = <int>[
      requiredStreak - stats.longestStreak,
      requiredLessons - stats.passedLessons,
      requiredChecks - stats.totalChecks,
    ];
    var worst = 0;
    for (final gap in gaps) {
      if (gap > worst) worst = gap;
    }
    return worst;
  }
}

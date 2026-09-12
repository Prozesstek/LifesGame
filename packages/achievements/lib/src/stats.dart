/// Die Zahlen, an denen sich entscheidet, was verdient ist.
///
/// **Warum eine eigene kleine Klasse und nicht die echten Objekte.**
/// Dieses Package kennt keines der anderen sieben — sonst wäre es kein
/// reines Dart-Package mehr und die Schichtregel aus `CLAUDE.md` wäre nur
/// noch Vereinbarung. Die App reicht Zahlen herein; woher sie stammen, ist
/// hier gleichgültig. Gleiche Bauform wie `TitleStats` (ADR-0014) und
/// `AbilityProgress` (ADR-0017).
///
/// **Jede Zahl hier darf nie fallen** — das ist Punkt 3 aus ADR-0033 und
/// keine Empfehlung. Deshalb steht hier die *längste* Kette und nicht die
/// laufende, „je besessen" und nicht „gerade getragen", die höchste
/// Sprosse und nicht die nächste. Eine Errungenschaft, die wieder
/// verschwindet, wäre schlimmer als keine: Sie nähme etwas weg, das
/// jemand schon hatte.
///
/// Wer eine Zahl ergänzt, deren Wert sinken kann, macht den Katalog
/// unbrauchbar — auch wenn heute keine Bedingung daran hängt.
class AchievementStats {
  const AchievementStats({
    this.totalChecks = 0,
    this.longestStreak = 0,
    this.customHabitCount = 0,
    this.daysWithThreeChecks = 0,
    this.longestRunWithThreeChecks = 0,
    this.checksOnHardCustomHabits = 0,
    this.comebackStreak = 0,
    this.passedLessons = 0,
    this.perfectLessons = 0,
    this.completedAreas = 0,
    this.areasWithPassedNode = 0,
    this.retriedLessons = 0,
    this.highestRung = 0,
    this.comebackVictories = 0,
    this.everOwnedCount = 0,
    this.slotsEverOwned = 0,
    this.completeSetsEverOwned = 0,
    this.soldCount = 0,
  });

  const AchievementStats.empty() : this();

  // --- Gewohnheiten ---

  /// Alle je gesetzten Häkchen.
  final int totalChecks;

  /// Die längste je gelaufene Kette, **nicht** die laufende.
  final int longestStreak;

  /// Wie viele eigene Gewohnheiten angelegt wurden (ADR-0028).
  final int customHabitCount;

  /// Tage, an denen mindestens drei Häkchen gesetzt wurden.
  ///
  /// **Nicht „alle erledigt", und das ist kein Ungenauigkeit.**
  /// `HabitTracker.isDayComplete` vergleicht mit der *heutigen* Liste
  /// laufender Gewohnheiten; welche an einem vergangenen Tag liefen,
  /// steht nirgends. „Alles erledigt" ist damit rückwirkend nicht
  /// bestimmbar — und rückwirkend muss es sein (ADR-0033, Punkt 2).
  final int daysWithThreeChecks;

  /// Die längste ununterbrochene Folge solcher Tage.
  final int longestRunWithThreeChecks;

  /// Häkchen auf eigenen Gewohnheiten mit dem Grad „schwer".
  ///
  /// Vorlagen zählen nicht mit: Sie sind immer „mittel", und der Grad ist
  /// die einzige Stelle, an der jemand sich selbst etwas abverlangt hat.
  final int checksOnHardCustomHabits;

  /// Die längste Kette, die **nach** einer Pause begonnen hat.
  ///
  /// Wie lang die Pause mindestens sein muss, steht im Katalog und nicht
  /// hier — diese Zahl misst nur, was danach kam.
  final int comebackStreak;

  // --- Theorie ---

  /// Bestandene Seiten aus Handbuch **und** Graph.
  final int passedLessons;

  /// Seiten, bei denen alle Fragen saßen.
  final int perfectLessons;

  /// Gebiete des Baums, die vollständig bestanden sind.
  final int completedAreas;

  /// Gebiete, in denen mindestens ein Knoten bestanden ist.
  final int areasWithPassedNode;

  /// Lektionen, die bestanden wurden, nachdem sie vorher misslungen
  /// waren. Braucht die Spur `LessonRecord.failedAttempts` und zählt
  /// deshalb erst ab deren Einbau (ADR-0033).
  final int retriedLessons;

  // --- Kampf ---

  /// Die höchste geschlagene Sprosse.
  final int highestRung;

  /// Sprossen, die nach mindestens drei Niederlagen doch fielen. Braucht
  /// die Spur `LadderProgress.defeats` und zählt ebenfalls erst ab deren
  /// Einbau.
  final int comebackVictories;

  // --- Laden ---

  /// Wie viele verschiedene Stücke je besessen wurden — Verkauftes
  /// eingeschlossen.
  ///
  /// **„Je besessen" und nicht „im Besitz".** Ein Verkauf darf keine
  /// Errungenschaft zurücknehmen. Dass sich das überhaupt rechnen lässt,
  /// liegt an ADR-0031: `Loadout.soldIds` ist eine Historie, keine
  /// Bilanz.
  final int everOwnedCount;

  /// Auf wie vielen der sechs Plätze je ein Stück lag.
  final int slotsEverOwned;

  /// Wie viele der drei Sets je vollständig zusammen waren — Stück für
  /// Stück gezählt, nicht gleichzeitig getragen.
  final int completeSetsEverOwned;

  /// Wie oft verkauft wurde.
  final int soldCount;
}

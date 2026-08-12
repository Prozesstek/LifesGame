/// Der Charakterwert, auf den eine Gewohnheit einzahlt.
///
/// Vier Werte, weil der Kampf genau vier kennt. Jede Gewohnheit speist
/// **einen** davon — nicht zwei, nicht anteilig. Sonst ist beim Abhaken
/// nicht mehr zu sehen, wofür man es tut.
enum HabitStat {
  /// Körperliche Anstrengung und Mut → Angriff.
  staerke('Stärke', 'Angriff'),

  /// Versorgung und Erholung → Lebenspunkte.
  ausdauer('Ausdauer', 'Lebenspunkte'),

  /// Selbststeuerung und Planung → Verteidigung.
  disziplin('Disziplin', 'Verteidigung'),

  /// Aufmerksamkeit → Energie im Kampf.
  klarheit('Klarheit', 'Energie');

  const HabitStat(this.label, this.combatLabel);

  /// Name des Werts, wie ihn der Spieler sieht.
  final String label;

  /// Was der Wert im Kampf bewirkt — die Übersetzung gehört sichtbar in
  /// die Oberfläche, sonst bleibt der Kern-Loop unsichtbar.
  final String combatLabel;
}

/// Eine Gewohnheits-Vorlage, wie sie der Skillbaum freischaltet.
///
/// Die Vorlagen sind Inhalt, kein Nutzerzustand: Der Spieler wählt aus
/// ihnen aus, erfindet aber keine eigenen. Das Konzept verlangt die feste
/// Verknüpfung von Vorlage, Stat und Theoriezweig (Abschnitt 3.7).
class HabitTemplate {
  const HabitTemplate({
    required this.id,
    required this.name,
    required this.stat,
    required this.branchId,
    required this.why,
  });

  /// Stabiler Bezeichner für Speicherstände und Tests.
  final String id;

  /// Der Wortlaut, den der Spieler abhakt. Identisch mit dem
  /// `unlocksHabit` der freischaltenden Lektion — geprüft in
  /// `test/habits_theory_test.dart`.
  final String name;

  final HabitStat stat;

  /// Der Theoriezweig, aus dem die Vorlage stammt.
  final String branchId;

  /// Ein Satz, warum diese Gewohnheit wirkt. Die Lektion hat es erklärt,
  /// die Erinnerung gehört auf die Kachel.
  final String why;
}

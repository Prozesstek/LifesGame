import 'habit.dart';

/// Die vier **Gebiete**, in die eine Gewohnheit einzahlt (ADR-0085).
///
/// Es sind dieselben vier wie die Wurzeln des Wissensbaums, und der Name
/// jedes Eintrags ist die Id seiner Wurzel. `package:theory` und
/// `package:habits` wissen nichts voneinander; dass beide Seiten
/// zusammenpassen, prüft `test/skills_test.dart` in der App.
///
/// **Warum vier und nicht feiner.** Jeder bekommt dieselben Skills, sonst
/// lässt sich nicht vergleichen — und jede Seite des Baums gehört schon
/// heute zu genau einem dieser Gebiete. Sport heißt dabei Körper.
///
/// **Das Gebiet bestimmt auch den Kampfwert** (ADR-0088): Wer trainiert,
/// schlägt härter; ein klarer Kopf treibt die Fähigkeiten an; wer
/// versteht, sieht den Schlag kommen; Freunde halten dich am Leben. Vier
/// Gebiete, vier Werte — beim Anlegen ist das eine Frage statt zwei, und
/// wer in allen vier Gebieten lebt, ist im Kampf rund.
enum SkillArea {
  koerper('Körper', HabitStat.staerke),
  geist('Geist', HabitStat.klarheit),
  wissenschaft('Wissenschaft', HabitStat.disziplin),
  gesellschaft('Gesellschaft', HabitStat.ausdauer);

  const SkillArea(this.label, this.kampfwert);

  /// Name des Gebiets, wie ihn der Spieler sieht.
  final String label;

  /// Der Kampfwert, den jede Gewohnheit dieses Gebiets steigert — die
  /// **einzige** Stelle, an der das steht. `Habit.stat` fragt hier.
  final HabitStat kampfwert;

  /// Liest den gespeicherten Namen. Null bei allem, was nicht passt —
  /// nachsichtig wie alles, was aus einem Spielstand kommt.
  static SkillArea? tryParse(Object? value) {
    for (final area in values) {
      if (area.name == value) return area;
    }
    return null;
  }
}

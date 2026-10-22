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
enum SkillArea {
  koerper('Körper'),
  geist('Geist'),
  wissenschaft('Wissenschaft'),
  gesellschaft('Gesellschaft');

  const SkillArea(this.label);

  /// Name des Gebiets, wie ihn der Spieler sieht.
  final String label;

  /// Liest den gespeicherten Namen. Null bei allem, was nicht passt —
  /// nachsichtig wie alles, was aus einem Spielstand kommt.
  static SkillArea? tryParse(Object? value) {
    for (final area in values) {
      if (area.name == value) return area;
    }
    return null;
  }
}

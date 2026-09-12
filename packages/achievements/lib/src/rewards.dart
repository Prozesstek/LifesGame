/// Was eine Errungenschaft einbringt.
///
/// **Alle Zahlen stehen hier, und nur hier.** Gleiche Regel wie bei
/// `TheoryRewards`, `HabitRewards`, `GearPrices` und `LadderRewards`:
/// Steht eine dieser Zahlen irgendwo anders im Code, ist das ein Bug.
///
/// **Meilensteine zahlen, Entdeckungen nicht** — der Kern von ADR-0033.
/// Das Issue begründet Entdeckungen mit Selbstbild und Identität, und
/// genau dafür ist äußere Belohnung schädlich: Wer für ein Selbstbild
/// bezahlt wird, lernt, dass es um die Bezahlung ging. Meilensteine sind
/// dagegen ehrlich Leistung und zahlen deshalb — einmalig, nach demselben
/// Vorbild wie eine Lektion und eine Sprosse der Reihe (ADR-0032).
///
/// Wer an diesen Zahlen dreht, lässt `flutter test
/// test/progression_test.dart` laufen: Errungenschaften sind seit
/// ADR-0033 der fünfte Zufluss in die vier Kurven.
enum AchievementTier {
  klein(xp: 30, gold: 10, fame: 5),
  mittel(xp: 75, gold: 25, fame: 10),
  gross(xp: 150, gold: 50, fame: 25),

  /// Die Stufe jeder Entdeckung: kein Gold, keine Erfahrung, nur Ruhm.
  entdeckung(xp: 0, gold: 0, fame: 15);

  const AchievementTier({
    required this.xp,
    required this.gold,
    required this.fame,
  });

  final int xp;
  final int gold;

  /// **Ruhm ist ein Stand, kein Zahlungsmittel** (ADR-0033, Punkt 5). Er
  /// soll Ziel 7 dienen: Zwei Spieler vergleichen „340 gegen 410", wie
  /// „17 / 30" bei der Reihe. Der Name ist bewusst kein „…punkte" —
  /// Theorie- und Fähigkeitspunkte gibt man aus, Ruhm nicht.
  final int fame;
}

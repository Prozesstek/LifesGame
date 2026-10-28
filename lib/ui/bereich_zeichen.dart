/// **Das Zeichen jedes Bereichs** — eine Tabelle für die Kreise der
/// Startseite und für jede Stelle, die in einen Bereich führt: die Tipps
/// nach einer Niederlage, die Wege im Charakter, das Buch in der Grube.
/// Ein Bereich, ein Zeichen; zwei Stellen mit verschiedenen Bildern
/// läsen sich als zwei Dinge.
abstract final class BereichZeichen {
  // **Jeder Kreis trägt, was ein Spieler aus RPGs kennt** (28.10.2026,
  // Frederik: „passendere Icons wählen, vielleicht gucken, was der
  // Spieler aus anderen Spielen gelernt hat“): die Quest-Rolle, die
  // gekreuzten Schwerter, den Münzbeutel, den Rucksack fürs Inventar,
  // den Helm für den Charakterbogen. Gezeichnet im Pixelstil wie Holz
  // und Figuren, nicht als Systemzeichen; woher jedes kommt, steht in
  // `tool/kreis_zeichen.py`. Das Systemzeichen bleibt nur Ersatz.

  /// Die Schriftrolle mit Haken auf dem Gewohnheiten-Kreis — die Quest.
  static const String gewohnheiten = 'assets/UI/Kreis_Gewohnheiten.png';

  /// Die gekreuzten Schwerter auf dem Kampf-Kreis, wie auf „Hinab“.
  static const String kampf = 'assets/UI/Kreis_Kampf.png';

  /// Drei Balken, die steigen, auf dem Statistik-Kreis.
  static const String statistik = 'assets/UI/Kreis_Statistik.png';

  /// Der Münzbeutel auf dem Laden-Kreis.
  static const String laden = 'assets/UI/Kreis_Laden.png';

  /// Der leuchtende Runenstein auf dem Fähigkeiten-Kreis (ADR-0049). Bis
  /// zum 28.10. das Bild von Sternenfall — ein Stern liest sich eher als
  /// Bewertung denn als Kraft.
  static const String faehigkeiten = 'assets/UI/Kreis_Faehigkeiten.png';

  /// Der Rucksack auf dem Ausrüstungs-Kreis (ADR-0057) — das Inventar,
  /// wie in fast jedem Spiel. Bis zum 28.10. der Plattenharnisch.
  static const String ausruestung = 'assets/UI/Kreis_Ausruestung.png';

  /// Der Helm auf dem Charakter-Kreis — der Charakterbogen. Bis zum
  /// 28.10. ein Profil-Männchen wie in einer App.
  static const String charakter = 'assets/UI/Kreis_Charakter.png';

  /// Das Buch auf dem Theorie-Kreis — Frederiks Zeichnung, 64 × 64.
  static const String theorie = 'assets/UI/Buch.png';
}

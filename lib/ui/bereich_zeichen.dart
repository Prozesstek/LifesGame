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

  /// Alle Zeichen der Kreise.
  static const List<String> alle = <String>[
    gewohnheiten,
    theorie,
    kampf,
    statistik,
    laden,
    faehigkeiten,
    ausruestung,
    charakter,
  ];

  /// **Wie weit ein Zeichen von seiner Mitte reicht** — der äußerste
  /// gezeichnete Bildpunkt, gemessen in halben Bildbreiten: 1 berührt
  /// die Mitte jeder Kante, √2 reicht bis in die Ecken (29.10.2026).
  ///
  /// Danach wird ein Zeichen im Kreis verkleinert, damit es **innerhalb
  /// bleibt** (`HubCircle`): Die Schwerter reichen bis in die Ecken und
  /// stachen über den Rand. Gemessen und aufgerundet;
  /// `test/bereich_zeichen_test.dart` misst nach, ob keine Zahl zu klein
  /// ist. Ein unbekanntes Bild gilt als bis in die Ecken gefüllt.
  static double reichweite(String pfad) => switch (pfad) {
    gewohnheiten => 1.18,
    theorie => 0.99,
    kampf => 1.42,
    statistik => 1.11,
    laden => 1.26,
    faehigkeiten => 1.18,
    ausruestung => 0.96,
    charakter => 0.84,
    _ => 1.42,
  };
}

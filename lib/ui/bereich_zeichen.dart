/// **Das Zeichen jedes Bereichs** — eine Tabelle für die Kreise der
/// Startseite und für jede Stelle, die in einen Bereich führt: die Tipps
/// nach einer Niederlage, die Wege im Charakter, das Buch in der Grube.
/// Ein Bereich, ein Zeichen; zwei Stellen mit verschiedenen Bildern
/// läsen sich als zwei Dinge.
abstract final class BereichZeichen {
  // **Jeder Kreis trägt, was ein Spieler aus RPGs kennt** (28.10.2026,
  // Frederik: „passendere Icons wählen, vielleicht gucken, was der
  // Spieler aus anderen Spielen gelernt hat“): die Quest-Rolle, die
  // gekreuzten Schwerter, den Münzbeutel, den Harnisch für die Ausrüstung,
  // den Helm für den Charakterbogen. Gezeichnet im Pixelstil wie Holz
  // und Figuren, nicht als Systemzeichen; woher jedes kommt, steht in
  // `tool/kreis_zeichen.py`. Das Systemzeichen bleibt nur Ersatz.

  /// Die Schriftrolle mit Haken auf dem Gewohnheiten-Kreis — die Quest.
  /// Seit dem 04.11.2026 gezeichnet mit pxl:
  /// `tool/pixel/kreis_gewohnheiten.px.js`.
  static const String gewohnheiten = 'assets/UI/Kreis_Gewohnheiten.png';

  /// Die gekreuzten Schwerter auf dem Kampf-Kreis, wie auf „Hinab“ —
  /// seit dem 04.11.2026 gezeichnet mit pxl: `tool/pixel/kreis_kampf.px.js`.
  static const String kampf = 'assets/UI/Kreis_Kampf.png';

  /// Drei Balken, die steigen, und ein goldener Pfeil darüber —
  /// gezeichnet mit pxl (`tool/pixel/kreis_statistik.px.js`).
  static const String statistik = 'assets/UI/Kreis_Statistik.png';

  /// Ein praller Lederbeutel voller Gold, davor Münzen — gezeichnet mit
  /// pxl (`tool/pixel/kreis_laden.px.js`).
  static const String laden = 'assets/UI/Kreis_Laden.png';

  /// Ein schräg liegendes Zauberbuch mit Flammensiegel auf dem
  /// Fähigkeiten-Kreis (ADR-0049) — gezeichnet mit pxl
  /// (`tool/pixel/kreis_faehigkeiten.px.js`). Bis zum 28.10. das Bild von
  /// Sternenfall, bis zum 08.11. ein Runenstein aus Raven.
  static const String faehigkeiten = 'assets/UI/Kreis_Faehigkeiten.png';

  /// Ein Plattenharnisch mit Goldbeschlag auf dem Ausrüstungs-Kreis
  /// (ADR-0057) — gezeichnet mit pxl (`tool/pixel/kreis_ausruestung.px.js`).
  /// Vom 28.10. bis 10.11. ein Rucksack.
  static const String ausruestung = 'assets/UI/Kreis_Ausruestung.png';

  /// Der Helm auf dem Charakter-Kreis — der Charakterbogen. Bis zum
  /// 28.10. ein Profil-Männchen wie in einer App.
  static const String charakter = 'assets/UI/Kreis_Charakter.png';

  /// Das Buch auf dem Theorie-Kreis — ein Foliant mit dem Talentbaum,
  /// seit dem 04.11.2026 gezeichnet mit pxl: `tool/pixel/kreis_theorie.px.js`.
  /// Bis dahin Frederiks Zeichnung.
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
    gewohnheiten => 1.31,
    theorie => 1.16,
    kampf => 1.07,
    statistik => 1.18,
    laden => 1.26,
    faehigkeiten => 1.25,
    ausruestung => 1.0,
    charakter => 0.84,
    _ => 1.42,
  };
}

/// Die sieben Bereiche der Startseite.
enum Bereich {
  gewohnheiten,
  kampf,
  theorie,
  faehigkeiten,
  laden,
  ausruestung,
  charakter,
}

/// Was die Aufdeck-Regel wissen muss — Zahlen, keine Objekte.
///
/// **Jede Angabe hier darf nur wachsen**, aus demselben Grund wie bei
/// den Errungenschaften (ADR-0033): Ein Kreis, der wieder verschwindet,
/// wäre schlimmer als einer, der fehlt. Deshalb „je gesetzte Häkchen“
/// statt „heute abgehakt“ und „je besessen“ statt „im Besitz“.
class ErsterStartStand {
  const ErsterStartStand({
    this.hatGewohnheit = false,
    this.haekchen = 0,
    this.hatGekaempft = false,
    this.seiten = 0,
    this.handbuchFertig = false,
    this.gelernt = 0,
    this.angelegt = 0,
    this.goldVerdient = 0,
    this.billigstesStueck = 0,
    this.jeBesessen = 0,
    this.level = 1,
  });

  /// Ob je eine Gewohnheit lief oder angelegt wurde.
  final bool hatGewohnheit;

  /// Alle je gesetzten Häkchen.
  final int haekchen;

  /// Ob ein Lauf in der Grube zu Ende ging, gewonnen oder verloren.
  final bool hatGekaempft;

  /// Bestandene Seiten aus Handbuch und Baum.
  final int seiten;

  final bool handbuchFertig;

  /// Freigeschaltete Fähigkeiten.
  final int gelernt;

  /// Fähigkeiten, die auf einem Platz liegen — die einzige Zahl, die
  /// fallen kann. An ihr hängt nur ein Leuchten, kein Kreis.
  final int angelegt;

  /// Gold, das je eingenommen wurde, vor Ausgaben.
  final int goldVerdient;

  /// Was das billigste Stück im Laden kostet (`GearCatalog`).
  final int billigstesStueck;

  /// Wie viele verschiedene Stücke je besessen wurden.
  final int jeBesessen;

  final int level;
}

/// Welche Bereiche die Startseite zeigt, und welcher gerade dran ist.
///
/// **Abgeleitet, nie gezählt** (ADR-0068). Es gibt keinen gespeicherten
/// Tutorial-Schritt: Ein Stand, der schon weiter ist, sieht sofort alles,
/// und ein eingefügter Stand braucht keine Übernahme.
///
/// Die Reihenfolge ist „Kampf früh“: fragen, abhaken, kämpfen, lesen,
/// Fähigkeit anlegen. Laden, Ausrüstung und Charakter kommen dazu, sobald
/// es dort etwas zu tun gibt.
class ErsterStart {
  const ErsterStart._(this.sichtbar, this.leuchtet, this.fragtNachGewohnheit);

  /// Alles offen, nichts leuchtet — für Tests anderer Bereiche und für
  /// jeden Stand, der durch ist.
  static const ErsterStart allesOffen = ErsterStart._(
    <Bereich>{
      Bereich.gewohnheiten,
      Bereich.kampf,
      Bereich.theorie,
      Bereich.faehigkeiten,
      Bereich.laden,
      Bereich.ausruestung,
      Bereich.charakter,
    },
    null,
    false,
  );

  /// Ab so vielen Häkchen zeigt sich die Theorie auch ohne Kampf.
  ///
  /// **Niemand muss kämpfen, um zu lesen.** Wer die Grube auslässt, wäre
  /// sonst für immer vom Baum ausgesperrt — von dem Teil, der die
  /// Gewohnheiten trägt.
  static const int haekchenFuerTheorie = 3;

  /// Ab diesem Level zeigt sich der Charakter: Mit dem ersten Aufstieg
  /// gibt es dort zum ersten Mal etwas zu sehen.
  static const int levelFuerCharakter = 2;

  final Set<Bereich> sichtbar;

  /// Der Kreis, der als Nächstes dran ist — höchstens einer.
  final Bereich? leuchtet;

  /// Ob „Heute“ statt einer Liste die erste Frage stellt.
  final bool fragtNachGewohnheit;

  bool zeigt(Bereich bereich) => sichtbar.contains(bereich);

  /// Ob alle sieben Kreise stehen.
  bool get fertig => sichtbar.length == Bereich.values.length;

  /// Tagesaufgaben und Truhe kommen mit dem ersten Häkchen — vorher
  /// stünden dort drei Aufgaben, bevor es eine Gewohnheit gibt.
  bool get zeigtTagesaufgaben => zeigt(Bereich.kampf);

  static ErsterStart aus(ErsterStartStand s) {
    // **Jede Bedingung nennt auch, was erst später kommen kann.** So
    // bleibt die Reihe geschlossen, auch wenn ein Stand einen Schritt
    // übersprungen hat (Entwicklermodus, eingefügter Stand).
    final faehigkeiten = s.handbuchFertig || s.gelernt > 0 || s.angelegt > 0;
    final theorie =
        faehigkeiten ||
        s.hatGekaempft ||
        s.seiten > 0 ||
        s.haekchen >= haekchenFuerTheorie;
    final kampf = theorie || s.haekchen > 0;

    final sichtbar = <Bereich>{
      Bereich.gewohnheiten,
      if (kampf) Bereich.kampf,
      if (theorie) Bereich.theorie,
      if (faehigkeiten) Bereich.faehigkeiten,
      if (s.jeBesessen > 0 || s.goldVerdient >= s.billigstesStueck)
        Bereich.laden,
      if (s.jeBesessen > 0) Bereich.ausruestung,
      if (s.level >= levelFuerCharakter) Bereich.charakter,
    };

    return ErsterStart._(
      Set<Bereich>.unmodifiable(sichtbar),
      _naechster(s, kampf: kampf, theorie: theorie, faehigkeiten: faehigkeiten),
      !s.hatGewohnheit && s.haekchen == 0,
    );
  }

  /// Der jüngste Kreis der Hauptlinie, der noch nicht benutzt wurde.
  ///
  /// Jede Bedingung erledigt sich selbst: Wer gekämpft hat, bei dem
  /// leuchtet der Kampf nie wieder. Laden, Ausrüstung und Charakter
  /// leuchten nicht — sie erscheinen nur.
  static Bereich? _naechster(
    ErsterStartStand s, {
    required bool kampf,
    required bool theorie,
    required bool faehigkeiten,
  }) {
    if (faehigkeiten && s.gelernt > 0 && s.angelegt == 0) {
      return Bereich.faehigkeiten;
    }
    if (theorie && s.gelernt == 0 && s.angelegt == 0) return Bereich.theorie;
    if (kampf && !theorie && !s.hatGekaempft) return Bereich.kampf;
    return null;
  }
}

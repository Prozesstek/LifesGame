/// Die acht Bereiche der Startseite.
enum Bereich {
  gewohnheiten,
  kampf,
  theorie,
  faehigkeiten,
  laden,
  ausruestung,
  charakter,

  /// Die Statistik der Gewohnheiten (ADR-0087) — mit dem ersten Häkchen.
  statistik,
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
    this.stufenGeschafft = 0,
    this.seiten = 0,
    this.grundlagenGelesen = false,
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

  /// Die tiefste geschaffte Stufe der Grube, 0 heißt: noch keine.
  final int stufenGeschafft;

  /// Bestandene Seiten im Baum.
  final int seiten;

  /// Ob die fünf Seiten des früheren Handbuchs bestanden sind. Seit
  /// ADR-0070 sperrt das nichts mehr; es hält nur den Kreis der
  /// Fähigkeiten bei Ständen, die ihn darüber bekommen hatten.
  final bool grundlagenGelesen;

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

/// Die Schritte, durch die der Mentor einen neuen Spieler bringt
/// (ADR-0079), in ihrer Reihenfolge.
///
/// Der letzte — die erste Beute anlegen — steht nicht hier: Den ersten
/// Gegenstand legt das Spiel von selbst an, und der Mentor sagt seinen
/// Satz im Beute-Dialog des ersten Siegs (`showLoot`).
enum Schritt {
  /// Was willst du jeden Tag tun?
  gewohnheit,

  /// Das erste Häkchen.
  abhaken,

  /// Die erste Seite — sie bringt jedem Funkenstoß.
  ersteSeite,

  /// Die erste Fähigkeit auf einen Platz.
  faehigkeitAnlegen,

  /// Der erste Sieg in der Grube.
  grube,
}

/// Welche Bereiche die Startseite zeigt, welcher gerade dran ist, und
/// bei welchem Schritt der Mentor steht.
///
/// **Abgeleitet, nie gezählt** (ADR-0068). Es gibt keinen gespeicherten
/// Tutorial-Schritt: Ein Stand, der schon weiter ist, sieht sofort alles,
/// und ein eingefügter Stand braucht keine Übernahme.
///
/// Die Reihenfolge ist seit ADR-0079 die des Mentors: fragen, abhaken,
/// lesen, Fähigkeit anlegen, kämpfen. Bis dahin hieß sie „Kampf früh“
/// (ADR-0068): Die Grube kam mit dem ersten Häkchen, die Theorie erst
/// danach. Laden, Ausrüstung und Charakter kommen dazu, sobald es dort
/// etwas zu tun gibt.
class ErsterStart {
  const ErsterStart._(
    this.sichtbar,
    this.schritt,
    this.fragtNachGewohnheit,
    this.grubeErklaertSich,
    this.zeigtTagesgrube,
  );

  /// Alles offen, kein Schritt — für Tests anderer Bereiche und für jeden
  /// Stand, der durch ist.
  static const ErsterStart allesOffen = ErsterStart._(
    <Bereich>{
      Bereich.gewohnheiten,
      Bereich.kampf,
      Bereich.theorie,
      Bereich.faehigkeiten,
      Bereich.laden,
      Bereich.ausruestung,
      Bereich.charakter,
      Bereich.statistik,
    },
    null,
    false,
    false,
    true,
  );

  /// Ab so vielen Häkchen zeigt sich die Grube auch ohne gelesene Seite.
  ///
  /// **Niemand muss lesen, um zu kämpfen**, nur nicht gleich: Der Mentor
  /// will erst die Theorie zeigen (ADR-0079). Wer eine Woche lang
  /// abhakt und nichts liest, sähe die Grube sonst nie. Bis ADR-0079
  /// stand hier dieselbe Regel umgekehrt, die Theorie nach drei
  /// Häkchen.
  static const int haekchenFuerKampf = 7;

  /// Ab diesem Level zeigt sich der Charakter: Mit dem ersten Aufstieg
  /// gibt es dort zum ersten Mal etwas zu sehen.
  static const int levelFuerCharakter = 2;

  final Set<Bereich> sichtbar;

  /// Wo der Mentor steht — null, wenn der Weg gegangen ist.
  final Schritt? schritt;

  /// Ob „Heute“ statt einer Liste die erste Frage stellt.
  final bool fragtNachGewohnheit;

  /// Ob die Grube sich noch erklärt (ADR-0069): das Geister-Steuerkreuz,
  /// das Zeichen am Helden und nach einer Niederlage der Weg zur Theorie.
  ///
  /// **Bis die erste Stufe geschafft ist**, nicht nur im allerersten
  /// Lauf: Wer ihn verliert, hat die Hilfe im zweiten am nötigsten.
  final bool grubeErklaertSich;

  /// Ob im Eingang der Grube die Tagesgrube steht (ADR-0072).
  ///
  /// **Nach dem ersten Lauf, gewonnen oder verloren.** Sie hat einen
  /// Versuch am Tag; wer die Steuerung noch nie in der Hand hatte,
  /// verbrauchte ihn beim Ausprobieren.
  final bool zeigtTagesgrube;

  /// Der Kreis, der als Nächstes dran ist — höchstens einer. Es ist der
  /// Kreis des Schritts; bei der Gewohnheit und beim Häkchen ist das Ziel
  /// „Heute“ in der Mitte, kein Kreis.
  Bereich? get leuchtet => switch (schritt) {
    Schritt.ersteSeite => Bereich.theorie,
    Schritt.faehigkeitAnlegen => Bereich.faehigkeiten,
    Schritt.grube => Bereich.kampf,
    Schritt.gewohnheit || Schritt.abhaken || null => null,
  };

  bool zeigt(Bereich bereich) => sichtbar.contains(bereich);

  /// Ob alle acht Kreise stehen.
  bool get fertig => sichtbar.length == Bereich.values.length;

  /// Tagesaufgaben und Truhe kommen mit dem ersten Häkchen, wie die
  /// Theorie — vorher stünden dort drei Aufgaben, bevor es eine
  /// Gewohnheit gibt.
  bool get zeigtTagesaufgaben => zeigt(Bereich.theorie);

  static ErsterStart aus(ErsterStartStand s) {
    // **Ein Schritt ist erledigt, wenn er getan ist oder ein späterer,
    // der ihn braucht.** So bleibt die Reihe geschlossen, auch wenn ein
    // Stand einen übersprungen hat (Entwicklermodus, eingefügter Stand).
    // Das Häkchen folgt bewusst **nicht** aus der Seite: Wer zuerst
    // liest, steht noch auf Level 1, und der zweite Platz geht erst mit
    // dem Aufstieg auf, den das Häkchen bringt.
    final gewonnen = s.stufenGeschafft > 0;
    final angelegt = gewonnen || s.angelegt > 0;
    final gelesen = angelegt || s.seiten > 0;
    final abgehakt = gewonnen || s.haekchen > 0;
    final angefangen = abgehakt || gelesen || s.hatGewohnheit;

    final schritt = !angefangen
        ? Schritt.gewohnheit
        : !abgehakt
        ? Schritt.abhaken
        : !gelesen
        ? Schritt.ersteSeite
        : !angelegt
        ? Schritt.faehigkeitAnlegen
        : !gewonnen
        ? Schritt.grube
        : null;

    final faehigkeiten =
        gelesen || s.grundlagenGelesen || s.gelernt > 0 || s.angelegt > 0;
    final theorie = abgehakt || faehigkeiten;
    final kampf = angelegt || s.hatGekaempft || s.haekchen >= haekchenFuerKampf;

    final sichtbar = <Bereich>{
      Bereich.gewohnheiten,
      if (kampf) Bereich.kampf,
      if (theorie) Bereich.theorie,
      if (faehigkeiten) Bereich.faehigkeiten,
      if (s.jeBesessen > 0 || s.goldVerdient >= s.billigstesStueck)
        Bereich.laden,
      if (s.jeBesessen > 0) Bereich.ausruestung,
      if (s.level >= levelFuerCharakter) Bereich.charakter,
      // **Mit dem ersten Häkchen** (ADR-0087): Ab dann gibt es einen Tag
      // zu sehen. Nicht über `abgehakt` — ein Sieg ohne Häkchen hätte
      // nichts, was die Statistik zeigen könnte.
      if (s.haekchen > 0) Bereich.statistik,
    };

    return ErsterStart._(
      Set<Bereich>.unmodifiable(sichtbar),
      schritt,
      !s.hatGewohnheit && s.haekchen == 0,
      s.stufenGeschafft == 0,
      s.hatGekaempft,
    );
  }
}

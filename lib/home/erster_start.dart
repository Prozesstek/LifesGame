import 'package:progression/progression.dart';

/// Die acht Bereiche der Startseite.
enum Bereich {
  gewohnheiten,
  kampf,
  theorie,
  faehigkeiten,
  laden,
  ausruestung,
  charakter,

  /// Die Statistik der Gewohnheiten (ADR-0087) — mit dem ersten Häkchen,
  /// seit ADR-0098 frühestens auf Level 7.
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
    this.gewohnheitenJe = 0,
    this.hatTier = false,
    this.warAmFeuer = false,
    this.tagesgrubeVersucht = false,
    this.gewohnheitenGezeigt = false,
    this.talentpunktGezeigt = false,
    this.faehigkeitenGezeigt = false,
    this.gekauft = 0,
    this.etwasGesperrt = false,
    this.geschenkAngelegt = false,
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

  /// Wie viele verschiedene Gewohnheiten je liefen — laufend, pausiert
  /// oder abgehakt. Daran hängt der letzte Satz des Mentors
  /// ([Schritt.gebiete]).
  final int gewohnheitenJe;

  /// **Was ein Stand schon hat, behält er** (ADR-0098): ein gewähltes Ei,
  /// …
  final bool hatTier;

  /// … etwas, das je am Lagerfeuer geschah …
  final bool warAmFeuer;

  /// … und ein Versuch in der Tagesgrube. Ein Extra, das man schon
  /// benutzt hat, verschwindet nicht, nur weil das Level darunter liegt.
  final bool tagesgrubeVersucht;

  /// Ob der Hinweis auf die Gewohnheiten in dieser Sitzung weggetippt
  /// ist ([Schritt.gewohnheitenZeigen]). **Nicht gespeichert**: Wer vor
  /// der ersten Seite neu startet, hört ihn noch einmal — ein Tipp.
  final bool gewohnheitenGezeigt;

  /// … und ob der Talentpunkt erklärt ist ([Schritt.talentpunkt]).
  final bool talentpunktGezeigt;

  /// … und ob gezeigt ist, wo die Fähigkeiten liegen
  /// ([Schritt.faehigkeitenZeigen]).
  final bool faehigkeitenGezeigt;

  /// Wie viele Stücke je im Laden gekauft wurden (`Loadout.boughtCount`).
  final int gekauft;

  /// Ob gerade ein Stück gesperrt ist. **Kann fallen** — der Schritt
  /// [Schritt.sperren] gilt deshalb auch als erledigt, wenn ein späterer
  /// es ist.
  final bool etwasGesperrt;

  /// Ob das Geschenk des Mentors auf einem Platz liegt. Kann ebenfalls
  /// fallen; siehe [ErsterStart.rundgangVorbeiAb].
  final bool geschenkAngelegt;
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

  /// **Wo die Gewohnheiten wohnen** (06.11.2026): Nach dem ersten
  /// Häkchen zeigt der Mentor auf ihren Kreis; ein Tipp irgendwohin
  /// führt weiter. Der einzige Schritt, der nicht an einer Tat hängt.
  gewohnheitenZeigen,

  /// **Was ein Talentpunkt ist** (06.11.2026): Beim ersten Öffnen der
  /// Theorie steht er groß in der Mitte, der Mentor erklärt, ein Tipp
  /// schickt ihn an seinen Platz oben rechts. Auf der Startseite ist es
  /// derselbe Weg wie [ersteSeite].
  talentpunkt,

  /// Die erste Seite — sie bringt jedem Funkenstoß.
  ersteSeite,

  /// Die erste Fähigkeit auf einen Platz. **Seit dem 07.11.2026 legt das
  /// Spiel sie im Tutorial selbst an** (`showAbilityUnlocks`); der
  /// Schritt bleibt für Stände, die eine Fähigkeit haben, aber keine
  /// angelegt.
  faehigkeitAnlegen,

  /// **Wo die Fähigkeiten liegen** (07.11.2026): Ist die erste von selbst
  /// angelegt, zeigt der Mentor auf ihren Kreis; ein Tipp irgendwohin
  /// führt weiter — wie bei den Gewohnheiten.
  faehigkeitenZeigen,

  /// Der erste Sieg in der Grube.
  grube,

  /// **Die Gebiete, ganz am Ende** (Issue #183): Was ein Gebiet ist und
  /// dass es im Kampf stärkt, sagt der Mentor erst nach dem ersten Sieg —
  /// und er bleibt dabei, bis eine zweite Gewohnheit da ist. Der Sieg
  /// hat die Plätze dafür gebracht (ADR-0093).
  gebiete,

  /// **Der Rundgang** (Frederik, 07.11.2026): Laden, Ausrüstung,
  /// Fähigkeiten, je mit einer kleinen Aufgabe, dann ist das Tutorial
  /// vorbei. Reicht das Gold noch nicht für den Laden, wartet der Mentor
  /// hier.
  goldSammeln,

  /// Etwas im Laden kaufen — der Laden hält dafür ein Stück zum
  /// billigsten Preis bereit (`DailyShop.mitMentorAngebot`).
  laden,

  /// Ein Stück in der Ausrüstung sperren.
  sperren,

  /// Das Geschenk anlegen: Sammeln, von „Beim Händler“, statt Funkenstoß.
  geschenk,
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
    this.zeigtTagesaufgaben,
    this.zeigtHaustier,
    this.zeigtSammlung, [
    this.gesperrt = const <LevelExtra>{},
  ]);

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
    true,
    true,
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

  /// Ab wie vielen Gewohnheiten der Mentor die Gebiete erklärt hat.
  static const int gewohnheitenNachDenGebieten = 2;

  /// **Wer so viele Etagen geschafft hat, macht keinen Rundgang mehr.**
  /// Ein Stand, der weiter ist — auch die Stände von vor dem 07.11.2026 —,
  /// wird nicht zurück in den Laden geschickt, und wer Schloss oder
  /// Geschenk danach wieder löst, bekommt das Tutorial nicht zurück.
  static const int rundgangVorbeiAb = 2;

  final Set<Bereich> sichtbar;

  /// Wo der Mentor steht — null, wenn der Weg gegangen ist.
  final Schritt? schritt;

  /// Ob „Heute“ statt einer Liste die erste Frage stellt.
  final bool fragtNachGewohnheit;

  /// **Die ersten zwei Screens zeigen nur den Mentor und das, worum es
  /// geht** (06.11.2026): die erste Frage, dann das erste Häkchen. Leiste,
  /// Level, Gold, Ei und Feuer kommen erst danach.
  bool get nurMentor => fragtNachGewohnheit || schritt == Schritt.abhaken;

  /// **Bis zur ersten Seite nur, was man kennt** (06.11.2026): der Kreis
  /// der Gewohnheiten, „Heute“ und das neue Ziel, die Theorie. Level,
  /// Gold, Ei, Feuer und die gesperrte Statistik warten.
  bool get zeigtWenig =>
      nurMentor ||
      schritt == Schritt.gewohnheitenZeigen ||
      schritt == Schritt.talentpunkt ||
      schritt == Schritt.ersteSeite;

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
  /// verbrauchte ihn beim Ausprobieren. **Und frühestens auf Level 4**
  /// (ADR-0098, `LevelExtra.tagesdungeon`).
  final bool zeigtTagesgrube;

  /// Ob das Lagerfeuer brennt — Truhe, Dailies, „Morgen zuerst“
  /// (ADR-0076). Mit dem ersten Häkchen, wie die Theorie, **und
  /// frühestens auf Level 3** (ADR-0098). Der Name ist älter als das
  /// Feuer; an ihm hängen auch der Streifen der Dailies und die Frage
  /// nach dem geschafften Tag.
  final bool zeigtTagesaufgaben;

  /// Ob das Haustier da ist oder sein Ei gewählt werden kann (ADR-0086):
  /// erst, wenn es eine Gewohnheit gibt, **und frühestens auf Level 5**
  /// (ADR-0098) — außer das Ei ist schon gewählt.
  final bool zeigtHaustier;

  /// Ob der Weg in die Sammlung offen ist (ADR-0080) — **ab Level 10**
  /// (ADR-0098).
  final bool zeigtSammlung;

  /// **Was man schon sieht, aber noch nicht öffnen kann** (Frederik,
  /// 04.11.2026: „wenn man die Sachen schon sieht, aber sie halt mit so
  /// einem Schloss gesperrt sind“). Ein Extra steht hier, sobald seine
  /// übrige Bedingung erfüllt ist — die Statistik nach dem ersten Häkchen,
  /// das Ei, wenn es eine Gewohnheit gibt —, solange das Level fehlt.
  ///
  /// Die `zeigt…`-Felder bleiben, was **offen** ist; darauf hören auch der
  /// Streifen der Dailies und die Frage nach dem geschafften Tag.
  final Set<LevelExtra> gesperrt;

  /// Ob [extra] mit Schloss dasteht.
  bool istGesperrt(LevelExtra extra) => gesperrt.contains(extra);

  /// Ob [bereich] mit Schloss dasteht — heute nur die Statistik.
  bool bereichGesperrt(Bereich bereich) =>
      bereich == Bereich.statistik && istGesperrt(LevelExtra.statistik);

  /// Der Kreis, der als Nächstes dran ist — höchstens einer. Es ist der
  /// Kreis des Schritts; bei der Gewohnheit und beim Häkchen ist das Ziel
  /// „Heute“ in der Mitte, kein Kreis.
  Bereich? get leuchtet => switch (schritt) {
    Schritt.gewohnheitenZeigen => Bereich.gewohnheiten,
    Schritt.talentpunkt || Schritt.ersteSeite => Bereich.theorie,
    Schritt.faehigkeitAnlegen ||
    Schritt.faehigkeitenZeigen => Bereich.faehigkeiten,
    Schritt.grube => Bereich.kampf,
    Schritt.gebiete => Bereich.gewohnheiten,
    Schritt.laden => Bereich.laden,
    Schritt.sperren => Bereich.ausruestung,
    Schritt.geschenk => Bereich.faehigkeiten,
    Schritt.gewohnheit ||
    Schritt.abhaken ||
    Schritt.goldSammeln ||
    null => null,
  };

  bool zeigt(Bereich bereich) => sichtbar.contains(bereich);

  /// Ob alle acht Kreise stehen.
  bool get fertig => sichtbar.length == Bereich.values.length;

  /// Ob der Pflichtweg des Mentors gegangen ist: **der erste Sieg, sonst
  /// nichts**. Danach steht er höchstens noch bei [Schritt.gebiete], und
  /// der sperrt und schenkt nichts.
  ///
  /// Steht einzeln da, weil die Plätze für Gewohnheiten daran hängen
  /// (ADR-0093): `ersterStartProvider` liest den Tracker, und der Tracker
  /// darf sich nicht über eine Ecke selbst lesen (`gotchas.md`).
  static bool mentorFertig(int stufenGeschafft) => stufenGeschafft > 0;

  static ErsterStart aus(ErsterStartStand s) {
    // **Ein Schritt ist erledigt, wenn er getan ist oder ein späterer,
    // der ihn braucht.** So bleibt die Reihe geschlossen, auch wenn ein
    // Stand einen übersprungen hat (Entwicklermodus, eingefügter Stand).
    // Das Häkchen folgt bewusst **nicht** aus der Seite: Wer zuerst
    // liest, steht noch auf Level 1, und der zweite Platz geht erst mit
    // dem Aufstieg auf, den das Häkchen bringt.
    final gewonnen = mentorFertig(s.stufenGeschafft);
    final angelegt = gewonnen || s.angelegt > 0;
    final gelesen = angelegt || s.seiten > 0;
    final abgehakt = gewonnen || s.haekchen > 0;
    final angefangen = abgehakt || gelesen || s.hatGewohnheit;

    final schritt = !angefangen
        ? Schritt.gewohnheit
        : !abgehakt
        ? Schritt.abhaken
        : !gelesen
        ? (!s.gewohnheitenGezeigt
              ? Schritt.gewohnheitenZeigen
              : !s.talentpunktGezeigt
              ? Schritt.talentpunkt
              : Schritt.ersteSeite)
        : !angelegt
        ? Schritt.faehigkeitAnlegen
        : !gewonnen
        ? (!s.faehigkeitenGezeigt && !s.hatGekaempft
              ? Schritt.faehigkeitenZeigen
              : Schritt.grube)
        : s.gewohnheitenJe < gewohnheitenNachDenGebieten
        ? Schritt.gebiete
        : s.stufenGeschafft >= rundgangVorbeiAb
        ? null
        : s.gekauft == 0
        ? (s.goldVerdient >= s.billigstesStueck
              ? Schritt.laden
              : Schritt.goldSammeln)
        : !s.etwasGesperrt && !s.geschenkAngelegt
        ? Schritt.sperren
        : !s.geschenkAngelegt
        ? Schritt.geschenk
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
      // **Offen erst auf Level 7** (ADR-0098); darunter steht sie mit
      // Schloss da ([gesperrt]).
      // **Im Tutorial nur, was offen ist** (Frederik, 07.11.2026).
      if (s.haekchen > 0 &&
          (schritt == null || LevelExtra.statistik.offenAuf(s.level)))
        Bereich.statistik,
    };
    final fragt = !s.hatGewohnheit && s.haekchen == 0;

    // Je Extra: Ist seine übrige Bedingung erfüllt (es wäre zu sehen), und
    // ist es offen — über das Level oder weil der Stand es schon benutzt
    // hat?
    final extras = <LevelExtra, (bool, bool)>{
      LevelExtra.lagerfeuer: (
        // Tagesaufgaben und Truhe mit dem ersten Häkchen, wie die
        // Theorie — vorher stünden dort drei Aufgaben ohne Gewohnheit.
        // **Und erst nach dem Tutorial** (Frederik, 08.11.2026): Level 3
        // kommt mitten im Rundgang, und dort erklärt es niemand. Wer
        // schon am Feuer war, behält es.
        theorie && (schritt == null || s.warAmFeuer),
        LevelExtra.lagerfeuer.offenAuf(s.level) || s.warAmFeuer,
      ),
      LevelExtra.tagesdungeon: (
        s.hatGekaempft,
        LevelExtra.tagesdungeon.offenAuf(s.level) || s.tagesgrubeVersucht,
      ),
      LevelExtra.haustier: (
        !fragt || s.hatTier,
        LevelExtra.haustier.offenAuf(s.level) || s.hatTier,
      ),
      LevelExtra.statistik: (
        s.haekchen > 0,
        LevelExtra.statistik.offenAuf(s.level),
      ),
      LevelExtra.sammlung: (true, LevelExtra.sammlung.offenAuf(s.level)),
    };
    bool offen(LevelExtra e) => extras[e]!.$1 && extras[e]!.$2;

    return ErsterStart._(
      Set<Bereich>.unmodifiable(sichtbar),
      schritt,
      fragt,
      s.stufenGeschafft == 0,
      offen(LevelExtra.tagesdungeon),
      offen(LevelExtra.lagerfeuer),
      offen(LevelExtra.haustier),
      offen(LevelExtra.sammlung),
      // **Bis das Tutorial vorbei ist, kein Schloss** (Frederik,
      // 07.11.2026): Bis dahin steht nur da, was offen ist — Ei, Feuer,
      // Statistik und Sammlung mit Schloss kamen sonst mitten im Weg des
      // Mentors herein.
      schritt != null
          ? const <LevelExtra>{}
          : Set<LevelExtra>.unmodifiable(<LevelExtra>{
              for (final MapEntry(key: e, value: (zuSehen, auf))
                  in extras.entries)
                if (zuSehen && !auf) e,
            }),
    );
  }
}

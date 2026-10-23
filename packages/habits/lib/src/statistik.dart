import 'day.dart';
import 'tracker.dart';

/// **Die Statistik der Gewohnheiten** (ADR-0087) — reine Rechnung aus der
/// Historie, nie gespeichert.
///
/// Gezählt wird wie bei der Tageskette (ADR-0064): Ein Tag ist **fällig**,
/// wenn eine Gewohnheit nach dem Plan, der damals galt, dran war und es
/// sie schon gab ([HabitTracker.wasDueOn]). Die Quote ist erledigt durch
/// fällig. Ein Tag ohne Fälliges ist ein Ruhetag und zählt nicht; ein Tag
/// mit Streak-Eis steht als eigener Zustand da, zählt aber nicht als
/// erledigt.

/// Woche, Monat, Jahr — oder alles seit dem ersten Häkchen.
enum StatZeitraum { woche, monat, jahr, gesamt }

/// Worin ein Fenster für Balken und Kurve geteilt wird.
enum StatTeilung { tag, woche, monat }

/// Ein Zeitraum mit festem Anfang und Ende, beide eingeschlossen.
///
/// Woche heißt Montag bis Sonntag, Monat und Jahr sind Kalendermonat und
/// -jahr. Mit [davor] und [danach] wird geblättert.
class StatFenster {
  const StatFenster._(this.zeitraum, this.von, this.bis);

  /// Das Fenster von [zeitraum], in dem [tag] liegt. [anfang] ist der
  /// erste Tag mit Daten und nur für [StatZeitraum.gesamt] nötig, das von
  /// dort bis [heute] reicht.
  factory StatFenster.um(
    StatZeitraum zeitraum,
    Day tag, {
    required Day anfang,
    required Day heute,
  }) {
    switch (zeitraum) {
      case StatZeitraum.woche:
        final montag = tag.startOfWeek;
        return StatFenster._(zeitraum, montag, montag.plus(6));
      case StatZeitraum.monat:
        return StatFenster._(
          zeitraum,
          Day(tag.year, tag.month, 1),
          Day.from(DateTime.utc(tag.year, tag.month + 1, 0)),
        );
      case StatZeitraum.jahr:
        return StatFenster._(
          zeitraum,
          Day(tag.year, 1, 1),
          Day(tag.year, 12, 31),
        );
      case StatZeitraum.gesamt:
        return StatFenster._(zeitraum, anfang < heute ? anfang : heute, heute);
    }
  }

  final StatZeitraum zeitraum;
  final Day von;
  final Day bis;

  /// Wie viele Kalendertage das Fenster hat.
  int get laenge => von.daysUntil(bis) + 1;

  bool enthaelt(Day tag) => tag >= von && tag <= bis;

  /// Ob es ein Fenster davor und danach gibt — „Gesamt“ ist eins.
  bool get blaetterbar => zeitraum != StatZeitraum.gesamt;

  /// Das Fenster davor; bei „Gesamt“ dasselbe.
  StatFenster get davor {
    if (!blaetterbar) return this;
    return StatFenster.um(zeitraum, von.previous, anfang: von, heute: bis);
  }

  /// Das Fenster danach; bei „Gesamt“ dasselbe.
  StatFenster get danach {
    if (!blaetterbar) return this;
    return StatFenster.um(zeitraum, bis.next, anfang: von, heute: bis);
  }

  /// Jeder Tag des Fensters, von vorn.
  Iterable<Day> get tage sync* {
    for (var tag = von; tag <= bis; tag = tag.next) {
      yield tag;
    }
  }

  /// Worin die Balken geteilt werden: Woche und Monat je Tag, Jahr und
  /// Gesamt je Monat.
  StatTeilung get balkenTeilung => switch (zeitraum) {
        StatZeitraum.woche || StatZeitraum.monat => StatTeilung.tag,
        StatZeitraum.jahr || StatZeitraum.gesamt => StatTeilung.monat,
      };

  /// Worin die Kurve geteilt wird: Woche und Monat je Tag, das Jahr je
  /// Woche, Gesamt je Monat.
  StatTeilung get kurvenTeilung => switch (zeitraum) {
        StatZeitraum.woche || StatZeitraum.monat => StatTeilung.tag,
        StatZeitraum.jahr => StatTeilung.woche,
        StatZeitraum.gesamt => StatTeilung.monat,
      };

  @override
  bool operator ==(Object other) =>
      other is StatFenster &&
      other.zeitraum == zeitraum &&
      other.von == von &&
      other.bis == bis;

  @override
  int get hashCode => Object.hash(zeitraum, von, bis);
}

/// Erledigt von fällig.
class StatQuote {
  const StatQuote(this.erledigt, this.faellig);

  static const StatQuote leer = StatQuote(0, 0);

  final int erledigt;
  final int faellig;

  /// Zwischen 0 und 1, oder null, wenn nichts fällig war.
  double? get anteil => faellig == 0 ? null : erledigt / faellig;

  /// In ganzen Prozent, oder null.
  int? get prozent => anteil == null ? null : (anteil! * 100).round();

  /// Ob alles Fällige erledigt ist — und überhaupt etwas fällig war.
  bool get voll => faellig > 0 && erledigt == faellig;

  StatQuote operator +(StatQuote other) =>
      StatQuote(erledigt + other.erledigt, faellig + other.faellig);
}

/// Was ein Tag war.
class StatTag {
  const StatTag({
    required this.tag,
    required this.faellig,
    required this.erledigt,
    required this.haekchen,
    required this.eis,
    required this.zukunft,
    this.menge = 0,
  });

  final Day tag;

  /// Wie viele Gewohnheiten fällig waren.
  final int faellig;

  /// Wie viele davon erledigt sind.
  final int erledigt;

  /// Alle Häkchen des Tages — auch an Gewohnheiten, die nicht fällig
  /// waren.
  final int haekchen;

  /// Ein Streak-Eis deckt den Tag, und es war etwas offen.
  final bool eis;

  /// Liegt nach heute.
  final bool zukunft;

  /// Wie viel von einer Menge oder Zeit geschafft wurde — nur in der
  /// Statistik einer Gewohnheit mit Ziel, sonst 0.
  final int menge;

  StatQuote get quote => StatQuote(erledigt, faellig);

  /// Nichts fällig, und es ist schon gewesen.
  bool get ruhetag => !zukunft && faellig == 0;
}

/// Ein Stück eines Fensters — ein Tag, eine Woche oder ein Monat — für
/// Balken und Kurve.
class StatAbschnitt {
  const StatAbschnitt({
    required this.von,
    required this.bis,
    required this.quote,
    required this.haekchen,
    required this.menge,
    required this.kette,
    required this.zukunft,
  });

  final Day von;
  final Day bis;
  final StatQuote quote;
  final int haekchen;
  final int menge;

  /// Die Kette am Ende des Abschnitts — bei einer Gewohnheit ihre, sonst
  /// die Tageskette.
  final int kette;

  /// Beginnt nach heute.
  final bool zukunft;
}

/// Wie viel einer Gewohnheit mit Menge oder Zeit in einem Fenster
/// zusammenkam.
class StatMenge {
  const StatMenge({required this.summe, required this.tage});

  final int summe;

  /// Die fälligen Tage bis heute, durch die geteilt wird.
  final int tage;

  /// Im Schnitt je fälligem Tag, gerundet.
  int get schnitt => tage == 0 ? 0 : (summe / tage).round();
}

/// Bestwerte über die ganze Zeit.
class StatRekorde {
  const StatRekorde({
    required this.laengsteKette,
    required this.besterMonat,
    required this.perfekteWochen,
    required this.meisteHaekchen,
    required this.haekchenGesamt,
  });

  /// Bei einer Gewohnheit ihre längste Kette, sonst die längste
  /// Tageskette.
  final int laengsteKette;

  /// Der Monat (sein erster Tag) mit der besten Quote; nur Monate mit
  /// mindestens [StatRechnung.mindestFaellig] fälligen Tagen zählen.
  final ({Day monat, StatQuote quote})? besterMonat;

  /// Wochen von Montag bis Sonntag, in denen alles Fällige erledigt war.
  final int perfekteWochen;

  /// Der Tag mit den meisten Häkchen.
  final ({Day tag, int anzahl})? meisteHaekchen;

  final int haekchenGesamt;
}

/// Eine Gewohnheit im Jahresrückblick.
class StatJahrGewohnheit {
  const StatJahrGewohnheit({
    required this.habitId,
    required this.quote,
    required this.haekchen,
    required this.menge,
  });

  final String habitId;
  final StatQuote quote;
  final int haekchen;

  /// Summe der Menge oder Zeit, 0 ohne Ziel.
  final int menge;
}

/// **Der Jahresrückblick**: ein Kalenderjahr in Zahlen.
class StatJahr {
  const StatJahr({
    required this.jahr,
    required this.tage,
    required this.quote,
    required this.haekchen,
    required this.perfekteWochen,
    required this.laengsteKette,
    required this.besterMonat,
    required this.gewohnheiten,
    required this.vorjahr,
  });

  final int jahr;

  /// Jeder Tag des Jahres, für das Raster.
  final List<StatTag> tage;
  final StatQuote quote;
  final int haekchen;
  final int perfekteWochen;

  /// Die längste Tageskette, die in diesem Jahr erreicht wurde.
  final int laengsteKette;
  final ({Day monat, StatQuote quote})? besterMonat;

  /// Jede Gewohnheit mit Häkchen in diesem Jahr.
  final List<StatJahrGewohnheit> gewohnheiten;

  /// Häkchen und Quote des Vorjahres, wenn es dort Fälliges gab.
  final ({int haekchen, StatQuote quote})? vorjahr;

  /// Die Gewohnheit mit der besten Quote — nur solche mit mindestens
  /// [StatRechnung.mindestFaelligJahr] fälligen Tagen.
  StatJahrGewohnheit? get besteQuote {
    StatJahrGewohnheit? beste;
    for (final g in gewohnheiten) {
      if (g.quote.faellig < StatRechnung.mindestFaelligJahr) continue;
      if (beste == null || g.quote.anteil! > beste.quote.anteil!) beste = g;
    }
    return beste;
  }

  /// Die Gewohnheit mit den meisten Häkchen.
  StatJahrGewohnheit? get meisteHaekchen {
    StatJahrGewohnheit? meiste;
    for (final g in gewohnheiten) {
      if (g.haekchen == 0) continue;
      if (meiste == null || g.haekchen > meiste.haekchen) meiste = g;
    }
    return meiste;
  }
}

/// **Rechnet die Statistik** — für alle Gewohnheiten oder für eine
/// ([habitId]).
///
/// Ein Objekt je Ansicht; es merkt sich jeden Tag, den es einmal
/// gerechnet hat. [heute] trennt, was schon war, von dem, was noch kommt.
class StatRechnung {
  StatRechnung(this.tracker, {required this.heute, this.habitId})
      : _ids = habitId == null ? tracker.trackedIds : <String>{habitId},
        _erste = tracker.firstCheckDays,
        _mitMenge =
            habitId != null && tracker.definitionFor(habitId)?.goal != null;

  /// Wie viele fällige Tage ein Monat haben muss, um bester Monat zu sein
  /// — sonst gewänne der erste Tag mit 1 von 1.
  static const int mindestFaellig = 7;

  /// Wie viele fällige Tage eine Gewohnheit im Jahr braucht, um als die
  /// mit der besten Quote zu gelten.
  static const int mindestFaelligJahr = 14;

  /// **Wann der Jahresrückblick angekündigt wird**: vom 20. Dezember bis
  /// zum 7. Januar — für das Jahr, das gerade endet oder geendet hat.
  /// Sonst null; dann gibt es ihn nur über den Knopf in der Jahresansicht.
  static int? rueckblickJahr(Day heute) {
    if (heute.month == 12 && heute.day >= 20) return heute.year;
    if (heute.month == 1 && heute.day <= 7) return heute.year - 1;
    return null;
  }

  final HabitTracker tracker;
  final Day heute;
  final String? habitId;
  final Set<String> _ids;
  final Map<String, Day> _erste;
  final bool _mitMenge;
  final Map<Day, StatTag> _tage = <Day, StatTag>{};

  /// Der erste Tag mit Daten — das erste Häkchen dieser Ansicht, oder
  /// heute.
  Day get anfang {
    Day? erster;
    for (final id in _ids) {
      final tag = _erste[id];
      if (tag != null && (erster == null || tag < erster)) erster = tag;
    }
    return erster ?? heute;
  }

  /// Das Fenster von [zeitraum], in dem heute liegt.
  StatFenster fenster(StatZeitraum zeitraum) =>
      StatFenster.um(zeitraum, heute, anfang: anfang, heute: heute);

  /// Was [tag] war.
  StatTag tag(Day tag) => _tage.putIfAbsent(tag, () => _rechne(tag));

  StatTag _rechne(Day tag) {
    if (tag > heute) {
      return StatTag(
        tag: tag,
        faellig: 0,
        erledigt: 0,
        haekchen: 0,
        eis: false,
        zukunft: true,
      );
    }
    var faellig = 0;
    var erledigt = 0;
    var haekchen = 0;
    for (final id in _ids) {
      final abgehakt = tracker.isChecked(id, tag);
      if (abgehakt) haekchen++;
      if (tracker.wasDueOn(id, tag, firstCheck: _erste[id])) {
        faellig++;
        if (abgehakt) erledigt++;
      }
    }
    return StatTag(
      tag: tag,
      faellig: faellig,
      erledigt: erledigt,
      haekchen: haekchen,
      eis: tracker.isFrozen(tag) && erledigt < faellig,
      zukunft: false,
      menge: _mitMenge ? tracker.progressOn(habitId!, tag) : 0,
    );
  }

  /// Jeder Tag des Fensters.
  List<StatTag> tage(StatFenster fenster) => <StatTag>[
        for (final t in fenster.tage) tag(t),
      ];

  /// Die Quote im Fenster bis heute.
  StatQuote quote(StatFenster fenster) =>
      _quoteZwischen(fenster.von, fenster.bis);

  StatQuote _quoteZwischen(Day von, Day bis) {
    var summe = StatQuote.leer;
    for (var t = von; t <= bis && t <= heute; t = t.next) {
      summe += tag(t).quote;
    }
    return summe;
  }

  /// Häkchen im Fenster bis heute.
  int haekchen(StatFenster fenster) {
    var summe = 0;
    for (var t = fenster.von; t <= fenster.bis && t <= heute; t = t.next) {
      summe += tag(t).haekchen;
    }
    return summe;
  }

  /// **Der Vergleich mit der Zeit davor**, in Prozentpunkten.
  ///
  /// Solange das Fenster läuft, zählen **die gleichen Tage** davor: am
  /// Mittwoch Montag bis Mittwoch dieser Woche gegen Montag bis Mittwoch
  /// der letzten. Null, wenn eine Seite nichts Fälliges hatte, oder bei
  /// „Gesamt“.
  int? vergleich(StatFenster fenster) {
    if (!fenster.blaetterbar || fenster.von > heute) return null;
    final ende = fenster.bis < heute ? fenster.bis : heute;
    final vergangen = fenster.von.daysUntil(ende);
    final davor = fenster.davor;
    final davorEnde = davor.von.plus(vergangen);
    final jetzt = _quoteZwischen(fenster.von, ende);
    final damals = _quoteZwischen(
      davor.von,
      davorEnde < davor.bis ? davorEnde : davor.bis,
    );
    if (jetzt.prozent == null || damals.prozent == null) return null;
    return jetzt.prozent! - damals.prozent!;
  }

  /// Das Fenster in Abschnitte geteilt — je Tag, Woche oder Monat.
  /// Abschnitte nach heute stehen mit [StatAbschnitt.zukunft] dabei.
  List<StatAbschnitt> abschnitte(StatFenster fenster, StatTeilung teilung) {
    final abschnitte = <StatAbschnitt>[];
    var von = fenster.von;
    while (von <= fenster.bis) {
      var bis = switch (teilung) {
        StatTeilung.tag => von,
        StatTeilung.woche => von.startOfWeek.plus(6),
        StatTeilung.monat => Day.from(DateTime.utc(von.year, von.month + 1, 0)),
      };
      if (bis > fenster.bis) bis = fenster.bis;
      abschnitte.add(_abschnitt(von, bis));
      von = bis.next;
    }
    return abschnitte;
  }

  StatAbschnitt _abschnitt(Day von, Day bis) {
    var quote = StatQuote.leer;
    var haekchen = 0;
    var menge = 0;
    for (var t = von; t <= bis && t <= heute; t = t.next) {
      final stand = tag(t);
      quote += stand.quote;
      haekchen += stand.haekchen;
      menge += stand.menge;
    }
    final zukunft = von > heute;
    final ende = bis < heute ? bis : heute;
    return StatAbschnitt(
      von: von,
      bis: bis,
      quote: quote,
      haekchen: haekchen,
      menge: menge,
      kette: zukunft ? 0 : _ketteAm(ende),
      zukunft: zukunft,
    );
  }

  int _ketteAm(Day tag) {
    final id = habitId;
    return id == null
        ? tracker.dayStreakEndingAt(tag)
        : tracker.streakEndingAt(id, tag);
  }

  /// Die Quote je Wochentag im Fenster, Montag (1) bis Sonntag (7).
  Map<int, StatQuote> jeWochentag(StatFenster fenster) {
    final je = <int, StatQuote>{for (var w = 1; w <= 7; w++) w: StatQuote.leer};
    for (var t = fenster.von; t <= fenster.bis && t <= heute; t = t.next) {
      je[t.weekday] = je[t.weekday]! + tag(t).quote;
    }
    return je;
  }

  /// Der Wochentag mit der besten Quote im Fenster, oder null, wenn nichts
  /// fällig war. Bei Gleichstand der frühere.
  int? staerksterWochentag(StatFenster fenster) {
    int? bester;
    double? besteQuote;
    for (final eintrag in jeWochentag(fenster).entries) {
      final anteil = eintrag.value.anteil;
      if (anteil == null) continue;
      if (besteQuote == null || anteil > besteQuote) {
        bester = eintrag.key;
        besteQuote = anteil;
      }
    }
    return bester;
  }

  /// Wie viel Menge oder Zeit im Fenster zusammenkam — nur für eine
  /// Gewohnheit mit Ziel, sonst null.
  StatMenge? menge(StatFenster fenster) {
    if (!_mitMenge) return null;
    var summe = 0;
    var tage = 0;
    for (var t = fenster.von; t <= fenster.bis && t <= heute; t = t.next) {
      final stand = tag(t);
      summe += stand.menge;
      if (stand.faellig > 0) tage++;
    }
    return StatMenge(summe: summe, tage: tage);
  }

  /// Die Bestwerte über die ganze Zeit.
  StatRekorde rekorde() {
    final von = anfang;
    final id = habitId;
    return StatRekorde(
      laengsteKette:
          id == null ? tracker.longestDayStreak : tracker.longestStreakOf(id),
      besterMonat: _besterMonat(von, heute),
      perfekteWochen: _perfekteWochen(von, heute),
      meisteHaekchen: _meisteHaekchen(von, heute),
      haekchenGesamt: id == null ? tracker.totalChecks : tracker.checksFor(id),
    );
  }

  ({Day monat, StatQuote quote})? _besterMonat(Day von, Day bis) {
    ({Day monat, StatQuote quote})? bester;
    var monat = Day(von.year, von.month, 1);
    while (monat <= bis) {
      final ende = Day.from(DateTime.utc(monat.year, monat.month + 1, 0));
      final quote = _quoteZwischen(
        monat < von ? von : monat,
        ende < bis ? ende : bis,
      );
      if (quote.faellig >= mindestFaellig &&
          (bester == null || quote.anteil! > bester.quote.anteil!)) {
        bester = (monat: monat, quote: quote);
      }
      monat = ende.next;
    }
    return bester;
  }

  /// Wochen von Montag bis Sonntag, die ganz zwischen [von] und [bis]
  /// liegen und in denen alles Fällige erledigt war.
  int _perfekteWochen(Day von, Day bis) {
    var anzahl = 0;
    var montag = von.startOfWeek;
    while (montag.plus(6) <= bis) {
      if (_quoteZwischen(montag, montag.plus(6)).voll) anzahl++;
      montag = montag.plus(7);
    }
    return anzahl;
  }

  ({Day tag, int anzahl})? _meisteHaekchen(Day von, Day bis) {
    ({Day tag, int anzahl})? meiste;
    for (var t = von; t <= bis; t = t.next) {
      final n = tag(t).haekchen;
      if (n > 0 && (meiste == null || n > meiste.anzahl)) {
        meiste = (tag: t, anzahl: n);
      }
    }
    return meiste;
  }

  /// **Der Jahresrückblick** für [jahr] — nur in der Statistik aller
  /// Gewohnheiten.
  StatJahr jahresrueckblick(int jahr) {
    final von = Day(jahr, 1, 1);
    final bis = Day(jahr, 12, 31);
    final fenster = StatFenster.um(
      StatZeitraum.jahr,
      von,
      anfang: von,
      heute: heute,
    );

    var laengste = 0;
    for (var t = von; t <= bis && t <= heute; t = t.next) {
      if (tag(t).haekchen == 0) continue;
      final kette = tracker.dayStreakEndingAt(t);
      if (kette > laengste) laengste = kette;
    }

    final gewohnheiten = <StatJahrGewohnheit>[];
    for (final id in _ids) {
      final einzeln = StatRechnung(tracker, heute: heute, habitId: id);
      final haekchen = einzeln.haekchen(fenster);
      if (haekchen == 0) continue;
      gewohnheiten.add(
        StatJahrGewohnheit(
          habitId: id,
          quote: einzeln.quote(fenster),
          haekchen: haekchen,
          menge: einzeln.menge(fenster)?.summe ?? 0,
        ),
      );
    }

    final vorher = fenster.davor;
    final quoteVorher = quote(vorher);
    return StatJahr(
      jahr: jahr,
      tage: tage(fenster),
      quote: quote(fenster),
      haekchen: haekchen(fenster),
      perfekteWochen: _perfekteWochen(von, bis < heute ? bis : heute),
      laengsteKette: laengste,
      besterMonat: _besterMonat(von, bis < heute ? bis : heute),
      gewohnheiten: gewohnheiten,
      vorjahr: quoteVorher.faellig == 0
          ? null
          : (haekchen: haekchen(vorher), quote: quoteVorher),
    );
  }
}

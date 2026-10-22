/// Wohin ein Tipp nach einer Niederlage führt — je Bereich einer.
enum StaerkerWeg { faehigkeiten, ausruestung, baum, gewohnheiten, laden }

/// Ein Tipp nach einer Niederlage: ein kurzer Satz und der Bereich, in den
/// ein Tipp darauf führt (ADR-0083).
class StaerkerTipp {
  const StaerkerTipp(this.weg, this.satz);

  final StaerkerWeg weg;
  final String satz;

  @override
  bool operator ==(Object other) =>
      other is StaerkerTipp && other.weg == weg && other.satz == satz;

  @override
  int get hashCode => Object.hash(weg, satz);

  @override
  String toString() => 'StaerkerTipp($weg, $satz)';
}

/// Die Zahlen, aus denen die Tipps gewählt werden. Zusammengetragen in
/// `staerker_werden_provider.dart`, gerechnet wird hier.
class StaerkerStand {
  const StaerkerStand({
    this.leerePlaetze = 0,
    this.ungenutzteFaehigkeiten = 0,
    this.besseresImRucksack = 0,
    this.freiePunkte = 0,
    this.offeneHaekchen = 0,
    this.inForm = false,
    this.besseresImLaden = 0,
  });

  /// Offene Fähigkeitsplätze, auf denen nichts liegt.
  final int leerePlaetze;

  /// Freigeschaltete Fähigkeiten, die auf keinem Platz liegen.
  final int ungenutzteFaehigkeiten;

  /// Exemplare im Rucksack, die besser sind als das Getragene.
  final int besseresImRucksack;

  /// Freie Theoriepunkte.
  final int freiePunkte;

  /// Heute fällige Gewohnheiten, die noch nicht abgehakt sind.
  final int offeneHaekchen;

  /// Ob heute alles erledigt ist (ADR-0043).
  final bool inForm;

  /// Angebote im Laden, die bezahlbar und besser sind als das Getragene.
  final int besseresImLaden;
}

/// **Was nach einer Niederlage stärker macht** — drei Tipps aus dem
/// eigenen Stand (ADR-0083).
///
/// Erst das, was sofort und ohne Kosten hilft (ein leerer Platz, ein
/// besseres Stück im Rucksack), dann das, was etwas kostet (Punkte,
/// Häkchen, Gold). Reicht das nicht für drei, füllen allgemeine Wege
/// auf — **nie zwei Tipps in denselben Bereich**, sonst führten zwei
/// Knöpfe an dieselbe Stelle.
///
/// Reine Rechnung: erzeugt keine Zahl und ändert nichts.
abstract final class StaerkerWerden {
  /// Wie viele Tipps das Blatt zeigt.
  static const int anzahl = 3;

  static List<StaerkerTipp> tipps(StaerkerStand stand) {
    final gewaehlt = <StaerkerTipp>[];
    void nimm(StaerkerTipp tipp) {
      if (gewaehlt.length >= anzahl) return;
      if (gewaehlt.any((t) => t.weg == tipp.weg)) return;
      gewaehlt.add(tipp);
    }

    for (final tipp in _ausDemStand(stand)) {
      nimm(tipp);
    }
    for (final tipp in _allgemein) {
      nimm(tipp);
    }
    return List<StaerkerTipp>.unmodifiable(gewaehlt);
  }

  static Iterable<StaerkerTipp> _ausDemStand(StaerkerStand s) sync* {
    if (s.leerePlaetze > 0 && s.ungenutzteFaehigkeiten > 0) {
      yield StaerkerTipp(
        StaerkerWeg.faehigkeiten,
        s.leerePlaetze == 1
            ? 'Ein Fähigkeitsplatz ist leer.'
            : '${s.leerePlaetze} Fähigkeitsplätze sind leer.',
      );
    }
    if (s.besseresImRucksack > 0) {
      yield StaerkerTipp(
        StaerkerWeg.ausruestung,
        s.besseresImRucksack == 1
            ? 'Im Rucksack liegt ein besseres Stück.'
            : 'Im Rucksack liegen ${s.besseresImRucksack} bessere Stücke.',
      );
    }
    if (s.freiePunkte > 0) {
      yield StaerkerTipp(
        StaerkerWeg.baum,
        s.freiePunkte == 1
            ? 'Ein Theoriepunkt ist frei.'
            : '${s.freiePunkte} Theoriepunkte sind frei.',
      );
    }
    if (!s.inForm && s.offeneHaekchen > 0) {
      yield StaerkerTipp(
        StaerkerWeg.gewohnheiten,
        s.offeneHaekchen == 1
            ? 'Noch ein Häkchen bis In Form.'
            : 'Noch ${s.offeneHaekchen} Häkchen bis In Form.',
      );
    }
    if (s.besseresImLaden > 0) {
      yield const StaerkerTipp(
        StaerkerWeg.laden,
        'Im Laden ist etwas Besseres bezahlbar.',
      );
    }
  }

  /// Was immer stimmt, in dieser Reihenfolge.
  static const List<StaerkerTipp> _allgemein = <StaerkerTipp>[
    StaerkerTipp(
      StaerkerWeg.gewohnheiten,
      'Jedes Häkchen macht deine Werte größer.',
    ),
    StaerkerTipp(
      StaerkerWeg.baum,
      'Jede Seite bringt Erfahrung, jedes Level Kraft.',
    ),
    StaerkerTipp(StaerkerWeg.laden, 'Der Laden hat jeden Tag Neues.'),
  ];
}

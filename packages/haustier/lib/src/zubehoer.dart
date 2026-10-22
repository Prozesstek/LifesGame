import 'wachstum.dart';

/// Wo ein Stück Zubehör sitzt. Je Platz trägt das Tier eins.
enum ZubehoerPlatz {
  kopf('Kopf'),
  hals('Hals'),
  spielzeug('Spielzeug');

  const ZubehoerPlatz(this.label);

  final String label;
}

/// Ein Stück Zubehör: gekauft für Gold oder an einer Stufe verdient.
///
/// **Gold für das Tier statt für Waffen** ist der Punkt (Frederik,
/// 22.10.2026): Nicht jeder will sich über den Kampf messen, und wer nicht
/// kämpft, soll sein Gold trotzdem für etwas ausgeben können, das zeigt,
/// was er getan hat. Die verdienten Stücke gibt es nur an Stufen — sie
/// lassen sich nicht kaufen.
class Zubehoer {
  const Zubehoer({
    required this.id,
    required this.name,
    required this.platz,
    this.preis,
    this.abStufe,
  }) : assert(
          (preis == null) != (abStufe == null),
          'gekauft oder verdient, nie beides',
        );

  final String id;
  final String name;
  final ZubehoerPlatz platz;

  /// Was es im Laden kostet — null, wenn es verdient wird.
  final int? preis;

  /// Ab welcher Stufe es da ist — null, wenn es gekauft wird.
  final HaustierStufe? abStufe;

  bool get istVerdient => abStufe != null;
}

/// Alles Zubehör an einem Ort. Gleiche Regel wie bei den Preisen der
/// Ausrüstung: Steht eine dieser Zahlen woanders, ist das ein Bug.
///
/// **Die Preise liegen zwischen einem und fünf Tagen Gold** — der Laden
/// der Ausrüstung ist auf 25 Gold am Tag ausgelegt (`packages/gear`). Ein
/// Hut soll eine Entscheidung gegen ein Schwert sein, kein Monatslohn.
abstract final class ZubehoerKatalog {
  static const List<Zubehoer> alle = <Zubehoer>[
    // --- Kopf ---
    Zubehoer(
      id: 'schleife',
      name: 'Schleife',
      platz: ZubehoerPlatz.kopf,
      abStufe: HaustierStufe.jung,
    ),
    Zubehoer(
      id: 'strohhut',
      name: 'Strohhut',
      platz: ZubehoerPlatz.kopf,
      preis: 40,
    ),
    Zubehoer(
      id: 'zauberhut',
      name: 'Zauberhut',
      platz: ZubehoerPlatz.kopf,
      preis: 120,
    ),
    Zubehoer(
      id: 'krone',
      name: 'Krone',
      platz: ZubehoerPlatz.kopf,
      abStufe: HaustierStufe.praechtig,
    ),

    // --- Hals ---
    Zubehoer(
      id: 'halstuch',
      name: 'Halstuch',
      platz: ZubehoerPlatz.hals,
      preis: 30,
    ),
    Zubehoer(
      id: 'glocke',
      name: 'Glöckchen',
      platz: ZubehoerPlatz.hals,
      preis: 60,
    ),
    Zubehoer(
      id: 'umhang',
      name: 'Umhang',
      platz: ZubehoerPlatz.hals,
      abStufe: HaustierStufe.ausgewachsen,
    ),

    // --- Spielzeug ---
    Zubehoer(
      id: 'ball',
      name: 'Ball',
      platz: ZubehoerPlatz.spielzeug,
      preis: 25,
    ),
    Zubehoer(
      id: 'kissen',
      name: 'Kissen',
      platz: ZubehoerPlatz.spielzeug,
      preis: 50,
    ),
    Zubehoer(
      id: 'kristall',
      name: 'Kristall',
      platz: ZubehoerPlatz.spielzeug,
      abStufe: HaustierStufe.uralt,
    ),
  ];

  static Zubehoer? byId(String? id) {
    for (final z in alle) {
      if (z.id == id) return z;
    }
    return null;
  }

  static List<Zubehoer> fuer(ZubehoerPlatz platz) {
    return List<Zubehoer>.unmodifiable(alle.where((z) => z.platz == platz));
  }
}

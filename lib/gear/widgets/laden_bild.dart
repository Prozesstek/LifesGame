import 'dart:ui';

/// **Wo im Ladenbild was liegt** (AktivesBrett, 21.11.2026) — eine
/// Stelle für alle Rechtecke, in Bildpunkten des Bildes.
///
/// Das Bild (`assets/UI/Laden.jpg`, 494 × 648) zeigt oben links die Tafel,
/// rechts den Händler und darunter den Tresen mit sechs Fächern. Tafel
/// und Fächer sind leer gemalt; was darauf steht, legt die App darüber.
/// Wer das Bild austauscht, misst die Rechtecke hier neu.
abstract final class LadenBild {
  static const String pfad = 'assets/UI/Laden.jpg';

  static const double breite = 494;
  static const double hoehe = 648;

  /// Das dunkle Innere der Tafel.
  static const Rect tafel = Rect.fromLTRB(12, 21, 238, 139);

  /// Die sechs Fächer, Zeile für Zeile von links.
  static final List<LadenFachBild> faecher = <LadenFachBild>[
    LadenFachBild.bei(12, 164, 216),
    LadenFachBild.bei(182, 336, 216),
    LadenFachBild.bei(355, 491, 216),
    LadenFachBild.bei(12, 164, 416),
    LadenFachBild.bei(182, 336, 416),
    LadenFachBild.bei(355, 491, 416),
  ];

  /// Die Farbe des Tresens am unteren Bildrand — der Grund darunter.
  static const Color tresen = Color(0xFF6A4530);
}

/// Ein Fach: der Holzrahmen, darin das dunkle Innere fürs Bild und den
/// Namen, darunter die Planke für den Preis.
class LadenFachBild {
  const LadenFachBild({
    required this.rahmen,
    required this.innen,
    required this.planke,
  });

  /// Aus dem Rahmen gemessen: Alle sechs Fächer sind gleich gebaut.
  LadenFachBild.bei(double links, double rechts, double oben)
    : rahmen = Rect.fromLTRB(links, oben, rechts, oben + 184),
      innen = Rect.fromLTRB(links + 10, oben + 10, rechts - 12, oben + 131),
      planke = Rect.fromLTRB(links + 10, oben + 134, rechts - 12, oben + 174);

  final Rect rahmen;
  final Rect innen;
  final Rect planke;
}

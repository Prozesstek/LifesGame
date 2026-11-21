import 'dart:ui';

/// **Wo im Ladenbild was liegt** (AktivesBrett, 21.11.2026) — eine
/// Stelle für alle Rechtecke, in Bildpunkten des Bildes.
///
/// Das Bild (`assets/UI/Laden.jpg`, 432 × 530) beginnt ganz oben am
/// Bildschirm: zuerst die Dachbalken, in denen das Schild „Laden“ hängt,
/// darunter links die Tafel, rechts der Händler, unten sein Tresen mit
/// sechs Fächern. Tafel und Fächer sind leer gemalt; was darauf steht,
/// legt die App darüber.
/// Wer das Bild austauscht, misst die Rechtecke hier neu.
abstract final class LadenBild {
  static const String pfad = 'assets/UI/Laden.jpg';

  static const double breite = 432;
  static const double hoehe = 530;

  /// Das dunkle Innere der Tafel.
  static const Rect tafel = Rect.fromLTRB(16, 103, 202, 266);

  /// Die sechs Fächer, Zeile für Zeile von links.
  static final List<LadenFachBild> faecher = <LadenFachBild>[
    LadenFachBild.bei(18, 142, 316),
    LadenFachBild.bei(158, 282, 316),
    LadenFachBild.bei(298, 412, 316),
    LadenFachBild.bei(18, 142, 422),
    LadenFachBild.bei(158, 282, 422),
    LadenFachBild.bei(298, 412, 422),
  ];

  /// Die Farbe des Tresens am unteren Bildrand — der Grund darunter.
  static const Color tresen = Color(0xFF6A4426);
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
    : rahmen = Rect.fromLTRB(links, oben, rechts, oben + 100),
      innen = Rect.fromLTRB(links + 8, oben + 7, rechts - 8, oben + 74),
      planke = Rect.fromLTRB(links + 8, oben + 76, rechts - 8, oben + 90);

  final Rect rahmen;
  final Rect innen;
  final Rect planke;
}

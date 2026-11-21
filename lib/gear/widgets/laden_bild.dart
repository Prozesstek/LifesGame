import 'dart:ui';

/// **Wo im Ladenbild was liegt** (AktivesBrett, 21.11.2026) — eine
/// Stelle für Bild, Tafel und Fächer.
///
/// Das Bild (`assets/UI/Laden.jpg`, 432 × 312) beginnt ganz oben am
/// Bildschirm: zuerst die Dachbalken, in denen das Schild „Laden“ hängt,
/// darunter links die Tafel, rechts der Händler, unten die Kante seines
/// Tresens. Die Tafel ist leer gemalt; was darauf steht, legt die App
/// darüber. Wer das Bild austauscht, misst hier neu.
///
/// **Die Fächer sind nicht im Bild** (AktivesBrett, 21.11.2026: „die Items
/// sind nicht symmetrisch“): Im gemalten Tresen war die rechte Spalte
/// schmaler. Jetzt ist es **ein** Fach, aus dem Bild geschnitten
/// (`Laden_Fach.png`), sechsmal gleich groß gelegt — gedehnt wird nur sein
/// dunkles Inneres ([fachMitte]), Holzrand und Planke bleiben, wie sie sind.
abstract final class LadenBild {
  static const String pfad = 'assets/UI/Laden.jpg';

  static const double breite = 432;
  static const double hoehe = 312;

  /// Das dunkle Innere der Tafel.
  static const Rect tafel = Rect.fromLTRB(16, 103, 202, 266);

  /// Ein leeres Fach: Holzrand, dunkles Inneres, unten die Planke.
  static const String fach = 'assets/UI/Laden_Fach.png';

  /// Was beim Dehnen eines Fachs mitwächst — das dunkle Innere. Alles
  /// außen herum (Rand, Planke) bleibt so groß wie im Bild.
  static const Rect fachMitte = Rect.fromLTRB(10, 9, 114, 72);

  /// Wie weit das dunkle Innere vom Rand des Fachs absteht, und wie hoch
  /// die Planke unten ist — in Bildpunkten, im Fach gleich Punkten.
  static const double fachRand = 8;
  static const double fachOben = 7;
  static const double plankeOben = 24;
  static const double plankeUnten = 10;

  /// Die Pfosten links und rechts am Tresen.
  static const String pfostenLinks = 'assets/UI/Laden_Pfosten_links.png';
  static const String pfostenRechts = 'assets/UI/Laden_Pfosten_rechts.png';
  static const double pfostenBreite = 12;

  /// Die Rückwand des Tresens, zwischen den Fächern.
  static const Color tresen = Color(0xFF3E2918);
}

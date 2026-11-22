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
/// schmaler. Die App legt sechs gleich große Fächer darunter, jedes im
/// Holzrahmen der App (`LadenFach`, 22.11.2026).
abstract final class LadenBild {
  static const String pfad = 'assets/UI/Laden.jpg';

  static const double breite = 432;
  static const double hoehe = 608;

  /// Wo der Inhalt der Tafel steht — ihr dunkles Inneres, oben so weit
  /// frei, dass das Schild „Laden“ nichts verdeckt.
  static const Rect tafel = Rect.fromLTRB(22, 104, 232, 366);

  /// Ab hier ist das Bild Tresen: das dunkle Innere unter der Platte.
  static const double tresenOben = 417;

  /// Die Pfosten links und rechts am Tresen.
  static const String pfostenLinks = 'assets/UI/Laden_Pfosten_links.png';
  static const String pfostenRechts = 'assets/UI/Laden_Pfosten_rechts.png';
  static const double pfostenBreite = 12;

  /// Das dunkle Innere des Tresens, zwischen den Fächern — aus dem Bild.
  static const Color tresen = Color(0xFF331D0F);
}

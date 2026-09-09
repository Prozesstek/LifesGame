import 'package:flutter/material.dart';

/// Die Farben der App an einem Ort.
///
/// Steht ein Farbwert direkt im Widget-Code, gehört er hierher.
///
/// **Zwei Farben sind gemessen und nicht gewählt:** [surface] und [text]
/// stehen so in `assets/UI/ButtonBG.png`. Der gezeichnete Knopf gibt
/// damit den Ton für die ganze App vor, statt als Fremdkörper darauf zu
/// liegen — er war der Anlass für diese Palette.
///
/// **Es gibt zwei Untergründe, und jede Bedeutung hat für beide einen
/// Wert.** Die Bildschirme legen Pergamentflächen auf dunkles Leder; die
/// Kampfarena dagegen ist selbst dunkel, weil zwei helle Figuren darauf
/// stehen. Eine Farbe für beides gibt es nicht — was auf Pergament
/// lesbar ist, verschwindet auf Leder und umgekehrt.
///
/// | Untergrund | Fläche | Schrift | Bedeutungen |
/// |---|---|---|---|
/// | Pergament | [surface] | [text], [textDim], [muted] | [accent], [enemy], [success], [gold] |
/// | Leder / Arena | [background] | [textOnDark], [textOnDarkDim] | die `…OnDark`-Werte |
abstract final class Palette {
  // ---------------------------------------------------------------
  // Der Grund, auf dem alles liegt
  // ---------------------------------------------------------------

  /// Dunkles Leder. Es ist nur zwischen den Flächen zu sehen — und in der
  /// Kampfarena, wo es die ganze Fläche trägt.
  static const Color background = Color(0xFF17110A);

  /// Eine Spur heller als [background], für abgesetzte dunkle Flächen
  /// (Kampf-HUD, Rahmen im Browser).
  static const Color backgroundRaised = Color(0xFF241A0E);

  // ---------------------------------------------------------------
  // Die Flächen: Pergament
  // ---------------------------------------------------------------

  /// Pergament. **Abgelesen aus `ButtonBG.png`** — jede Karte, jedes
  /// Blatt und jede Kachel steht darauf.
  static const Color surface = Color(0xFFE8C48C);

  /// Ein Ton tiefer: Ränder, Trennlinien, nicht gewählte Reiter.
  static const Color surfaceRaised = Color(0xFFD9B072);

  /// Noch ein Ton tiefer: der leere Teil eines Balkens, eine Mulde.
  ///
  /// Ein Fortschrittsbalken braucht drei Werte — Fläche, Mulde, Füllung —
  /// und auf hellem Grund reichen zwei nicht mehr aus.
  static const Color surfaceSunken = Color(0xFFC69A5C);

  // ---------------------------------------------------------------
  // Schrift auf Pergament
  // ---------------------------------------------------------------

  /// Tinte. **Abgelesen aus `ButtonBG.png`** (dort der Rand).
  static const Color text = Color(0xFF372200);

  /// Nebensätze, Einheiten, Herkunftsangaben.
  static const Color textDim = Color(0xFF5E4A2C);

  /// Was gerade nicht gilt: gesperrt, leer, nicht gekauft.
  static const Color muted = Color(0xFF9A8460);

  // ---------------------------------------------------------------
  // Schrift auf Leder
  // ---------------------------------------------------------------

  /// Warmes Off-White. Steht direkt auf [background] — die Namen unter
  /// den Bereichskreisen, die Zahlen im Kampf.
  ///
  /// **Kein reines Weiß.** Auf einem warmen Braun wirkt reines Weiß
  /// blaustichig; die App hatte es an dreiundvierzig Stellen und sah
  /// dadurch kühler aus, als sie gemeint war.
  static const Color textOnDark = Color(0xFFEFDCB8);

  /// Das Gegenstück zu [textDim] auf dunklem Grund.
  static const Color textOnDarkDim = Color(0xFFB09B77);

  // ---------------------------------------------------------------
  // Bedeutungen auf Pergament
  // ---------------------------------------------------------------

  /// Was offen, gewählt oder der Weg nach vorn ist. Gebranntes Leder.
  static const Color accent = Color(0xFF7A3D14);

  /// Der Gegner, ein Verlust, eine Warnung.
  static const Color enemy = Color(0xFF9E2B20);

  /// Geschafft, getragen, bestanden.
  static const Color success = Color(0xFF33591F);

  /// Gold als Zahl. Nicht die Farbe der gezeichneten Münze — die bringt
  /// ihre eigene mit.
  static const Color gold = Color(0xFF6A4C06);

  // ---------------------------------------------------------------
  // Dieselben Bedeutungen auf Leder
  // ---------------------------------------------------------------

  static const Color accentOnDark = Color(0xFFD98E4A);
  static const Color enemyOnDark = Color(0xFFE0684F);
  static const Color successOnDark = Color(0xFF7FBE6A);
  static const Color goldOnDark = Color(0xFFE0B65B);

  // ---------------------------------------------------------------
  // Die Arena
  // ---------------------------------------------------------------

  /// Die leere Hälfte eines Balkens auf dunklem Grund.
  ///
  /// Auf Pergament tut das [surfaceSunken]; hier braucht es das
  /// Gegenstück, weil die Statusleisten im Kampf auf Leder stehen.
  static const Color trackOnDark = Color(0xFF2E2314);

  /// Eine kleine Marke auf dunklem Grund — Statuseffekte, Restrunden.
  static const Color chipOnDark = Color(0xFF3A2C1B);

  /// Das Zeitfenster, in dem ein Treffer *ordentlich* ist.
  static const Color timingGood = Color(0xFF6B7A3A);

  /// Das Zeitfenster, in dem er *perfekt* ist.
  ///
  /// Oliv → Grün ist eine Steigerung, die man ohne Legende liest. Vorher
  /// standen dort Blau und Grün: zwei Farben ohne Reihenfolge, und beide
  /// aus einer Palette, die es nicht mehr gibt.
  static const Color timingPerfect = Color(0xFF5FA86B);
}

import '../ui/pixel_art.dart';

/// Welches Bild zu einem Zug gehört — und wie groß seine Kachel wird.
///
/// **Reine Darstellung.** Was ein Zug tut, steht in `package:combat`; hier
/// steht nur, wie er aussieht — dieselbe Trennung wie bei
/// `MoveAnimation` und `moveHelpFor`.
///
/// **Acht von fünfzehn Fähigkeiten haben eins** — die Commons und
/// Uncommons aus `docs/vorlagen/faehigkeiten.md`, Nummer 1 bis 8. Die
/// übrigen und alle Waffenzüge tragen weiter ihren Namen auf der Kachel,
/// genau so, wie es die Waffenzüge von Anfang an getan haben.
///
/// **Ein Bild kommt in zwei Schritten dazu:**
///
/// 1. Datei nach `assets/Faehigkeiten/` legen, auf 64 × 64 gezeichnet und
///    als [assetSize] Pixel abgelegt.
/// 2. Eine Zeile in [_dateien] ergänzen.
///
/// `test/move_icon_test.dart` prüft danach von selbst mit, dass die Id in
/// `package:combat` existiert und die Datei wirklich geladen werden kann.
///
/// **Hier steht ein Pfad und kein Dateiname**, wie bei `GearIcons`. Bis
/// zum 10.09. musste die Datei heißen wie die Move-Id — aber gezeichnet
/// wird „Funkenstoß", nicht `funkenstoss`, und die ersten vier Zeichnungen
/// kamen als „Untitled" an. Die Zuordnung steht deshalb in dieser Tabelle
/// und nicht im Dateinamen.
abstract final class MoveIcons {
  /// Move-Id → Pfad der Zeichnung.
  static const Map<String, String> _dateien = <String, String>{
    // Common
    'funkenstoss': 'assets/Faehigkeiten/Funkenstoss.png',
    'steinhaut': 'assets/Faehigkeiten/Steinhaut.png',
    'wurzelgriff': 'assets/Faehigkeiten/Wurzelgriff.png',
    'aurastrom': 'assets/Faehigkeiten/Aurastrom.png',

    // Uncommon
    'bluetentau': 'assets/Faehigkeiten/Bluetentau.png',
    'klingenwirbel': 'assets/Faehigkeiten/Klingenwirbel.png',
    'frostnebel': 'assets/Faehigkeiten/Frostnebel.png',
    'prisma_barriere': 'assets/Faehigkeiten/PrismaBarriere.png',
  };

  /// Der Pfad zum Bild, oder `null` wenn es für diesen Zug keins gibt.
  static String? forMoveId(String moveId) => _dateien[moveId];

  /// Alle Move-Ids, für die es ein Bild gibt.
  static Iterable<String> get moveIds => _dateien.keys;

  /// Abstand zwischen zwei Kacheln.
  static const double gap = 10;

  /// Obergrenze für die Kantenlänge einer Kachel.
  ///
  /// **Sie bestimmt zugleich, wie viel Platz die Arena bekommt.** Die
  /// Kachel ist quadratisch, ihre Breite ist also auch ihre Höhe — und was
  /// sie nicht braucht, bleibt den beiden Kämpfern. Bei 88 passen alle
  /// vier Züge in **eine** Reihe; die zweite Reihe entfällt, und das sind
  /// rund 190 Pixel, die das Kampffeld zurückbekommt.
  static const double maxTileSide = 88;

  /// Wie breit jede von [count] Kacheln in einer [rowWidth] Pixel breiten
  /// Reihe wird.
  ///
  /// Quadratisch, damit das **ganze** Bild zu sehen ist: Die Vorlagen sind
  /// quadratisch, und eine breitere als hohe Kachel schnitte sie oben und
  /// unten an.
  ///
  /// Alle Züge stehen in einer Reihe. Passt es nicht, werden die Kacheln
  /// schmaler statt umzubrechen — eine zweite Reihe kostet mehr Höhe, als
  /// vier kleinere Kacheln an Lesbarkeit einbringen.
  static double tileSideFor(double rowWidth, int count) {
    if (count <= 0) return 0;

    final proSpalte = (rowWidth - gap * (count - 1)) / count;
    return proSpalte.clamp(40.0, maxTileSide);
  }

  /// Höhe der Namenszeile über einer Bildkachel.
  ///
  /// Sie wird auch bei Kacheln **ohne** Bild freigehalten, damit die
  /// Bildflächen einer Reihe auf gleicher Höhe liegen.
  static const double labelHeight = 17;

  /// Die Auflösung der abgelegten Bilder.
  ///
  /// **Gezeichnet wird auf 64 × 64, abgelegt wird auf 256 × 256** — also
  /// jeder Bildpunkt der Zeichnung als 4 × 4 Block. Beides zusammen ist
  /// die Vorgabe fuer das ganze Projekt (`GearIcons`, `EnemyIcons`).
  ///
  /// **Warum 256 und nicht mehr.** Die Kachel ist hoechstens 88 Punkte
  /// breit, auf einem Handy mit dreifacher Pixeldichte also 264 echte
  /// Pixel. Ein 256er Bild wird dorthin um 1,03 vergroessert — praktisch
  /// eins zu eins. Ein groesseres Bild muesste **verkleinert** werden,
  /// und das ist bei Pixelgrafik der schlimmere Fall: Mit
  /// `FilterQuality.none` fallen dabei einzelne Bildpunkte einfach weg.
  static const int artSize = PixelArt.artSize;
  static const int assetSize = PixelArt.assetSize;
}

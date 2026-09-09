import '../ui/pixel_art.dart';

/// Welches Bild zu einem Zug gehört — und wie groß seine Kachel wird.
///
/// **Reine Darstellung.** Was ein Zug tut, steht in `package:combat`; hier
/// steht nur, wie er aussieht — dieselbe Trennung wie bei
/// `MoveAnimation` und `moveHelpFor`.
///
/// **Derzeit hat kein Zug ein Bild.** Die vier Umgebungen hatten eines und
/// sind am 27.08. wieder herausgenommen worden; das Kachelformat ist
/// geblieben. Ohne Bild trägt die Kachel ihren Namen — genau so, wie es
/// die Waffenzüge von Anfang an getan haben.
///
/// **Ein Bild kommt in drei Schritten zurück:**
///
/// 1. Datei nach `assets/abilities/` legen, benannt wie die Move-Id, in
///    [assetSize] Pixel Kantenlänge.
/// 2. In `pubspec.yaml` den Ordner unter `assets:` eintragen — dort steht
///    die Zeile auskommentiert bereit.
/// 3. Eine Zeile in [_dateien] ergänzen.
///
/// `test/move_icon_test.dart` prüft danach von selbst mit, dass die Id in
/// `package:combat` existiert und die Datei wirklich geladen werden kann.
abstract final class MoveIcons {
  static const String _ordner = 'assets/abilities';

  /// Move-Id → Dateiname. Leer, solange es keine Bilder gibt.
  ///
  /// **Die Datei heißt wie die Id.** Damit kann die Zuordnung nicht
  /// auseinanderlaufen.
  static const Map<String, String> _dateien = <String, String>{};

  /// Der Pfad zum Bild, oder `null` wenn es für diesen Zug keins gibt.
  static String? forMoveId(String moveId) {
    final datei = _dateien[moveId];
    return datei == null ? null : '$_ordner/$datei';
  }

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

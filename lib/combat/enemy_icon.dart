import '../ui/pixel_art.dart';

/// Welches Bild zu einem Gegner gehört.
///
/// **Reine Darstellung**, wie `MoveIcons` und `GearIcons` — was ein
/// Gegner *kann*, steht in `package:combat`.
///
/// **Derzeit hat kein Gegner ein Bild.** Issue #35 führt „Gegner" unter
/// den Designs auf, die noch entstehen müssen, und Issue #36 verlangt
/// ausdrücklich nur ein Platzhalterbild. Bis dahin steht auf der Fläche
/// ein Zeichen und der Name.
///
/// **Ein Bild kommt in zwei Schritten dazu:**
///
/// 1. Datei nach `assets/enemies/` legen, benannt wie die Gegner-Id, in
///    [assetSize] Pixel Kantenlänge. Den Ordner in `pubspec.yaml`
///    eintragen — `assets/character/` steht dort als Vorbild.
/// 2. Eine Zeile in [_dateien] ergänzen.
///
/// `test/enemy_icon_test.dart` prüft danach von selbst mit, dass die Id
/// in der Reihe existiert und die Datei wirklich geladen werden kann.
abstract final class EnemyIcons {
  static const String _ordner = 'assets/enemies';

  /// Gegner-Id → Dateiname. Leer, solange es keine Bilder gibt.
  static const Map<String, String> _dateien = <String, String>{};

  /// Der Pfad zum Bild, oder `null` wenn es für diesen Gegner keins gibt.
  static String? forEnemyId(String enemyId) {
    final datei = _dateien[enemyId];
    return datei == null ? null : '$_ordner/$datei';
  }

  /// Alle Gegner-Ids, für die es ein Bild gibt.
  static Iterable<String> get enemyIds => _dateien.keys;

  /// **Gezeichnet auf 64 × 64, abgelegt als 256 × 256** — dieselbe
  /// Vorgabe wie bei [MoveIcons] und [GearIcons].
  ///
  /// Hier stand zuerst ein hochkantes Format, weil die Flaeche hochkant
  /// war. Seit die Zeichnungen durchgehend quadratisch sind, ist die
  /// **Flaeche** quadratisch geworden und nicht das Bild — sonst
  /// stuenden 144 Punkte Rahmen leer.
  ///
  /// Ein Gegner wird damit deutlich groeber dargestellt als eine
  /// Fähigkeitskachel: 64 Bildpunkte auf rund 320 Punkte Breite, also
  /// jeder Bildpunkt fuenf Punkte gross. Das ist der Stil, nicht ein
  /// Fehler — wer feinere Gegner will, zeichnet sie auf 128 × 128 und
  /// legt sie als 512 ab.
  static const int artSize = PixelArt.artSize;
  static const int assetSize = PixelArt.assetSize;
}

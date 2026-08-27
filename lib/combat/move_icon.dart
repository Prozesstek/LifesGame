/// Welches Bild zu einem Zug gehört.
///
/// **Reine Darstellung.** Was ein Zug tut, steht in `package:combat`; hier
/// steht nur, wie er aussieht — dieselbe Trennung wie bei
/// `MoveAnimation` und `moveHelpFor`.
///
/// **Nicht jeder Zug hat eins**, und das ist gewollt: Bisher gibt es die
/// vier Umgebungen als Bild. Wer keins hat, bekommt keinen Platzhalter —
/// sechzehn leere Kästchen sähen aus, als wäre etwas nicht geladen.
abstract final class MoveIcons {
  static const String _ordner = 'assets/abilities';

  /// Move-Id → Dateiname.
  ///
  /// **Die Datei heißt wie die Id.** Ein neues Bild ist damit eine Datei
  /// im Ordner und eine Zeile hier; dass die Id wirklich existiert, prüft
  /// `test/move_icon_test.dart` gegen `package:combat`.
  static const Map<String, String> _dateien = <String, String>{
    'frostnebel': 'frostnebel.png',
    'sandsturm': 'sandsturm.png',
    'giftmoor': 'giftmoor.png',
    'vulkanbruch': 'vulkanbruch.png',
  };

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
  /// Dreifache Kachelgröße, damit sie auf einem Handy mit dreifacher
  /// Pixeldichte nicht hochgerechnet werden müssen. Die Vorlagen sind
  /// 1024 × 1024 — es wird also verkleinert, nie vergrößert.
  static const int assetSize = 384;
}

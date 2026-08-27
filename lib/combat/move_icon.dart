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

  /// Kantenlänge der Kachel im Kampf — das Bild **ist** der Knopf.
  ///
  /// Zwei Kacheln nebeneinander passen bei 390 Pixeln Breite bequem
  /// (175 je Kachel). Begrenzt wird die Größe von der **Höhe**: Arena und
  /// zwei Kachelreihen teilen sich rund 660 Pixel, und zwei Reihen kosten
  /// hier zusammen etwa 300.
  static const double tileSize = 128;

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

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

  /// Kantenlänge auf dem Move-Knopf im Kampf.
  ///
  /// Bewusst klein: Zwei Knöpfe nebeneinander lassen bei 390 Pixeln
  /// Breite rund 155 Pixel Inhalt je Knopf, und Name und Energiekosten
  /// brauchen davon den größeren Teil.
  static const double buttonSize = 28;
}

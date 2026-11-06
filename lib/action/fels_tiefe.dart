import 'package:action_combat/action_combat.dart';

/// Welche Wandfelder tief im Fels liegen — **nur Darstellung**.
///
/// Gesehen wird von einer Wand nur ihr Rand. Ein Feld, um das herum
/// [rand] Felder weit nur Wand liegt, bekommt deshalb keinen Stein,
/// sondern eine dunkle Fläche. Kollision und Wege fragen weiter
/// `Level.isWallAt`; hier ändert sich nur, was gemalt wird.
class FelsTiefe {
  FelsTiefe._(this._width, this._tief);

  /// Wie viele Steine eine Wand vom Boden aus breit gezeichnet wird.
  static const int rand = 2;

  final int _width;
  final List<bool> _tief;

  /// Rechnet es einmal je Karte aus. Gezählt werden die festen Felder
  /// (`Tile.wand`) — ein Tor oder ein gerufener Fels liegt auf Boden und
  /// macht seine Nachbarn deshalb zum Rand.
  factory FelsTiefe.aus(Level level) {
    final breite = level.width;
    final hoehe = level.height;
    bool wand(int x, int y) => level.tileAt(x, y) == Tile.wand;

    final tief = List<bool>.filled(breite * hoehe, false);
    for (var y = 0; y < hoehe; y++) {
      for (var x = 0; x < breite; x++) {
        tief[y * breite + x] = _ringsumWand(x, y, wand);
      }
    }
    return FelsTiefe._(breite, tief);
  }

  static bool _ringsumWand(int x, int y, bool Function(int, int) wand) {
    for (var dy = -rand; dy <= rand; dy++) {
      for (var dx = -rand; dx <= rand; dx++) {
        if (!wand(x + dx, y + dy)) return false;
      }
    }
    return true;
  }

  /// Ob das Feld ohne Stein bleibt.
  bool istTief(int x, int y) {
    if (x < 0 || y < 0 || x >= _width) return false;
    final i = y * _width + x;
    return i < _tief.length && _tief[i];
  }
}

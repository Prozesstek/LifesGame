import 'dart:collection';

import 'balance.dart';
import 'level.dart';
import 'vec2.dart';

/// Wie weit jedes Feld von einem Ziel entfernt ist — und in welche
/// Richtung man von dort aus gehen muss.
///
/// **Ein Feld statt dreissig Wegen.** Ein A\* je Gegner und Bild wäre
/// dreissig Suchen; eine Flutfüllung vom Helden aus ist **eine**, und
/// alle Gegner lesen daraus ihre Richtung ab. Das ist der übliche Griff
/// in dieser Art Spiel, und er stimmt hier besonders gut: Alle wollen
/// zum selben Ziel.
///
/// Ohne das bleibt jeder an der ersten Ecke stehen. Genau das hat der
/// kopflose Lauf beim ersten Versuch gemeldet — zwei Gegner erledigt,
/// dann fünf Minuten gegen eine Wand gelaufen.
class FlowField {
  FlowField._(this._level, this._distances, this._width);

  /// Flutet die Halle von [tileX], [tileY] aus.
  factory FlowField.from(Level level, int tileX, int tileY) {
    final width = level.width;
    final distances = List<int>.filled(width * level.height, _unreachable);

    if (!level.isWallAt(tileX, tileY)) {
      distances[tileY * width + tileX] = 0;
      final queue = Queue<int>()..add(tileY * width + tileX);

      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        final x = current % width;
        final y = current ~/ width;
        final next = distances[current] + 1;

        for (final richtung in _richtungen) {
          final nx = x + richtung[0];
          final ny = y + richtung[1];
          if (level.isWallAt(nx, ny)) continue;
          final index = ny * width + nx;
          if (index < 0 || index >= distances.length) continue;
          if (distances[index] <= next) continue;
          distances[index] = next;
          queue.add(index);
        }
      }
    }

    return FlowField._(level, distances, width);
  }

  static const int _unreachable = 1 << 30;

  static const List<List<int>> _richtungen = <List<int>>[
    <int>[1, 0],
    <int>[-1, 0],
    <int>[0, 1],
    <int>[0, -1],
  ];

  final Level _level;
  final List<int> _distances;
  final int _width;

  /// Entfernung in Feldern, oder null, wenn dort niemand hinkommt.
  int? distanceAt(int tileX, int tileY) {
    if (tileX < 0 || tileY < 0 || tileX >= _width) return null;
    final index = tileY * _width + tileX;
    if (index < 0 || index >= _distances.length) return null;
    final wert = _distances[index];
    return wert == _unreachable ? null : wert;
  }

  int? distanceAtPoint(Vec2 point) {
    return distanceAt(
      (point.x / ActionBalance.tileSize).floor(),
      (point.y / ActionBalance.tileSize).floor(),
    );
  }

  /// Die Richtung, in die man von [from] aus gehen muss.
  ///
  /// Gezielt wird auf die **Mitte** des nächsten Feldes, nicht einfach
  /// nach Norden oder Osten: Sonst schrammt eine Figur an jeder Ecke
  /// entlang und bleibt in der Türbreite hängen.
  Vec2 directionFrom(Vec2 from) {
    const size = ActionBalance.tileSize;
    final x = (from.x / size).floor();
    final y = (from.y / size).floor();

    final hier = distanceAt(x, y);
    if (hier == null || hier == 0) return Vec2.zero;

    var besterX = x;
    var besterY = y;
    var beste = hier;

    for (final richtung in _richtungen) {
      final nx = x + richtung[0];
      final ny = y + richtung[1];
      if (_level.isWallAt(nx, ny)) continue;
      final wert = distanceAt(nx, ny);
      if (wert == null || wert >= beste) continue;
      beste = wert;
      besterX = nx;
      besterY = ny;
    }

    if (besterX == x && besterY == y) return Vec2.zero;

    final ziel = Vec2(besterX * size + size / 2, besterY * size + size / 2);
    return (ziel - from).normalized;
  }
}

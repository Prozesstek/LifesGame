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
  FlowField._(this._blocked, this._distances, this._width);

  /// Flutet die Halle von [tileX], [tileY] aus.
  ///
  /// Mit [wide] gilt ein Feld nur als frei, wenn es zu einem freien
  /// Block aus 2 × 2 Feldern gehört. **Das Feld für breite Figuren**: Ein
  /// Troll ist breiter als ein Feld und passt durch keinen Gang, der nur
  /// eines breit ist — ohne dieses Feld schickte ihn der Weg trotzdem
  /// hinein, und er blieb davor stehen.
  factory FlowField.from(
    Level level,
    int tileX,
    int tileY, {
    bool wide = false,
  }) {
    final width = level.width;
    final distances = List<int>.filled(width * level.height, _unreachable);
    final blocked =
        wide ? (int x, int y) => !_inFreeBlock(level, x, y) : level.isWallAt;

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
          if (blocked(nx, ny)) continue;
          final index = ny * width + nx;
          if (index < 0 || index >= distances.length) continue;
          if (distances[index] <= next) continue;
          distances[index] = next;
          queue.add(index);
        }
      }
    }

    return FlowField._(blocked, distances, width);
  }

  /// Ob [x], [y] frei ist und zu einem freien 2 × 2-Block gehört.
  static bool _inFreeBlock(Level level, int x, int y) {
    if (level.isWallAt(x, y)) return false;
    for (final dx in const <int>[-1, 0]) {
      for (final dy in const <int>[-1, 0]) {
        if (!level.isWallAt(x + dx, y + dy) &&
            !level.isWallAt(x + dx + 1, y + dy) &&
            !level.isWallAt(x + dx, y + dy + 1) &&
            !level.isWallAt(x + dx + 1, y + dy + 1)) {
          return true;
        }
      }
    }
    return false;
  }

  static const int _unreachable = 1 << 30;

  static const List<List<int>> _richtungen = <List<int>>[
    <int>[1, 0],
    <int>[-1, 0],
    <int>[0, 1],
    <int>[0, -1],
  ];

  final bool Function(int x, int y) _blocked;
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
    final weg = pathFrom(from, maxSteps: 1);
    if (weg.isEmpty) return Vec2.zero;
    return (weg.first - from).normalized;
  }

  /// Die Mitten der nächsten [maxSteps] Felder am Weg entlang, das
  /// nächste zuerst. Leer, wenn [from] schon am Ziel liegt oder das Ziel
  /// von dort nicht erreichbar ist.
  ///
  /// Das Feld kennt nur vier Richtungen, der Weg ist also eine Treppe.
  /// Wer ihm Feld für Feld folgt, läuft im Zickzack; wer den weitesten
  /// Punkt ansteuert, den er ohne Wand erreicht, läuft gerade — dafür ist
  /// diese Liste da (`ActionWorld._chaseDirection`).
  List<Vec2> pathFrom(Vec2 from, {required int maxSteps}) {
    const size = ActionBalance.tileSize;
    var x = (from.x / size).floor();
    var y = (from.y / size).floor();
    final weg = <Vec2>[];

    while (weg.length < maxSteps) {
      final naechstes = _downhill(x, y);
      if (naechstes == null) break;
      x = naechstes % _width;
      y = naechstes ~/ _width;
      weg.add(Vec2(x * size + size / 2, y * size + size / 2));
    }
    return weg;
  }

  /// Das Nachbarfeld, das dem Ziel am nächsten liegt, als Index — oder
  /// null am Ziel und ausserhalb des Erreichbaren.
  int? _downhill(int x, int y) {
    final hier = distanceAt(x, y);
    if (hier == null || hier == 0) return null;

    int? bester;
    var beste = hier;
    for (final richtung in _richtungen) {
      final nx = x + richtung[0];
      final ny = y + richtung[1];
      if (_blocked(nx, ny)) continue;
      final wert = distanceAt(nx, ny);
      if (wert == null || wert >= beste) continue;
      beste = wert;
      bester = ny * _width + nx;
    }
    return bester;
  }
}

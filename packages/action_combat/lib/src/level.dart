import 'dart:collection';

import 'balance.dart';
import 'entity.dart';
import 'vec2.dart';

/// Was auf einem Feld steht.
enum Tile { wand, boden }

/// Wo ein Gegner anfängt.
class Spawn {
  const Spawn({required this.kind, required this.tileX, required this.tileY});

  final EnemyKind kind;
  final int tileX;
  final int tileY;
}

/// Eine Halle als Karte.
///
/// **Als Text geschrieben, nicht als Zahlenliste.** Ein Prototyp lebt
/// davon, dass man ihn ändern kann, ohne den Code zu lesen — wer einen
/// Gegner mehr will, tippt ein `e` in die Zeile. Dass die Karte danach
/// noch trägt, prüft [problems]: geschlossen, genau ein Startpunkt,
/// genau ein Endgegner, und **jeder Gegner vom Start aus erreichbar**.
///
/// Dieselbe Rolle wie `TheoryGraph.isHealthy`: Inhalt, den ein Test
/// mitprüft, statt Inhalt, dem man ansieht, dass er stimmt.
class Level {
  Level._({
    required this.name,
    required this.tiles,
    required this.heroStart,
    required this.spawns,
  });

  /// Liest eine Karte aus Zeilen.
  ///
  /// | Zeichen | Bedeutung |
  /// |---|---|
  /// | `#` | Wand |
  /// | `.` | Boden |
  /// | `@` | Start des Helden |
  /// | `e` | Fussvolk |
  /// | `s` | Fernkämpfer |
  /// | `B` | Endgegner |
  /// | `k` | Kobold — schnell, schwach |
  /// | `t` | Troll — gross, zäh |
  ///
  /// Kürzere Zeilen werden rechts mit Wand aufgefüllt. Ein unbekanntes
  /// Zeichen wirft — anders als beim Spielstand ist das hier kein fremdes
  /// Datum, sondern ein Tippfehler im eigenen Repo, und der soll laut
  /// werden.
  factory Level.parse(String name, List<String> rows) {
    if (rows.isEmpty) throw ArgumentError('Die Halle "$name" ist leer.');

    final width =
        rows.fold<int>(0, (max, r) => r.length > max ? r.length : max);
    final tiles = <List<Tile>>[];
    final spawns = <Spawn>[];
    Vec2? start;

    for (var y = 0; y < rows.length; y++) {
      final row = <Tile>[];
      for (var x = 0; x < width; x++) {
        final zeichen = x < rows[y].length ? rows[y][x] : '#';
        switch (zeichen) {
          case '#':
            row.add(Tile.wand);
          case '.':
            row.add(Tile.boden);
          case '@':
            row.add(Tile.boden);
            start = _centerOf(x, y);
          case 'e':
            row.add(Tile.boden);
            spawns.add(Spawn(kind: EnemyKind.fussvolk, tileX: x, tileY: y));
          case 's':
            row.add(Tile.boden);
            spawns.add(Spawn(kind: EnemyKind.schuetze, tileX: x, tileY: y));
          case 'B':
            row.add(Tile.boden);
            spawns.add(Spawn(kind: EnemyKind.endgegner, tileX: x, tileY: y));
          case 'k':
            row.add(Tile.boden);
            spawns.add(Spawn(kind: EnemyKind.flink, tileX: x, tileY: y));
          case 't':
            row.add(Tile.boden);
            spawns.add(Spawn(kind: EnemyKind.brocken, tileX: x, tileY: y));
          default:
            throw ArgumentError(
              'Unbekanntes Zeichen "$zeichen" in "$name" bei $x,$y.',
            );
        }
      }
      tiles.add(List<Tile>.unmodifiable(row));
    }

    if (start == null) {
      throw ArgumentError('Die Halle "$name" hat kein "@".');
    }

    return Level._(
      name: name,
      tiles: List<List<Tile>>.unmodifiable(tiles),
      heroStart: start,
      spawns: List<Spawn>.unmodifiable(spawns),
    );
  }

  final String name;
  final List<List<Tile>> tiles;
  final Vec2 heroStart;
  final List<Spawn> spawns;

  int get height => tiles.length;

  int get width => tiles.isEmpty ? 0 : tiles.first.length;

  double get worldWidth => width * ActionBalance.tileSize;

  double get worldHeight => height * ActionBalance.tileSize;

  int get trashCount {
    return spawns.where((s) => s.kind != EnemyKind.endgegner).length;
  }

  int get archerCount {
    return spawns.where((s) => s.kind == EnemyKind.schuetze).length;
  }

  Tile tileAt(int x, int y) {
    if (y < 0 || y >= height || x < 0 || x >= width) return Tile.wand;
    return tiles[y][x];
  }

  bool isWallAt(int x, int y) => tileAt(x, y) == Tile.wand;

  /// Ob der Weltpunkt [point] in einer Wand liegt.
  bool isWallAtPoint(Vec2 point) {
    return isWallAt(
      (point.x / ActionBalance.tileSize).floor(),
      (point.y / ActionBalance.tileSize).floor(),
    );
  }

  static Vec2 _centerOf(int tileX, int tileY) {
    const size = ActionBalance.tileSize;
    return Vec2(tileX * size + size / 2, tileY * size + size / 2);
  }

  Vec2 centerOfSpawn(Spawn spawn) => _centerOf(spawn.tileX, spawn.tileY);

  /// Was an dieser Halle nicht stimmt. Leer heisst: sie trägt.
  ///
  /// Vier Prüfungen, jede mit einem Fehler dahinter, den man sonst erst
  /// im Spiel merkt — und die letzte erst nach zwei Minuten Suchen.
  List<String> get problems {
    final fehler = <String>[];

    for (var x = 0; x < width; x++) {
      if (!isWallAt(x, 0) || !isWallAt(x, height - 1)) {
        fehler.add('Die Halle ist oben oder unten offen (Spalte $x).');
        break;
      }
    }
    for (var y = 0; y < height; y++) {
      if (!isWallAt(0, y) || !isWallAt(width - 1, y)) {
        fehler.add('Die Halle ist links oder rechts offen (Zeile $y).');
        break;
      }
    }

    final endgegner = spawns.where((s) => s.kind == EnemyKind.endgegner);
    if (endgegner.length != 1) {
      fehler.add('Genau ein Endgegner, nicht ${endgegner.length}.');
    }
    if (spawns.length < 2) {
      fehler.add('Eine Halle ohne Gegner ist ein Spaziergang.');
    }

    final erreichbar = _reachableFromStart();
    for (final spawn in spawns) {
      if (!erreichbar.contains(_key(spawn.tileX, spawn.tileY))) {
        fehler.add(
          'Gegner bei ${spawn.tileX},${spawn.tileY} ist eingemauert.',
        );
      }
    }

    return fehler;
  }

  bool get isHealthy => problems.isEmpty;

  /// Flutfüllung vom Startfeld aus.
  Set<int> _reachableFromStart() {
    const size = ActionBalance.tileSize;
    final startX = (heroStart.x / size).floor();
    final startY = (heroStart.y / size).floor();

    final gesehen = <int>{_key(startX, startY)};
    final queue = Queue<List<int>>()..add(<int>[startX, startY]);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      const richtungen = <List<int>>[
        <int>[1, 0],
        <int>[-1, 0],
        <int>[0, 1],
        <int>[0, -1],
      ];
      for (final richtung in richtungen) {
        final nx = current[0] + richtung[0];
        final ny = current[1] + richtung[1];
        if (isWallAt(nx, ny)) continue;
        if (!gesehen.add(_key(nx, ny))) continue;
        queue.add(<int>[nx, ny]);
      }
    }
    return gesehen;
  }

  int _key(int x, int y) => y * 10000 + x;
}

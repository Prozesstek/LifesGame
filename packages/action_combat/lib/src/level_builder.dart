import 'dart:math' as math;

import 'balance.dart';
import 'level.dart';
import 'room_catalog.dart';
import 'stage.dart';

/// Steckt aus den Räumen in [RoomCatalog] eine Grube zusammen (ADR-0039).
///
/// **Gesät, nicht zufällig.** Derselbe Startwert ergibt dieselbe Karte —
/// nur so lässt sich eine Stufe ohne Bildschirm durchsimulieren und ein
/// Fehler, den jemand gemeldet hat, nachstellen.
///
/// Das Verfahren ist absichtlich einfach:
///
/// 1. Ein Raster aus [gridColumns] × [gridRows] Zellen.
/// 2. Ein Pfad durch das Raster, der keine Zelle zweimal betritt: Start,
///    [PitStage.roomCount] Räume, der Wächter.
/// 3. In jede Zelle des Pfads ein Raum, zwischen Nachbarn ein Gang von
///    zwei Feldern Breite — von Mitte zu Mitte, damit er immer ankommt.
/// 4. Alles ausserhalb des Pfads bleibt Fels und wird abgeschnitten.
///
/// Ob das Ergebnis trägt, prüft danach dieselbe Stelle wie bei einer
/// handgeschriebenen Halle: [Level.problems].
abstract final class LevelBuilder {
  static const int gridColumns = 4;
  static const int gridRows = 4;

  /// Eine Zelle ist ein Raum plus ein Feld Fels ringsum.
  static const int cellWidth = RoomCatalog.width + 2;
  static const int cellHeight = RoomCatalog.height + 2;

  static Level build({required PitStage stage, required int seed}) {
    final rng = math.Random(seed);
    final pfad = _path(rng, stage.roomCount + 2);

    const breite = gridColumns * cellWidth;
    const hoehe = gridRows * cellHeight;
    final feld = List<List<String>>.generate(
      hoehe,
      (_) => List<String>.filled(breite, '#'),
    );

    for (var i = 0; i < pfad.length; i++) {
      final raum = i == 0
          ? RoomCatalog.startRoom
          : i == pfad.length - 1
              ? _pick(rng, RoomCatalog.bossRooms)
              : _mitTroll(rng, _pick(rng, RoomCatalog.rooms), stage);
      _stamp(feld, raum, pfad[i]);
    }

    for (var i = 1; i < pfad.length; i++) {
      _carve(feld, pfad[i - 1], pfad[i]);
    }

    final start = _centerOf(pfad.first);
    feld[start.y][start.x] = '@';

    return Level.parse('Die Grube · Stufe ${stage.number}', _crop(feld, pfad));
  }

  /// Ein Pfad aus [length] Zellen, der keine zweimal betritt.
  ///
  /// Tiefensuche mit Zurückgehen: Eine Sackgasse wird verlassen statt
  /// hingenommen. Auf einem Raster von 4 × 4 gibt es für jede Länge bis 16
  /// einen Weg, die Suche endet also immer.
  static List<_Cell> _path(math.Random rng, int length) {
    if (length > gridColumns * gridRows) {
      throw ArgumentError('Ein Pfad aus $length Zellen passt nicht.');
    }

    final start = _Cell(rng.nextInt(gridColumns), rng.nextInt(gridRows));
    final pfad = <_Cell>[start];
    final besucht = <_Cell>{start};

    bool weiter() {
      if (pfad.length == length) return true;
      final nachbarn = _neighbours(pfad.last)
          .where((c) => !besucht.contains(c))
          .toList()
        ..shuffle(rng);
      for (final n in nachbarn) {
        pfad.add(n);
        besucht.add(n);
        if (weiter()) return true;
        pfad.removeLast();
        besucht.remove(n);
      }
      return false;
    }

    if (!weiter()) {
      // Kann von diesem Start aus scheitern, nicht grundsätzlich — also
      // nochmal von vorn, mit dem nächsten Wurf desselben Generators.
      return _path(rng, length);
    }
    return pfad;
  }

  static Iterable<_Cell> _neighbours(_Cell c) sync* {
    if (c.x > 0) yield _Cell(c.x - 1, c.y);
    if (c.x < gridColumns - 1) yield _Cell(c.x + 1, c.y);
    if (c.y > 0) yield _Cell(c.x, c.y - 1);
    if (c.y < gridRows - 1) yield _Cell(c.x, c.y + 1);
  }

  /// Setzt mit einer Wahrscheinlichkeit, die mit der Stufe wächst, einen
  /// Troll an die Stelle eines Fussvolks.
  ///
  /// **Er ersetzt, statt dazuzukommen:** Die Zahl der Gegner hängt so
  /// weiter nur an den Räumen, und ein Raum mit Troll ist härter, nicht
  /// voller. Ein Raum, der schon einen hat, bekommt keinen zweiten.
  static List<String> _mitTroll(
    math.Random rng,
    List<String> raum,
    PitStage stage,
  ) {
    final chance = ActionBalance.brockenChanceFirst +
        (ActionBalance.brockenChanceLast - ActionBalance.brockenChanceFirst) *
            stage.progress;
    // Immer würfeln, auch wenn nichts daraus wird — sonst verschöbe ein
    // Raum ohne Fussvolk alle folgenden Würfe, und ein Startwert ergäbe
    // je nach Katalog eine andere Grube.
    final wurf = rng.nextDouble();
    final platz = rng.nextInt(1 << 16);
    if (wurf >= chance || raum.join().contains('t')) return raum;

    final plaetze = <(int, int)>[
      for (var y = 0; y < raum.length; y++)
        for (var x = 0; x < raum[y].length; x++)
          if (raum[y][x] == 'e') (x, y),
    ];
    if (plaetze.isEmpty) return raum;

    final (x, y) = plaetze[platz % plaetze.length];
    return <String>[
      for (var i = 0; i < raum.length; i++)
        i == y ? raum[i].replaceRange(x, x + 1, 't') : raum[i],
    ];
  }

  static List<String> _pick(math.Random rng, List<List<String>> auswahl) {
    return auswahl[rng.nextInt(auswahl.length)];
  }

  static void _stamp(List<List<String>> feld, List<String> raum, _Cell c) {
    final x0 = c.x * cellWidth + 1;
    final y0 = c.y * cellHeight + 1;
    for (var y = 0; y < RoomCatalog.height; y++) {
      for (var x = 0; x < RoomCatalog.width; x++) {
        feld[y0 + y][x0 + x] = raum[y][x];
      }
    }
  }

  /// Das linke obere der vier Mittelfelder einer Zelle.
  static _Tile _centerOf(_Cell c) {
    return _Tile(
      c.x * cellWidth + cellWidth ~/ 2 - 1,
      c.y * cellHeight + cellHeight ~/ 2 - 1,
    );
  }

  /// Ein Gang von zwei Feldern Breite zwischen zwei Nachbarzellen.
  ///
  /// **Nur Fels wird zu Boden.** Ein Gegner, der im Weg steht, bleibt
  /// stehen — sonst verschwände er beim Bauen, und die Zahl der Gegner
  /// hinge vom Zufall des Pfads ab.
  static void _carve(List<List<String>> feld, _Cell a, _Cell b) {
    final von = _centerOf(a);
    final nach = _centerOf(b);

    final x0 = math.min(von.x, nach.x);
    final x1 = math.max(von.x, nach.x) + 1;
    final y0 = math.min(von.y, nach.y);
    final y1 = math.max(von.y, nach.y) + 1;

    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        if (feld[y][x] == '#') feld[y][x] = '.';
      }
    }
  }

  /// Schneidet die unbenutzten Zellen ab — eine Grube aus vier Räumen
  /// soll nicht in einem Raster aus sechzehn liegen.
  static List<String> _crop(List<List<String>> feld, List<_Cell> pfad) {
    final xs = pfad.map((c) => c.x);
    final ys = pfad.map((c) => c.y);
    final links = xs.reduce(math.min) * cellWidth;
    final rechts = (xs.reduce(math.max) + 1) * cellWidth;
    final oben = ys.reduce(math.min) * cellHeight;
    final unten = (ys.reduce(math.max) + 1) * cellHeight;

    return <String>[
      for (var y = oben; y < unten; y++) feld[y].sublist(links, rechts).join(),
    ];
  }
}

class _Cell {
  const _Cell(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _Cell && other.x == x && other.y == y;

  @override
  int get hashCode => y * 100 + x;
}

class _Tile {
  const _Tile(this.x, this.y);

  final int x;
  final int y;
}

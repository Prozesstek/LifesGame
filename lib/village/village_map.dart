import 'dart:collection';
import 'dart:math' as math;

import 'package:action_combat/action_combat.dart' show Vec2;

/// Die Orte im Dorf — jeder führt zu einem Bereich des Spiels.
///
/// **Prototyp im Entwicklermodus.** Das Dorf ersetzt (noch) nicht die
/// Startseite mit den Kreisen; es probiert aus, ob sich ein Ort besser
/// anfühlt als ein Menü.
enum VillagePlace {
  buecherei('Bücherei', 'b', 'B'),
  hoehle('Höhle', 'h', 'H'),
  laden('Laden', 'l', 'L'),
  zuhause('Zuhause', 'z', 'Z'),
  brett('Brett', 's', 'S'),

  // --- im eigenen Haus ---
  trophaeen('Trophäen', 't', 'T', verb: 'ansehen'),
  titelwand('Titelwand', 'w', 'W', verb: 'ansehen'),
  ruestung('Rüstung', 'r', 'R', verb: 'ansehen'),
  truhe('Schatztruhe', 'k', 'K', verb: 'öffnen'),
  ausgang('Ausgang', 'a', 'A', verb: 'hinaus');

  const VillagePlace(
    this.label,
    this.doorChar,
    this.bodyChar, {
    this.verb = 'betreten',
  });

  /// Die Orte des Dorfs.
  static const List<VillagePlace> dorf = <VillagePlace>[
    buecherei,
    hoehle,
    laden,
    zuhause,
    brett,
  ];

  /// Die Dinge im eigenen Haus.
  static const List<VillagePlace> haus = <VillagePlace>[
    trophaeen,
    titelwand,
    ruestung,
    truhe,
    ausgang,
  ];

  final String label;

  /// Was der Knopf davor tut — ein Haus betritt man, ein Regal sieht man an.
  final String verb;

  /// Die Aufschrift des Knopfs.
  String get action => verb == 'hinaus' ? 'Hinausgehen' : '$label $verb';

  /// Das Feld, auf dem man den Ort betritt — begehbar.
  final String doorChar;

  /// Die Felder, die das Gebäude einnimmt — fest.
  final String bodyChar;
}

/// Ein Feld der Karte.
enum VillageTile { gras, weg, baum, gebaeude, tuer }

/// Ein Feld als Spalte und Zeile.
class TilePos {
  const TilePos(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is TilePos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}

/// **Die Dorfkarte**, aus Text gelesen wie die Räume der Grube.
///
/// `#` Baum, `.` Gras, `,` Weg, `@` Start. Grossbuchstaben sind Gebäude
/// ([VillagePlace.bodyChar]), der Kleinbuchstabe daneben ist ihre Tür.
/// Reines Dart: Die Karte, die Wege und das Laufen sind ohne Bildschirm
/// testbar.
class VillageMap {
  VillageMap._({
    required this.width,
    required this.height,
    required List<VillageTile> tiles,
    required this.start,
    required Map<VillagePlace, TilePos> doors,
    required Map<VillagePlace, ({TilePos from, TilePos to})> bodies,
  }) : _tiles = List<VillageTile>.unmodifiable(tiles),
       doors = Map<VillagePlace, TilePos>.unmodifiable(doors),
       bodies = Map<VillagePlace, ({TilePos from, TilePos to})>.unmodifiable(
         bodies,
       );

  factory VillageMap.parse(List<String> rows) {
    final hoehe = rows.length;
    final breite = rows.map((r) => r.length).reduce(math.max);
    final tiles = <VillageTile>[];
    TilePos? start;
    final tueren = <VillagePlace, TilePos>{};
    final flaechen = <VillagePlace, List<TilePos>>{};

    for (var y = 0; y < hoehe; y++) {
      final zeile = rows[y].padRight(breite, '#');
      for (var x = 0; x < breite; x++) {
        final c = zeile[x];
        final pos = TilePos(x, y);
        VillagePlace? tuer;
        VillagePlace? koerper;
        for (final p in VillagePlace.values) {
          if (p.doorChar == c) tuer = p;
          if (p.bodyChar == c) koerper = p;
        }
        if (tuer != null) {
          tueren[tuer] = pos;
          (flaechen[tuer] ??= <TilePos>[]).add(pos);
          tiles.add(VillageTile.tuer);
        } else if (koerper != null) {
          (flaechen[koerper] ??= <TilePos>[]).add(pos);
          tiles.add(VillageTile.gebaeude);
        } else {
          tiles.add(switch (c) {
            '#' => VillageTile.baum,
            ',' || '@' => VillageTile.weg,
            _ => VillageTile.gras,
          });
          if (c == '@') start = pos;
        }
      }
    }

    return VillageMap._(
      width: breite,
      height: hoehe,
      tiles: tiles,
      start: start ?? const TilePos(1, 1),
      doors: tueren,
      bodies: <VillagePlace, ({TilePos from, TilePos to})>{
        for (final MapEntry(:key, :value) in flaechen.entries)
          key: (
            from: TilePos(
              value.map((p) => p.x).reduce(math.min),
              value.map((p) => p.y).reduce(math.min),
            ),
            to: TilePos(
              value.map((p) => p.x).reduce(math.max),
              value.map((p) => p.y).reduce(math.max),
            ),
          ),
      },
    );
  }

  /// Kantenlänge eines Felds in Weltpunkten — dieselbe wie in der Grube.
  static const double tileSize = 32;

  final int width;
  final int height;
  final List<VillageTile> _tiles;
  final TilePos start;

  /// Wo man jeden Ort betritt.
  final Map<VillagePlace, TilePos> doors;

  /// Welche Felder jeder Ort einnimmt, Tür eingeschlossen — für das Bild.
  final Map<VillagePlace, ({TilePos from, TilePos to})> bodies;

  VillageTile tileAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return VillageTile.baum;
    return _tiles[y * width + x];
  }

  bool isWalkable(int x, int y) => switch (tileAt(x, y)) {
    VillageTile.gras || VillageTile.weg || VillageTile.tuer => true,
    VillageTile.baum || VillageTile.gebaeude => false,
  };

  /// Welcher Ort an diesem Feld liegt — Tür oder Gebäude.
  VillagePlace? placeAt(int x, int y) {
    for (final MapEntry(:key, :value) in bodies.entries) {
      if (x >= value.from.x &&
          x <= value.to.x &&
          y >= value.from.y &&
          y <= value.to.y) {
        return key;
      }
    }
    return null;
  }

  static Vec2 centerOf(TilePos p) =>
      Vec2((p.x + 0.5) * tileSize, (p.y + 0.5) * tileSize);

  static TilePos tileOf(Vec2 v) =>
      TilePos((v.x / tileSize).floor(), (v.y / tileSize).floor());

  /// Der kürzeste Weg über begehbare Felder, ohne [from], mit [to] —
  /// oder null, wenn es keinen gibt. Vier Richtungen, Breitensuche: Die
  /// Karte ist klein, und ein Dorf braucht keine Umwege.
  List<TilePos>? pathBetween(TilePos from, TilePos to) {
    if (!isWalkable(to.x, to.y)) return null;
    final vorher = <TilePos, TilePos>{};
    final offen = Queue<TilePos>()..add(from);
    final gesehen = <TilePos>{from};
    while (offen.isNotEmpty) {
      final hier = offen.removeFirst();
      if (hier == to) break;
      for (final (dx, dy) in const <(int, int)>[
        (1, 0),
        (-1, 0),
        (0, 1),
        (0, -1),
      ]) {
        final n = TilePos(hier.x + dx, hier.y + dy);
        if (gesehen.contains(n) || !isWalkable(n.x, n.y)) continue;
        gesehen.add(n);
        vorher[n] = hier;
        offen.add(n);
      }
    }
    if (from != to && !vorher.containsKey(to)) return null;
    final weg = <TilePos>[];
    var p = to;
    while (p != from) {
      weg.add(p);
      p = vorher[p]!;
    }
    return weg.reversed.toList();
  }
}

/// Die Figur im Dorf: läuft per Steuerung oder zu einem angetippten Ziel,
/// und sagt, vor welcher Tür sie steht.
///
/// **Sie betritt nichts von selbst.** Wer an einer Tür ankommt, bekommt
/// einen Knopf am Gebäude; erst der öffnet den Ort. Sonst reisst jeder
/// Schritt über eine Türschwelle einen Bildschirm auf.
class VillageWalker {
  VillageWalker(this.map) : position = VillageMap.centerOf(map.start);

  final VillageMap map;

  /// Punkte je Sekunde, etwas gemächlicher als in der Grube (120).
  static const double speed = 110;

  /// Wie breit die Figur ist, für die Kollision.
  static const double radius = 9;

  Vec2 position;
  Vec2 facing = const Vec2(1, 0);

  /// Wie schnell sie sich im letzten Schritt bewegt hat — für die Pose.
  double lastSpeed = 0;

  List<TilePos> _weg = const <TilePos>[];

  /// Ob sie gerade einem Weg folgt.
  bool get isWalkingPath => _weg.isNotEmpty;

  /// Vor welcher Tür sie gerade steht — oder null. Nur, wenn sie steht:
  /// Wer an einer Tür vorbeiläuft, will nicht hinein.
  VillagePlace? get atDoor {
    if (_weg.isNotEmpty) return null;
    final t = VillageMap.tileOf(position);
    for (final MapEntry(:key, :value) in map.doors.entries) {
      if (value == t) return key;
    }
    return null;
  }

  /// Geht zu dem Feld, auf das getippt wurde. Ein Gebäude heisst: zu
  /// seiner Tür. Gibt zurück, ob es einen Weg gibt.
  bool walkTo(Vec2 point) {
    var ziel = VillageMap.tileOf(point);
    final ort = map.placeAt(ziel.x, ziel.y);
    if (ort != null) ziel = map.doors[ort] ?? ziel;
    final weg = map.pathBetween(VillageMap.tileOf(position), ziel);
    if (weg == null) return false;
    _weg = weg;
    return true;
  }

  /// Zurück vor die Tür von [place], nachdem man drinnen war — ein Feld
  /// darunter, damit man nicht gleich wieder hineinläuft.
  void stepOutOf(VillagePlace place) {
    final tuer = map.doors[place];
    if (tuer != null) {
      final davor = TilePos(tuer.x, tuer.y + 1);
      if (map.isWalkable(davor.x, davor.y)) {
        position = VillageMap.centerOf(davor);
      }
    }
    _weg = const <TilePos>[];
  }

  /// Ein Schritt. [input] ist die Richtung der Steuerung, Länge bis 1;
  /// sie hat Vorrang vor einem angetippten Weg.
  void step(double dt, Vec2 input) {
    var richtung = Vec2.zero;
    if (!input.isZero) {
      _weg = const <TilePos>[];
      richtung = input.clampLength(1);
    } else if (_weg.isNotEmpty) {
      final ziel = VillageMap.centerOf(_weg.first);
      final hin = ziel - position;
      if (hin.length < 3) {
        _weg = _weg.sublist(1);
      } else {
        richtung = hin.normalized;
      }
    }

    final vorher = position;
    if (!richtung.isZero) {
      facing = richtung;
      _gleite(richtung * (speed * dt));
    }
    lastSpeed = dt > 0 ? (position - vorher).length / dt : 0;
  }

  /// Achsenweise bewegen, damit man an Kanten entlanggleitet statt
  /// hängenzubleiben. Im Dorf gibt es keine Ecken im Gedränge wie in der
  /// Grube, das reicht.
  void _gleite(Vec2 weg) {
    final nachX = Vec2(position.x + weg.x, position.y);
    if (_frei(nachX)) position = nachX;
    final nachY = Vec2(position.x, position.y + weg.y);
    if (_frei(nachY)) position = nachY;
  }

  bool _frei(Vec2 p) {
    for (final (dx, dy) in const <(double, double)>[
      (-1, -1),
      (1, -1),
      (-1, 1),
      (1, 1),
    ]) {
      final t = VillageMap.tileOf(Vec2(p.x + dx * radius, p.y + dy * radius));
      if (!map.isWalkable(t.x, t.y)) return false;
    }
    return true;
  }
}

/// Das Dorf des Prototyps.
/// Das Dorf des Prototyps — **hochkant**, zwölf Felder breit: Auf einem
/// Handy im Hochformat passt es damit in die Breite, und die Höhe reicht
/// für fast alles auf einmal.
///
/// Die Türen sitzen dort, wo `tool/dorf_kacheln.py` sie ins Bild malt:
/// Höhle in der dritten Spalte ihres Felsens, alle anderen in der zweiten.
final VillageMap village = VillageMap.parse(const <String>[
  '############',
  '#HHHH.BBBB.#',
  '#HHHH.BBBB.#',
  '#HHhH.BbBB.#',
  '#..,...,...#',
  '#..,,,,,...#',
  '#....,.....#',
  '#...S,.....#',
  '#...s,.....#',
  '#...,,.....#',
  '#....,.....#',
  '#LLL.,.ZZZ.#',
  '#LLL.,.ZZZ.#',
  '#LlL.,.ZzZ.#',
  '#.,,,@,,,..#',
  '#..........#',
  '############',
]);

/// **Das eigene Haus** — ein Raum, in dem die Figur herumläuft wie im
/// Dorf. `#` ist hier Wand. Oben an der Wand hängen Titel und steht das
/// Trophäenregal, links der Rüstungsständer, rechts die Schatztruhe; der
/// Kleinbuchstabe darunter ist der Platz davor. Unten geht es hinaus.
final VillageMap house = VillageMap.parse(const <String>[
  '############',
  '#WWWW..TTTT#',
  '#.w......t.#',
  '#..........#',
  '#RR........#',
  '#RR......KK#',
  '#r.......k.#',
  '#..........#',
  '#....@.....#',
  '#####a######',
]);

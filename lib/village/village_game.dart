import 'dart:async';
import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart' show Vec2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../action/action_sprites.dart';
import '../ui/palette.dart';
import 'village_map.dart';

/// Die Bilder des Dorfs und des Hauses — grob gezeichnet von
/// `tool/dorf_kacheln.py`. Hier stehen ganze Pfade.
abstract final class DorfBilder {
  static const String folder = 'assets/Dorf';

  static const String gras = '$folder/gras.png';
  static const String gras2 = '$folder/gras2.png';
  static const String weg = '$folder/weg.png';
  static const String baum = '$folder/baum.png';
  static const String dielen = '$folder/dielen.png';
  static const String dielen2 = '$folder/dielen2.png';
  static const String wand = '$folder/wand.png';

  /// Welches Bild zu welchem Ort gehört — **eine Tabelle**.
  static const Map<VillagePlace, String> orte = <VillagePlace, String>{
    VillagePlace.buecherei: '$folder/buecherei.png',
    VillagePlace.hoehle: '$folder/hoehle.png',
    VillagePlace.laden: '$folder/laden.png',
    VillagePlace.zuhause: '$folder/zuhause.png',
    VillagePlace.brett: '$folder/brett.png',
    VillagePlace.trophaeen: '$folder/regal.png',
    VillagePlace.titelwand: '$folder/titelwand.png',
    VillagePlace.ruestung: '$folder/ruestung.png',
    VillagePlace.truhe: '$folder/truhe.png',
    VillagePlace.ausgang: '$folder/ausgang.png',
  };

  static List<String> get all => <String>[
    gras,
    gras2,
    weg,
    baum,
    dielen,
    dielen2,
    wand,
    ...orte.values,
  ];
}

/// Womit eine Szene ihren Boden zeichnet — draussen Gras und Bäume,
/// drinnen Dielen und Wände. Die Karte sagt nur, was begehbar ist.
class VillageScene {
  const VillageScene({
    required this.map,
    required this.boden,
    required this.boden2,
    required this.rand,
    required this.bodenFarbe,
    this.weg,
  });

  final VillageMap map;
  final String boden;
  final String boden2;

  /// Was auf einem `#` steht: Baum oder Wand.
  final String rand;
  final String? weg;

  /// Solange die Bilder laden.
  final Color bodenFarbe;

  static final VillageScene dorf = VillageScene(
    map: village,
    boden: DorfBilder.gras,
    boden2: DorfBilder.gras2,
    rand: DorfBilder.baum,
    weg: DorfBilder.weg,
    bodenFarbe: const Color(0xFF567D3A),
  );

  static final VillageScene haus = VillageScene(
    map: house,
    boden: DorfBilder.dielen,
    boden2: DorfBilder.dielen2,
    rand: DorfBilder.wand,
    bodenFarbe: const Color(0xFF8A5A30),
  );
}

/// **Das Dorf als Spiel** — zeichnet Karte, Gebäude und die Figur, und
/// bewegt sie über [walker]. Betreten wird hier nichts: Vor welcher Tür
/// die Figur steht, liest der Bildschirm aus [walker] und zeigt dort einen
/// Knopf. Dieselbe Klasse zeichnet das Haus, mit einer anderen [scene].
class VillageGame extends Game {
  VillageGame({required this.walker, VillageScene? scene})
    : scene = scene ?? VillageScene.dorf;

  final VillageWalker walker;
  final VillageScene scene;

  /// Zeichnet etwas in einen Ort hinein — das Haus stellt so Pokale ins
  /// Regal und Gold neben die Truhe. [VillageGame] weiss davon nichts.
  void Function(Canvas canvas, VillagePlace place, Rect area)? decorate;

  /// Zählt Bilder hoch, damit der Knopf am Gebäude mit der Kamera wandert,
  /// ohne den ganzen Bildschirm neu zu bauen — wie in der Grube.
  final ValueNotifier<int> frame = ValueNotifier<int>(0);

  /// Die Richtung der Steuerung, gesetzt vom Ziehen.
  Vec2 moveInput = Vec2.zero;

  final Map<String, ui.Image> _bilder = <String, ui.Image>{};
  final Set<String> _unterwegs = <String>{};
  GrubeBilder? _figur;
  double _zeit = 0;
  bool _nachLinks = false;

  @override
  Future<void> onLoad() async {
    // Nicht abwarten — wie in der Grube: Das Dorf steht sofort, die
    // Bilder kommen, sobald sie da sind. Bis dahin zeichnet es Flächen.
    unawaited(_ladeKacheln());
    unawaited(
      GrubeBilder.load().then(
        (b) => _figur = b,
        onError: (Object f) => debugPrint('Dorf ohne Figur: $f'),
      ),
    );
  }

  Future<void> _ladeKacheln() async {
    for (final pfad in DorfBilder.all) {
      await _lade(pfad);
    }
  }

  Future<void> _lade(String pfad) async {
    if (_bilder.containsKey(pfad) || !_unterwegs.add(pfad)) return;
    try {
      final daten = await rootBundle.load(pfad);
      final codec = await ui.instantiateImageCodec(daten.buffer.asUint8List());
      _bilder[pfad] = (await codec.getNextFrame()).image;
    } on Exception catch (f) {
      debugPrint('Bild fehlt: $pfad ($f)');
    }
  }

  /// Ein Bild unter [pfad] — beim ersten Mal null, danach geladen. Für
  /// [decorate], das Bilder braucht, die keine Kachel sind.
  ui.Image? image(String pfad) {
    final bild = _bilder[pfad];
    if (bild == null) unawaited(_lade(pfad));
    return bild;
  }

  static final Paint _hart = Paint()..filterQuality = FilterQuality.none;

  /// Zeichnet [bild] hart skaliert in [ziel].
  static void drawImage(Canvas canvas, ui.Image bild, Rect ziel) {
    canvas.drawImageRect(
      bild,
      Rect.fromLTWH(0, 0, bild.width.toDouble(), bild.height.toDouble()),
      ziel,
      _hart,
    );
  }

  @override
  void update(double dt) {
    // Solange ein Ort offen ist, hält der Bildschirm das Spiel über
    // Flames `paused` an — dann kommt hier gar nichts an.
    _zeit += dt;
    walker.step(dt, moveInput);
    if (walker.facing.x.abs() > 0.15) _nachLinks = walker.facing.x < 0;
    frame.value++;
  }

  /// Wo ein Punkt der Welt gerade auf dem Bildschirm liegt.
  Offset worldToScreen(Vec2 punkt) {
    final k = _kamera();
    return Offset(punkt.x + k.x, punkt.y + k.y);
  }

  /// Aus einem Punkt auf dem Bildschirm ein Punkt in der Welt.
  Vec2 screenToWorld(Offset punkt) {
    final k = _kamera();
    return Vec2(punkt.dx - k.x, punkt.dy - k.y);
  }

  Vec2 _kamera() {
    final breite = walker.map.width * VillageMap.tileSize;
    final hoehe = walker.map.height * VillageMap.tileSize;
    final held = walker.position;
    var x = size.x / 2 - held.x;
    var y = size.y / 2 - held.y;
    x = breite > size.x ? x.clamp(size.x - breite, 0) : (size.x - breite) / 2;
    y = hoehe > size.y ? y.clamp(size.y - hoehe, 0) : (size.y - hoehe) / 2;
    return Vec2(x, y);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = Palette.background,
    );
    final k = _kamera();
    canvas.save();
    canvas.translate(k.x, k.y);
    _boden(canvas);
    _gebaeude(canvas);
    _held(canvas);
    _namen(canvas);
    canvas.restore();
  }

  void _kachel(Canvas canvas, String pfad, double x, double y, Color ersatz) {
    const t = VillageMap.tileSize;
    final bild = _bilder[pfad];
    final ziel = Rect.fromLTWH(x, y, t, t);
    if (bild == null) {
      canvas.drawRect(ziel, Paint()..color = ersatz);
      return;
    }
    drawImage(canvas, bild, ziel);
  }

  void _boden(Canvas canvas) {
    const t = VillageMap.tileSize;
    final karte = walker.map;
    final szene = scene;
    final weg = szene.weg;
    for (var y = 0; y < karte.height; y++) {
      for (var x = 0; x < karte.width; x++) {
        final px = x * t;
        final py = y * t;
        final boden = (x * 7 + y * 3) % 3 == 0 ? szene.boden2 : szene.boden;
        _kachel(canvas, boden, px, py, szene.bodenFarbe);
        switch (karte.tileAt(x, y)) {
          case VillageTile.weg:
            if (weg != null) {
              _kachel(canvas, weg, px, py, const Color(0xFFC4A46C));
            }
          case VillageTile.baum:
            _kachel(canvas, szene.rand, px, py, const Color(0xFF2C5828));
          case VillageTile.tuer:
            // Der Platz vor dem Brett ist Weg, die Türen der Häuser
            // zeichnet das Gebäude selbst.
            if (weg != null && karte.placeAt(x, y) == VillagePlace.brett) {
              _kachel(canvas, weg, px, py, const Color(0xFFC4A46C));
            }
          case VillageTile.gras || VillageTile.gebaeude:
            break;
        }
      }
    }
  }

  void _gebaeude(Canvas canvas) {
    const t = VillageMap.tileSize;
    for (final MapEntry(:key, :value) in walker.map.bodies.entries) {
      final ziel = Rect.fromLTRB(
        value.from.x * t,
        value.from.y * t,
        (value.to.x + 1) * t,
        (value.to.y + 1) * t,
      );
      final bild = _bilder[DorfBilder.orte[key]];
      if (bild == null) {
        canvas.drawRect(ziel, Paint()..color = Palette.surfaceSunken);
      } else {
        drawImage(canvas, bild, ziel);
      }
      decorate?.call(canvas, key, ziel);
    }
  }

  void _held(Canvas canvas) {
    final fuss = Offset(walker.position.x, walker.position.y + 8);
    canvas.drawOval(
      Rect.fromCenter(center: fuss, width: 18, height: 7),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    final figur = _figur;
    if (figur == null) {
      canvas.drawCircle(
        Offset(walker.position.x, walker.position.y),
        VillageWalker.radius,
        Paint()..color = Palette.accentOnDark,
      );
      return;
    }
    final laeuft = walker.lastSpeed > 20;
    figur.draw(
      canvas,
      figure: GrubeFiguren.held,
      pose: laeuft ? Pose.walk : Pose.idle,
      time: _zeit,
      foot: fuss,
      faceLeft: _nachLinks,
    );
  }

  /// Die Namen über den Orten — damit man ohne Legende weiss, was wo ist.
  void _namen(Canvas canvas) {
    const t = VillageMap.tileSize;
    for (final MapEntry(:key, :value) in walker.map.bodies.entries) {
      // Den Ausgang erkennt man am Bild — und über ihm ist Wand.
      if (key == VillagePlace.ausgang) continue;
      final mitte = (value.from.x + value.to.x + 1) / 2 * t;
      final oben = value.from.y * t - 4;
      final text = TextPainter(
        text: TextSpan(
          text: key.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Palette.textOnDark,
            shadows: <Shadow>[
              Shadow(color: Color(0xDD1A0E05), offset: Offset(1, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(mitte - text.width / 2, (oben - text.height).clamp(0, 1e9)),
      );
    }
  }
}

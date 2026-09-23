import 'dart:async';
import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart' show Vec2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../action/action_sprites.dart';
import '../ui/palette.dart';
import 'village_map.dart';

/// Die Bilder des Dorfs — grob gezeichnet von `tool/dorf_kacheln.py`.
abstract final class DorfBilder {
  static const String folder = 'assets/Dorf';

  static const String gras = 'gras.png';
  static const String gras2 = 'gras2.png';
  static const String weg = 'weg.png';
  static const String baum = 'baum.png';

  /// Welches Bild zu welchem Ort gehört — **eine Tabelle**.
  static const Map<VillagePlace, String> orte = <VillagePlace, String>{
    VillagePlace.buecherei: 'buecherei.png',
    VillagePlace.hoehle: 'hoehle.png',
    VillagePlace.laden: 'laden.png',
    VillagePlace.zuhause: 'zuhause.png',
    VillagePlace.brett: 'brett.png',
  };

  static List<String> get all => <String>[
    gras,
    gras2,
    weg,
    baum,
    ...orte.values,
  ];
}

/// **Das Dorf als Spiel** — zeichnet Karte, Gebäude und die Figur, und
/// bewegt sie über [walker]. Welcher Ort betreten wurde, meldet
/// [onEnter]; was dann passiert, entscheidet der Bildschirm.
class VillageGame extends Game {
  VillageGame({required this.walker, required this.onEnter});

  final VillageWalker walker;
  final void Function(VillagePlace place) onEnter;

  /// Die Richtung der Steuerung, gesetzt vom Ziehen.
  Vec2 moveInput = Vec2.zero;

  final Map<String, ui.Image> _bilder = <String, ui.Image>{};
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
    for (final datei in DorfBilder.all) {
      try {
        final daten = await rootBundle.load('${DorfBilder.folder}/$datei');
        final codec = await ui.instantiateImageCodec(
          daten.buffer.asUint8List(),
        );
        _bilder[datei] = (await codec.getNextFrame()).image;
      } on Exception catch (f) {
        debugPrint('Dorfbild fehlt: $datei ($f)');
      }
    }
  }

  @override
  void update(double dt) {
    // Solange ein Ort offen ist, hält der Bildschirm das Spiel über
    // Flames `paused` an — dann kommt hier gar nichts an.
    _zeit += dt;
    walker.step(dt, moveInput);
    if (walker.facing.x.abs() > 0.15) _nachLinks = walker.facing.x < 0;
    final ort = walker.takeEntered();
    if (ort != null) {
      moveInput = Vec2.zero;
      onEnter(ort);
    }
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

  static final Paint _hart = Paint()..filterQuality = FilterQuality.none;

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

  void _kachel(Canvas canvas, String datei, double x, double y, Color ersatz) {
    const t = VillageMap.tileSize;
    final bild = _bilder[datei];
    final ziel = Rect.fromLTWH(x, y, t, t);
    if (bild == null) {
      canvas.drawRect(ziel, Paint()..color = ersatz);
      return;
    }
    canvas.drawImageRect(
      bild,
      Rect.fromLTWH(0, 0, bild.width.toDouble(), bild.height.toDouble()),
      ziel,
      _hart,
    );
  }

  void _boden(Canvas canvas) {
    const t = VillageMap.tileSize;
    final karte = walker.map;
    for (var y = 0; y < karte.height; y++) {
      for (var x = 0; x < karte.width; x++) {
        final px = x * t;
        final py = y * t;
        final gras = (x * 7 + y * 3) % 3 == 0
            ? DorfBilder.gras2
            : DorfBilder.gras;
        _kachel(canvas, gras, px, py, const Color(0xFF567D3A));
        switch (karte.tileAt(x, y)) {
          case VillageTile.weg:
            _kachel(canvas, DorfBilder.weg, px, py, const Color(0xFFC4A46C));
          case VillageTile.baum:
            _kachel(canvas, DorfBilder.baum, px, py, const Color(0xFF2C5828));
          case VillageTile.tuer:
            // Der Platz vor dem Brett ist Weg, die Türen der Häuser
            // zeichnet das Gebäude selbst.
            if (karte.placeAt(x, y) == VillagePlace.brett) {
              _kachel(canvas, DorfBilder.weg, px, py, const Color(0xFFC4A46C));
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
        continue;
      }
      canvas.drawImageRect(
        bild,
        Rect.fromLTWH(0, 0, bild.width.toDouble(), bild.height.toDouble()),
        ziel,
        _hart,
      );
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

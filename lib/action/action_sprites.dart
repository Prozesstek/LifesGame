import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Was eine Figur gerade tut — und damit, welcher Streifen läuft.
enum Pose { idle, walk, attack, attack2, hurt, death }

/// Ein Streifen gleich grosser Bilder nebeneinander, von links nach rechts.
class SpriteStrip {
  const SpriteStrip(this.file, this.frames, {this.fps = 10});

  /// Dateiname unter [GrubeFiguren.folder].
  final String file;
  final int frames;
  final double fps;

  double get duration => frames / fps;

  /// Welches Bild nach [time] Sekunden dran ist.
  ///
  /// Ohne [loop] bleibt der Streifen auf dem letzten Bild stehen — ein
  /// Sterbender soll liegen bleiben, nicht wieder aufstehen.
  int frameAt(double time, {bool loop = true}) {
    final index = (time * fps).floor();
    if (loop) return index % frames;
    return index.clamp(0, frames - 1);
  }
}

/// Wie eine Art Gegner (oder der Held) aussieht.
///
/// **Die Bilder schauen nach rechts.** Nach links wird gespiegelt.
class Figure {
  const Figure({
    required this.strips,
    required this.frameSize,
    required this.footX,
    required this.footY,
    required this.topY,
    required this.scale,
    this.smooth = false,
    this.hover = 0,
  });

  /// Fehlt eine Pose, läuft [Pose.idle] — die kleinen Monster haben nur
  /// einen Streifen, und der reicht für alles.
  final Map<Pose, SpriteStrip> strips;

  /// Kantenlänge eines Bildes im Streifen.
  final double frameSize;

  /// Wo im Bild die Füsse stehen. Dort sitzt die Figur auf ihrem Schatten.
  final double footX;
  final double footY;

  /// Wo im Bild der Kopf anfängt.
  final double topY;

  /// Ganzzahlig, damit Pixelkunst scharf bleibt — ausser bei [smooth].
  final double scale;

  /// Ob das Bild **verkleinert** wird. Frederiks eigene Zeichnungen liegen
  /// als 256 × 256 vor (64 × 64 gezeichnet) und sind in der Grube kleiner
  /// als ein Viertel davon. Hart verkleinert fielen Bildpunkte weg, also
  /// weich — dieselbe Regel wie `PixelArt`.
  final bool smooth;

  /// Wie viele Punkte die Figur auf und ab schwebt. Wer fliegt und nur ein
  /// Bild hat, flattert so wenigstens.
  final double hover;

  SpriteStrip stripFor(Pose pose) => strips[pose] ?? strips[Pose.idle]!;

  bool has(Pose pose) => strips.containsKey(pose);

  /// Wie hoch die Figur ungefähr über ihren Füssen aufragt — für den
  /// Lebensbalken, der sonst im Kopf steckt.
  double get visibleHeight => (footY - topY) * scale;
}

/// Wer in der Grube wie aussieht.
///
/// **Eine Tabelle, eine Stelle** — wie `GearIcons` für den Laden. Die
/// Simulation kennt nur [EnemyKind]; welches Bild dazugehört, steht hier.
/// Die Bilder stammen aus Frederiks Download-Paket (siehe
/// `assets/Grube/HERKUNFT.md`).
abstract final class GrubeFiguren {
  static const String folder = 'assets/Grube';

  /// Der Soldat: sechs Streifen, Rahmen 100 × 100, die Figur selbst ist
  /// rund 17 × 21 Punkte gross und steht bei (50, 60).
  static const Figure held = Figure(
    strips: <Pose, SpriteStrip>{
      Pose.idle: SpriteStrip('Soldier_Idle.png', 6, fps: 8),
      Pose.walk: SpriteStrip('Soldier_Walk.png', 8, fps: 12),
      Pose.attack: SpriteStrip('Soldier_Attack01.png', 6, fps: 16),
      Pose.attack2: SpriteStrip('Soldier_Attack02.png', 6, fps: 16),
      Pose.hurt: SpriteStrip('Soldier_Hurt.png', 4, fps: 16),
      Pose.death: SpriteStrip('Soldier_Death.png', 4, fps: 8),
    },
    frameSize: 100,
    footX: 50,
    footY: 60,
    topY: 39,
    scale: 2,
  );

  /// Der Ork — breiter als der Held, steht bei (55, 57).
  static const Figure fussvolk = Figure(
    strips: <Pose, SpriteStrip>{
      Pose.idle: SpriteStrip('Orc_Idle.png', 6, fps: 8),
      Pose.walk: SpriteStrip('Orc_Walk.png', 8, fps: 12),
      Pose.attack: SpriteStrip('Orc_Attack01.png', 6, fps: 12),
      Pose.attack2: SpriteStrip('Orc_Attack02.png', 6, fps: 12),
      Pose.hurt: SpriteStrip('Orc_Hurt.png', 4, fps: 16),
      Pose.death: SpriteStrip('Orc_Death.png', 4, fps: 8),
    },
    frameSize: 100,
    footX: 55,
    footY: 57,
    topY: 42,
    scale: 2,
  );

  /// Das Blutauge schwebt: vier Bilder, 16 × 16. Es schiesst, also hält
  /// es Abstand — ein Auge liest sich sofort als „sieht dich von weitem".
  static const Figure schuetze = Figure(
    strips: <Pose, SpriteStrip>{
      Pose.idle: SpriteStrip('BloodshotEye.png', 4, fps: 6),
    },
    frameSize: 16,
    footX: 7.5,
    footY: 16,
    topY: 4,
    scale: 3,
  );

  /// Der Zyklop — derselbe Stil wie das Auge, aber viermal so gross wie
  /// das Fussvolk. Der Wächter soll man von weitem erkennen.
  static const Figure endgegner = Figure(
    strips: <Pose, SpriteStrip>{
      Pose.idle: SpriteStrip('CrushingCyclops.png', 4, fps: 5),
    },
    frameSize: 16,
    footX: 7.5,
    footY: 16,
    topY: 0,
    scale: 5,
  );

  /// Der Kobold — der Red Cap aus dem Paket. Kleiner als der Ork, damit
  /// man ihn im Rudel als das erkennt, was er ist: viele, schnell, schwach.
  ///
  /// Eine Fledermaus war gewünscht; das Paket hat keine. Kommt eine, ist
  /// es eine Zeile hier.
  static const Figure flink = Figure(
    strips: <Pose, SpriteStrip>{
      Pose.idle: SpriteStrip('RedCap.png', 4, fps: 10),
    },
    frameSize: 16,
    footX: 7.5,
    footY: 16,
    topY: 2,
    scale: 2,
  );

  /// Der Troll — der Stone Troll aus dem Paket. Grau und breit, damit er
  /// nicht mit dem rosa Wächter verwechselt wird; eine Stufe kleiner.
  static const Figure brocken = Figure(
    strips: <Pose, SpriteStrip>{
      Pose.idle: SpriteStrip('StoneTroll.png', 4, fps: 5),
    },
    frameSize: 16,
    footX: 7.5,
    footY: 16,
    topY: 0,
    scale: 4,
  );

  /// Die Fledermaus — Frederiks eigene Zeichnung, ein Bild, 256 × 256.
  /// Sie schwebt über ihrem Schatten und wippt dabei.
  static const Figure fledermaus = Figure(
    strips: <Pose, SpriteStrip>{Pose.idle: SpriteStrip('Fledermaus.png', 1)},
    frameSize: 256,
    footX: 130,
    footY: 256,
    topY: 32,
    scale: 0.16,
    smooth: true,
    hover: 4,
  );

  /// Der Stein — Frederiks Zeichnung, 256 × 256. Aus ihm sind die Wände
  /// der Grube gebaut, und der Wächter wirft ihn.
  static const String stein = 'Stein.png';

  /// Wo im Bild der Stein liegt; der Rest ist durchsichtig. Die Wand
  /// zeichnet nur diesen Ausschnitt, sonst stünden Lücken zwischen den
  /// Blöcken. `action_sprites_test.dart` misst ihn nach.
  static const Rect steinAusschnitt = Rect.fromLTRB(28, 64, 204, 224);

  static Figure forKind(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.keiner => held,
      EnemyKind.fussvolk => fussvolk,
      EnemyKind.schuetze => schuetze,
      EnemyKind.endgegner => endgegner,
      EnemyKind.flink => flink,
      EnemyKind.brocken => brocken,
      EnemyKind.flatterer => fledermaus,
    };
  }

  static const List<Figure> all = <Figure>[
    held,
    fussvolk,
    schuetze,
    endgegner,
    flink,
    brocken,
    fledermaus,
  ];

  /// Alle Dateien, die geladen werden müssen.
  static Set<String> get files => <String>{
    for (final figure in all)
      for (final strip in figure.strips.values) strip.file,
    stein,
  };
}

extension PoseTiming on Pose {
  /// Schläge und Treffer laufen einmal durch, alles andere in Schleife.
  bool get playsOnce =>
      this == Pose.attack || this == Pose.attack2 || this == Pose.hurt;
}

/// Welche Pose gilt — eine Regel, eine Stelle.
///
/// Ein Schlag schlägt alles, ein Treffer das Laufen. Sonst würde ein
/// getroffener Ork mitten im Schlag zurückzucken und der Schlag wäre nie
/// zu sehen.
Pose poseFor({
  required double attackLeft,
  required Pose attackPose,
  required double hurtLeft,
  required bool isMoving,
}) {
  if (attackLeft > 0) return attackPose;
  if (hurtLeft > 0) return Pose.hurt;
  if (isMoving) return Pose.walk;
  return Pose.idle;
}

/// Die geladenen Bilder der Grube.
class GrubeBilder {
  GrubeBilder._(this._images);

  final Map<String, ui.Image> _images;

  static Future<GrubeBilder>? _laden;

  /// Lädt einmal je App-Lauf. Ein neuer Lauf in der Grube bekommt
  /// dieselben Bilder, statt sie ein zweites Mal zu entpacken.
  static Future<GrubeBilder> load() {
    return _laden ??= _loadAll();
  }

  static Future<GrubeBilder> _loadAll() async {
    final images = <String, ui.Image>{};
    for (final file in GrubeFiguren.files) {
      final data = await rootBundle.load('${GrubeFiguren.folder}/$file');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      images[file] = (await codec.getNextFrame()).image;
    }
    return GrubeBilder._(images);
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  static final Paint _weich = Paint()..filterQuality = FilterQuality.medium;

  /// Zeichnet den Stein in [dst] — als Wandblock oder als Wurf.
  ///
  /// [rotation] dreht um die Mitte von [dst]; ein geworfener Brocken
  /// rollt.
  void drawStone(Canvas canvas, Rect dst, {double rotation = 0}) {
    final image = _images[GrubeFiguren.stein];
    if (image == null) return;
    if (rotation == 0) {
      canvas.drawImageRect(image, GrubeFiguren.steinAusschnitt, dst, _weich);
      return;
    }
    canvas.save();
    canvas.translate(dst.center.dx, dst.center.dy);
    canvas.rotate(rotation);
    canvas.drawImageRect(
      image,
      GrubeFiguren.steinAusschnitt,
      Rect.fromCenter(
        center: Offset.zero,
        width: dst.width,
        height: dst.height,
      ),
      _weich,
    );
    canvas.restore();
  }

  /// Zeichnet ein Bild der Figur so, dass ihre Füsse auf [foot] stehen.
  void draw(
    Canvas canvas, {
    required Figure figure,
    required Pose pose,
    required double time,
    required Offset foot,
    required bool faceLeft,
    bool loop = true,
    double opacity = 1,
    double sizeFactor = 1,
    double flash = 0,
  }) {
    final strip = figure.stripFor(pose);
    final image = _images[strip.file];
    if (image == null) return;

    final frame = strip.frameAt(time, loop: loop);
    final size = figure.frameSize;
    final src = Rect.fromLTWH(frame * size, 0, size, size);
    final scale = figure.scale * sizeFactor;

    // Schweben: ein ruhiges Auf und Ab, gut anderthalbmal je Sekunde.
    final schweben = figure.hover <= 0
        ? 0.0
        : figure.hover * (0.5 + 0.5 * math.sin(time * math.pi * 3));

    canvas.save();
    canvas.translate(foot.dx, foot.dy - schweben);
    if (faceLeft) canvas.scale(-1, 1);
    final dst = Rect.fromLTWH(
      -figure.footX * scale,
      -figure.footY * scale,
      size * scale,
      size * scale,
    );
    final guete = figure.smooth ? FilterQuality.medium : FilterQuality.none;
    final paint = opacity >= 1 && flash <= 0
        ? (figure.smooth ? _weich : _paint)
        : (Paint()
            ..filterQuality = guete
            ..color = Color.fromRGBO(255, 255, 255, opacity));
    canvas.drawImageRect(image, src, dst, paint);

    // Ein Treffer blitzt weiss auf — nur die Figur, nicht ihr Rahmen.
    if (flash > 0) {
      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..filterQuality = guete
          ..colorFilter = ColorFilter.mode(
            Color.fromRGBO(255, 255, 255, flash.clamp(0.0, 1.0)),
            BlendMode.srcATop,
          ),
      );
    }
    canvas.restore();
  }
}

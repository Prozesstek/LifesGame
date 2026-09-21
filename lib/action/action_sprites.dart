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

  /// Ganzzahlig, damit Pixelkunst scharf bleibt.
  final double scale;

  SpriteStrip stripFor(Pose pose) => strips[pose] ?? strips[Pose.idle]!;

  bool has(Pose pose) => strips.containsKey(pose);

  /// Wie hoch die Figur ungefähr über ihren Füssen aufragt — für den
  /// Lebensbalken, der sonst im Kopf steckt.
  double get visibleHeight => (footY - topY) * scale;
}

/// Wer in der Grube wie aussieht.
///
/// **Eine Tabelle, eine Stelle** — wie `EnemyIcons` für die Reihe. Die
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

  static Figure forKind(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.keiner => held,
      EnemyKind.fussvolk => fussvolk,
      EnemyKind.schuetze => schuetze,
      EnemyKind.endgegner => endgegner,
    };
  }

  static const List<Figure> all = <Figure>[held, fussvolk, schuetze, endgegner];

  /// Alle Dateien, die geladen werden müssen.
  static Set<String> get files => <String>{
    for (final figure in all)
      for (final strip in figure.strips.values) strip.file,
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

    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    if (faceLeft) canvas.scale(-1, 1);
    final dst = Rect.fromLTWH(
      -figure.footX * scale,
      -figure.footY * scale,
      size * scale,
      size * scale,
    );
    final paint = opacity >= 1 && flash <= 0
        ? _paint
        : (Paint()
            ..filterQuality = FilterQuality.none
            ..color = Color.fromRGBO(255, 255, 255, opacity));
    canvas.drawImageRect(image, src, dst, paint);

    // Ein Treffer blitzt weiss auf — nur die Figur, nicht ihr Rahmen.
    if (flash > 0) {
      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.none
          ..colorFilter = ColorFilter.mode(
            Color.fromRGBO(255, 255, 255, flash.clamp(0.0, 1.0)),
            BlendMode.srcATop,
          ),
      );
    }
    canvas.restore();
  }
}

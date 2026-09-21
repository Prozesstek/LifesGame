import 'dart:ui';

import 'package:action_combat/action_combat.dart';

import 'action_sprites.dart';

/// Was eine Figur gerade tut — abgeleitet aus Bewegung und Ereignissen.
///
/// **Anzeige, nicht Simulation.** Die Welt kennt weder Posen noch
/// Blickrichtung im Sinne eines Bildes; beides entsteht hier aus dem, was
/// sie ohnehin ausgibt. Deshalb liegt es in `lib/` und nicht in
/// `package:action_combat`.
class FigureState {
  FigureState(this._lastPosition, {required this.figure});

  /// Ab dieser Geschwindigkeit läuft jemand, darunter steht er.
  static const double walkThreshold = 12;

  /// Wie lange ein Treffer die Figur zucken lässt.
  static const double hurtTime = 0.22;

  final Figure figure;

  Vec2 _lastPosition;
  double _speed = 0;

  bool facesLeft = false;
  Pose pose = Pose.idle;
  double poseTime = 0;

  double _attackLeft = 0;
  Pose _attackPose = Pose.attack;
  double _hurtLeft = 0;

  /// Ein Schlag beginnt — auch mitten in einem laufenden, dann von vorn.
  void swing(Pose which) {
    _attackPose = which;
    _attackLeft = figure.stripFor(which).duration;
    pose = which;
    poseTime = 0;
  }

  void hit() => _hurtLeft = hurtTime;

  void update(EntityView view, double dt) {
    if (dt > 0) {
      final now = view.position.distanceTo(_lastPosition) / dt;
      // Geglättet, sonst flackert die Figur zwischen Laufen und Stehen,
      // wenn die Wegfindung einen Schritt lang zögert.
      _speed = _speed * 0.7 + now * 0.3;
    }
    _lastPosition = view.position;

    if (view.facing.x.abs() > 0.15) facesLeft = view.facing.x < 0;

    _attackLeft -= dt;
    _hurtLeft -= dt;

    final next = poseFor(
      attackLeft: _attackLeft,
      attackPose: _attackPose,
      hurtLeft: _hurtLeft,
      isMoving: _speed > walkThreshold,
    );
    if (next != pose) {
      pose = next;
      poseTime = 0;
    } else {
      poseTime += dt;
    }
  }
}

/// Ein Gefallener, der umkippt, kurz liegt und verblasst.
class FallenFigure {
  FallenFigure({
    required this.figure,
    required this.at,
    required this.facesLeft,
  });

  /// Wie lange er nach dem Umkippen noch liegt.
  static const double lieTime = 0.9;

  /// Wer keinen Sterbe-Streifen hat, schrumpft so lange weg.
  static const double shrinkTime = 0.35;

  final Figure figure;
  final Vec2 at;
  final bool facesLeft;
  double age = 0;

  double get duration =>
      (figure.has(Pose.death)
          ? figure.stripFor(Pose.death).duration
          : shrinkTime) +
      lieTime;

  double get progress => (age / duration).clamp(0.0, 1.0);

  /// Erst voll da, im letzten Drittel verblassen.
  double get opacity => progress < 0.66 ? 1 : (1 - progress) / 0.34;

  bool get isAlive => age < duration;

  /// Die Welt meldet den Mittelpunkt; gezeichnet wird auf den Füssen.
  Offset get foot => Offset(at.x, at.y + 8);
}

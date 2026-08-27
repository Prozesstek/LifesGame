import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Welche Haltung die Figur gerade einnimmt.
///
/// Die Haltung sagt nichts über Spielregeln — sie ist reine Darstellung.
/// Welcher Move welche Haltung auslöst, entscheidet `move_animation.dart`.
enum Pose {
  /// Ruhe. Atmet leicht.
  idle,

  /// Bogen gespannt, Zielarm nach vorn.
  aiming,

  /// Ausfallschritt nach vorn — für alles im Nahkampf.
  lunging,

  /// Geduckt, Arme vor dem Körper.
  bracing,
}

/// Eine Kampffigur: ein grauer Mensch aus Grundformen.
///
/// **Bewusst ohne Bilddateien.** Kopf, Rumpf, Arme und Beine sind
/// gezeichnet, nicht geladen. Das hält den Kampf ohne Assets lauffähig und
/// lässt jede Haltung aus Zahlen entstehen statt aus Einzelbildern. Rive
/// ersetzt das später; die Schnittstelle (`aimBow`, `takeHit`, …) bleibt
/// dieselbe.
///
/// Diese Klasse **rechnet nichts** (ADR-0002). Sie kennt keine HP, keinen
/// Schaden und keine Regeln — nur Haltungen und Zeit.
class Fighter extends PositionComponent {
  Fighter({required this.tint, required this.facesRight})
    : super(size: Vector2(58, 112), anchor: Anchor.bottomCenter);

  /// Der Grauton der Figur. Beide Seiten sind grau; der Unterschied ist
  /// die Helligkeit, nicht die Farbe.
  final Color tint;

  final bool facesRight;

  /// Ruheposition auf der X-Achse. Jede Bewegung kehrt hierher zurück.
  double homeX = 0;

  Pose _pose = Pose.idle;

  /// Läuft von 1 auf 0 und treibt die jeweilige Haltung.
  double _poseTime = 0;

  double _lunge = 0;
  double _flash = 0;
  double _shield = 0;
  double _recoil = 0;
  double _bob = 0;
  Color _flashColor = const Color(0xFFFFFFFF);
  bool _down = false;

  double get _direction => facesRight ? 1 : -1;

  // --- Was die Darstellung von außen auslöst ---

  /// Spannt den Bogen. Bleibt gespannt, bis [releaseBow] kommt.
  void aimBow() {
    _pose = Pose.aiming;
    _poseTime = 1;
  }

  /// Löst den Schuss: Der Zielarm schnellt zurück.
  void releaseBow() {
    _recoil = 1;
    _pose = Pose.idle;
    _poseTime = 0;
  }

  void lunge() {
    _pose = Pose.lunging;
    _lunge = 1;
  }

  void brace() {
    _pose = Pose.bracing;
    _poseTime = 1;
  }

  void takeHit({bool strong = false}) {
    _flash = strong ? 1.4 : 1;
    _recoil = strong ? 1.2 : 0.7;
    _flashColor = const Color(0xFFFFFFFF);
  }

  void glow(Color color) {
    _flash = 1;
    _flashColor = color;
  }

  void pulseShield() => _shield = 1;

  void fall() => _down = true;

  void reset() {
    _down = false;
    _pose = Pose.idle;
    _poseTime = 0;
    _lunge = 0;
    _flash = 0;
    _shield = 0;
    _recoil = 0;
  }

  /// Wo ein Pfeil die Figur verlässt — Höhe der vorderen Hand.
  Vector2 get handAnchor => _worldPointOf(Vector2(size.x * 0.78, 38));

  /// Wo ein Geschoss einschlägt — Brustmitte.
  Vector2 get chestAnchor => _worldPointOf(Vector2(size.x * 0.5, 44));

  /// Wo Schadens- und Heilungszahlen erscheinen — über dem Kopf.
  ///
  /// Bewusst mittig statt an der Trefferstelle: Die Zahl gehört zur
  /// Figur, nicht zur Wunde, und über dem Kopf steht sie bei jeder
  /// Blickrichtung an derselben Stelle.
  Vector2 get headAnchor => _worldPointOf(Vector2(size.x * 0.5, -10));

  Vector2 _worldPointOf(Vector2 local) {
    final x = facesRight ? local.x : size.x - local.x;
    return Vector2(position.x - size.x / 2 + x, position.y - size.y + local.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _bob += dt;
    _poseTime = (_poseTime - dt * 0.9).clamp(0, 1);
    _lunge = (_lunge - dt * 3.0).clamp(0, 2);
    _flash = (_flash - dt * 2.6).clamp(0, 2);
    _shield = (_shield - dt * 2.0).clamp(0, 2);
    _recoil = (_recoil - dt * 4.5).clamp(0, 2);

    if (_poseTime == 0 && _pose != Pose.lunging) _pose = Pose.idle;

    // Ausfallschritt nach vorn, dann zurück. Quadratisch, damit der
    // Antritt schnell und die Rückkehr weich wirkt.
    final step = _lunge * _lunge * 30 * _direction;
    final knock = -_recoil * 9 * _direction;
    position.x = homeX + step + knock;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    if (_down) {
      // Umfallen: kippen statt plattdrücken — das liest sich als Sturz.
      canvas.translate(size.x / 2, size.y);
      canvas.rotate(_direction * math.pi / 2 * 0.92);
      canvas.translate(-size.x / 2, -size.y);
    }

    if (!facesRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    _drawBody(canvas);

    canvas.restore();
  }

  void _drawBody(Canvas canvas) {
    final color = _flash > 0
        ? Color.lerp(tint, _flashColor, (_flash * 0.75).clamp(0, 1))!
        : tint;
    final body = Paint()..color = color;
    final dark = Paint()..color = _darken(color, 0.22);

    final breathe = _down ? 0.0 : math.sin(_bob * 2.4) * 1.2;
    final aim = _pose == Pose.aiming ? 0.85 + _poseTime * 0.15 : 0.0;
    final brace = _pose == Pose.bracing ? _poseTime : 0.0;
    final crouch = brace * 6;

    final cx = size.x / 2;
    final headY = 16.0 + breathe + crouch;
    final hipY = 70.0 + crouch;
    final shoulderY = 36.0 + breathe + crouch;

    // Beine
    _limb(canvas, dark, Offset(cx - 5, hipY), Offset(cx - 9, 108), 7);
    _limb(
      canvas,
      dark,
      Offset(cx + 5, hipY),
      Offset(cx + 10 + _lunge * 6, 108),
      7,
    );

    // Rumpf
    canvas.drawRRect(
      RRect.fromLTRBR(
        cx - 11,
        28 + breathe + crouch,
        cx + 11,
        hipY + 4,
        const Radius.circular(8),
      ),
      body,
    );

    // Kopf
    canvas.drawCircle(Offset(cx + 1, headY), 10, body);

    // Arme. Ihre Haltung ist das, was einen Bogenschützen ausmacht.
    if (aim > 0) {
      _drawBow(canvas, cx, shoulderY, aim, body);
    } else if (brace > 0) {
      _limb(canvas, body, Offset(cx - 6, shoulderY), Offset(cx + 6, 58), 6);
      _limb(canvas, body, Offset(cx + 6, shoulderY), Offset(cx + 12, 62), 6);
    } else {
      final swing = _lunge * 16;
      _limb(
        canvas,
        body,
        Offset(cx - 4, shoulderY),
        Offset(cx - 10, 64 - breathe),
        6,
      );
      _limb(
        canvas,
        body,
        Offset(cx + 6, shoulderY),
        Offset(cx + 12 + swing, 60 - swing * 0.7),
        6,
      );
    }

    if (_shield > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(cx - 20, 10, cx + 20, 110, const Radius.circular(20)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(
            0xFF7FD4FF,
          ).withValues(alpha: _shield.clamp(0, 1)),
      );
    }
  }

  /// Zielarm nach vorn, Zugarm zur Wange, dazu der Bogen selbst.
  void _drawBow(
    Canvas canvas,
    double cx,
    double shoulderY,
    double aim,
    Paint body,
  ) {
    final reach = 22.0 * aim;
    final hand = Offset(cx + 8 + reach, shoulderY + 2);

    _limb(canvas, body, Offset(cx + 6, shoulderY), hand, 6);
    _limb(
      canvas,
      body,
      Offset(cx - 4, shoulderY),
      Offset(cx + 2, shoulderY - 4),
      6,
    );

    final bow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC89B5B);

    canvas.drawArc(
      Rect.fromCenter(center: hand, width: 24 * aim, height: 52 * aim),
      -math.pi / 2.2,
      math.pi * 1.1,
      false,
      bow,
    );

    final string = Paint()
      ..strokeWidth = 1.4
      ..color = const Color(0xFFE8E2D4);
    final top = Offset(hand.dx, hand.dy - 25 * aim);
    final bottom = Offset(hand.dx, hand.dy + 25 * aim);
    final nock = Offset(hand.dx - 12 * aim, hand.dy);
    canvas.drawLine(top, nock, string);
    canvas.drawLine(nock, bottom, string);

    // Der aufgelegte Pfeil, solange gespannt wird.
    canvas.drawLine(
      nock,
      Offset(hand.dx + 12 * aim, hand.dy),
      Paint()
        ..strokeWidth = 2
        ..color = const Color(0xFFD8CFC0),
    );
  }

  void _limb(
    Canvas canvas,
    Paint source,
    Offset from,
    Offset to,
    double width,
  ) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = source.color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  Color _darken(Color color, double amount) {
    return Color.lerp(color, const Color(0xFF000000), amount)!;
  }
}

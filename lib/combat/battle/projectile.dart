import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ein Geschoss, das von einem Punkt zum anderen fliegt und sich danach
/// selbst entfernt.
///
/// **Der Pfeil entscheidet nichts.** Der Kampf ist längst ausgerechnet,
/// wenn er losfliegt — das Ergebnis steht in den Events, die die Engine
/// geliefert hat (ADR-0002). Er ist ein Bild, das zur richtigen Zeit an der
/// richtigen Stelle ist, mehr nicht.
///
/// [onArrive] gibt es für den Fall, dass später etwas am Einschlag hängen
/// soll (ein Funke, ein Geräusch). Das Zucken des Getroffenen hängt
/// **nicht** daran, sondern an derselben Zeitachse wie der Abschuss.
class Projectile extends PositionComponent {
  Projectile({
    required Vector2 from,
    required Vector2 to,
    this.onArrive,
    this.flightTime = 0.36,
    this.arc = 26,
    this.color = const Color(0xFFD8CFC0),
  }) : _from = from.clone(),
       _to = to.clone(),
       super(position: from.clone(), anchor: Anchor.center, priority: 10);

  final Vector2 _from;
  final Vector2 _to;

  /// Wird höchstens einmal aufgerufen, wenn das Geschoss ankommt.
  final VoidCallback? onArrive;

  /// Wie lange der Flug dauert. Kurz genug, dass eine Runde flüssig
  /// bleibt, lang genug, dass man ihn sieht.
  final double flightTime;

  /// Höhe des Bogens. 0 wäre eine gerade Linie und sähe aus wie ein Strich.
  final double arc;

  final Color color;

  double _t = 0;
  bool _arrived = false;

  @override
  void update(double dt) {
    super.update(dt);

    _t = (_t + dt / flightTime).clamp(0, 1);

    final flat = _from + (_to - _from) * _t;
    final lift = math.sin(_t * math.pi) * arc;
    final next = Vector2(flat.x, flat.y - lift);

    // Die Neigung ergibt sich aus der tatsächlichen Bewegung, nicht aus
    // einer Formel -- damit zeigt die Spitze am Scheitel wirklich waagerecht.
    final delta = next - position;
    if (delta.length2 > 0.0001) angle = math.atan2(delta.y, delta.x);
    position = next;

    if (_t >= 1 && !_arrived) {
      _arrived = true;
      onArrive?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Schaft
    canvas.drawLine(
      const Offset(-14, 0),
      const Offset(10, 0),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Spitze
    final head = Path()
      ..moveTo(16, 0)
      ..lineTo(8, -3.5)
      ..lineTo(8, 3.5)
      ..close();
    canvas.drawPath(head, Paint()..color = const Color(0xFFEDE7DA));

    // Befiederung
    final fletch = Paint()
      ..color = const Color(0xFF8C7B5F)
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(-14, 0), const Offset(-9, -4), fletch);
    canvas.drawLine(const Offset(-14, 0), const Offset(-9, 4), fletch);
  }
}

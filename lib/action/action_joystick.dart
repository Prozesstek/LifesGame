import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Das Steuerkreuz — es entsteht dort, wo der Daumen aufsetzt.
///
/// **Kein fester Kreis in der Ecke.** Auf einem Handy im Hochformat
/// greift jeder anders zu, und ein Kreis an einer festen Stelle zwingt
/// die Hand dorthin. Wer irgendwo aufsetzt, bekommt sein Kreuz dort —
/// dieselbe Lösung, die mobile Actionspiele durchweg verwenden.
///
/// Es liegt über dem ganzen Spielfeld, nicht nur über der unteren Hälfte:
/// Im Eifer trifft man einen abgegrenzten Bereich nicht. Angegriffen wird
/// ohnehin von selbst, also gibt es keine zweite Geste, mit der es sich
/// beissen könnte.
class ActionJoystick extends StatefulWidget {
  const ActionJoystick({required this.onChanged, super.key});

  /// Die Richtung, Länge höchstens 1. [Vec2.zero] heisst „steh".
  final ValueChanged<Vec2> onChanged;

  /// Ab wie vielen Pixeln Auslenkung die Figur losläuft. Darunter ist es
  /// ein Wackeln der Hand, keine Absicht.
  static const double deadZone = 8;

  /// Bei wie viel Auslenkung volles Tempo erreicht ist.
  static const double radius = 56;

  @override
  State<ActionJoystick> createState() => _ActionJoystickState();
}

class _ActionJoystickState extends State<ActionJoystick> {
  Offset? _base;
  Offset _knob = Offset.zero;

  void _update(Offset local) {
    final base = _base;
    if (base == null) return;

    final delta = local - base;
    final laenge = delta.distance;
    final begrenzt = laenge > ActionJoystick.radius
        ? delta * (ActionJoystick.radius / laenge)
        : delta;

    setState(() => _knob = begrenzt);

    if (laenge < ActionJoystick.deadZone) {
      widget.onChanged(Vec2.zero);
      return;
    }
    final anteil = math.min(1.0, laenge / ActionJoystick.radius);
    final richtung = Vec2(delta.dx / laenge, delta.dy / laenge);
    widget.onChanged(richtung * anteil);
  }

  void _end() {
    setState(() {
      _base = null;
      _knob = Offset.zero;
    });
    widget.onChanged(Vec2.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (details) {
        setState(() {
          _base = details.localPosition;
          _knob = Offset.zero;
        });
      },
      onPanUpdate: (details) => _update(details.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: CustomPaint(
        painter: _JoystickPainter(base: _base, knob: _knob),
        size: Size.infinite,
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  const _JoystickPainter({required this.base, required this.knob});

  final Offset? base;
  final Offset knob;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = base;
    if (mitte == null) return;

    canvas.drawCircle(
      mitte,
      ActionJoystick.radius,
      Paint()..color = Palette.textOnDark.withValues(alpha: 0.13),
    );
    canvas.drawCircle(
      mitte,
      ActionJoystick.radius,
      Paint()
        ..color = Palette.textOnDark.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      mitte + knob,
      20,
      Paint()..color = Palette.goldOnDark.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) {
    return old.base != base || old.knob != knob;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Etwas, das sich gerade wählen lässt, wackelt kurz und behält danach
/// einen goldenen Rand (Issue #138: „Dabei shaken die Fähigkeiten dann
/// leicht, damit der Nutzer erkennt, dass er was auswählen kann“).
///
/// **Das Wackeln endet von selbst** nach [mal] Schwüngen; der Rand
/// bleibt, solange [aktiv] gilt. Eine Bewegung ohne Ende liesse
/// `pumpAndSettle` nie zur Ruhe kommen (`gotchas.md`), und dauernd
/// wackelnde Kacheln wären unruhig.
class Wackeln extends StatefulWidget {
  const Wackeln({
    required this.aktiv,
    required this.child,
    this.radius = 10,
    super.key,
  });

  final bool aktiv;
  final Widget child;
  final double radius;

  /// Wie oft es hin und her geht.
  static const int mal = 4;

  /// Wie weit es sich dreht, im Bogenmaß — rund zwei Grad.
  static const double ausschlag = 0.035;

  static const Duration dauer = Duration(milliseconds: 720);

  @override
  State<Wackeln> createState() => _WackelnState();
}

class _WackelnState extends State<Wackeln> with SingleTickerProviderStateMixin {
  late final AnimationController _takt;

  @override
  void initState() {
    super.initState();
    _takt = AnimationController(vsync: this, duration: Wackeln.dauer);
    if (widget.aktiv) _starte();
  }

  @override
  void didUpdateWidget(Wackeln alt) {
    super.didUpdateWidget(alt);
    if (widget.aktiv && !alt.aktiv) _starte();
    if (!widget.aktiv) _takt.value = 0;
  }

  void _starte() {
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (ruhig) return;
    _takt.forward(from: 0);
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rand = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.aktiv
            ? Border.all(color: Palette.goldOnDark, width: 2.5)
            : null,
      ),
      child: widget.child,
    );
    return AnimatedBuilder(
      animation: _takt,
      builder: (context, child) {
        // Eine Sinuswelle, die zum Ende hin ausklingt.
        final t = _takt.value;
        final winkel =
            math.sin(t * Wackeln.mal * 2 * math.pi) *
            Wackeln.ausschlag *
            (1 - t);
        return Transform.rotate(angle: winkel, child: child);
      },
      child: rand,
    );
  }
}

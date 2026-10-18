import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/palette.dart';
import '../../ui/sprung.dart';

/// **Der Kreis, der beim Abhaken aufspringt** — eine Stelle für die Kachel
/// auf dem Gewohnheiten-Bildschirm und die Zeile in „Heute“.
///
/// Bis zum 18.10. blendete das Häkchen in 220 ms ein und wuchs dabei ein
/// wenig. Jetzt springt es wie bei Duolingo: Der grüne Kreis schiesst
/// über seine Grösse hinaus und pendelt zurück, dahinter blitzt es, ein
/// Ring läuft nach aussen, acht Striche fliegen weg.
///
/// **Nur beim Setzen.** Wer ein Häkchen zurücknimmt, hat sich vertan —
/// das soll still passieren. Und nur, wenn es *gesetzt wird*: Ein
/// Bildschirm, der ein schon erledigtes zeigt, springt nicht.
///
/// Das Zeichen bleibt ein [Icon] (`check_circle`, `radio_button_unchecked`),
/// damit Tests und Vorleser es finden wie vorher. Der Sprung malt sich
/// über den eigenen Rand hinaus; die Karten darum schneiden nicht ab.
class HaekchenKreis extends StatefulWidget {
  const HaekchenKreis({
    required this.isChecked,
    required this.size,
    this.offenFarbe = Palette.muted,
    super.key,
  });

  final bool isChecked;
  final double size;

  /// Die Farbe des offenen Kreises — die Akzentfarbe, wenn er dran ist.
  final Color offenFarbe;

  /// Wie lange der Sprung dauert. Der Kreis steht nach gut einem Drittel;
  /// der Rest ist Auspendeln, das man fühlt, aber nicht abwartet.
  static const Duration dauer = Duration(milliseconds: 650);

  @override
  State<HaekchenKreis> createState() => _HaekchenKreisState();
}

class _HaekchenKreisState extends State<HaekchenKreis>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sprung;

  @override
  void initState() {
    super.initState();
    _sprung = AnimationController(
      vsync: this,
      duration: HaekchenKreis.dauer,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(HaekchenKreis alt) {
    super.didUpdateWidget(alt);
    if (!alt.isChecked && widget.isChecked) _sprung.forward(from: 0);
    if (alt.isChecked && !widget.isChecked) _sprung.value = 1;
  }

  @override
  void dispose() {
    _sprung.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zeichen = Icon(
      widget.isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
      size: widget.size,
      color: widget.isChecked ? Palette.success : widget.offenFarbe,
    );
    return AnimatedBuilder(
      animation: _sprung,
      child: zeichen,
      builder: (context, child) {
        final t = _sprung.value;
        return CustomPaint(
          painter: t < 1 ? HaekchenSprungMaler(t) : null,
          child: Transform.scale(scale: Sprung.feder(t), child: child),
        );
      },
    );
  }
}

/// Blitz, Ring und Striche hinter dem springenden Kreis.
///
/// Öffentlich, damit ein Test fragen kann, ob gerade gesprungen wird.
class HaekchenSprungMaler extends CustomPainter {
  const HaekchenSprungMaler(this.t);

  /// Wie weit der Sprung ist, 0 bis 1.
  final double t;

  /// Wie viele Striche wegfliegen.
  static const int striche = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Ein grüner Schein, der sich ausdehnt und vergeht.
    final blitz = Sprung.vergeht(t, 0.35);
    if (blitz > 0) {
      canvas.drawCircle(
        mitte,
        r * (1 + 0.6 * (1 - blitz)),
        Paint()..color = Palette.successOnDark.withValues(alpha: 0.5 * blitz),
      );
    }

    // Der Ring läuft nach aussen und wird dabei dünner.
    final ring = Sprung.vergeht(t, 0.5);
    if (ring > 0) {
      final weg = Curves.easeOutCubic.transform(1 - ring);
      canvas.drawCircle(
        mitte,
        r * (1 + 0.85 * weg),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 + 2.6 * ring
          ..color = Palette.success.withValues(alpha: ring),
      );
    }

    // Acht Striche fliegen weg, abwechselnd grün und gold, schräg zum
    // Kreuz versetzt — sonst läsen sie sich als Fadenkreuz.
    final flug = Sprung.abschnitt(t, 0.04, 0.6);
    if (flug <= 0 || flug >= 1) return;
    final weit = Curves.easeOutCubic.transform(flug);
    final innen = r * (1.15 + 0.75 * weit);
    final laenge = r * 0.5 * (1 - flug);
    for (var i = 0; i < striche; i++) {
      final winkel = i * 2 * math.pi / striche + math.pi / striche;
      final richtung = Offset(math.cos(winkel), math.sin(winkel));
      canvas.drawLine(
        mitte + richtung * innen,
        mitte + richtung * (innen + laenge),
        Paint()
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = (i.isEven ? Palette.success : Palette.gold).withValues(
            alpha: 1 - flug * 0.6,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(HaekchenSprungMaler alt) => alt.t != t;
}

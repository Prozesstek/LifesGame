import 'package:combat/combat.dart';
import 'package:flutter/material.dart';

/// Der Timed Hit als Eingabe: ein Marker läuft über die Leiste, der Spieler
/// tippt möglichst mittig.
///
/// Diese Leiste **misst** nur. Was der Treffer wert ist, entscheidet die
/// Kampflogik anhand von [TimedHit] (ADR-0002) — und wie schwer er zu
/// treffen ist, steht in [spec], das aus `package:combat` kommt. Hier
/// werden weder Zonen noch Geschwindigkeiten festgelegt.
class TimingBar extends StatefulWidget {
  const TimingBar({
    required this.onResult,
    this.spec = TimingSpec.standard,
    this.hits = 1,
    super.key,
  });

  /// Wird aufgerufen, wenn **alle** Tipps abgegeben sind.
  final ValueChanged<List<TimedHit>> onResult;

  /// Geschwindigkeit und Fensterbreite dieses Zuges.
  final TimingSpec spec;

  /// Wie oft getippt werden muss. Klingenwirbel hat drei.
  final int hits;

  /// Dauer eines Durchlaufs bei Geschwindigkeit 1,0.
  static const Duration baseSweep = Duration(milliseconds: 1150);

  @override
  TimingBarState createState() => TimingBarState();
}

/// Der Zustand ist **öffentlich**, damit der Kampfbildschirm ihn über
/// einen `GlobalKey` auslösen kann.
///
/// Grund: Getippt werden soll überall, nicht nur auf der Leiste. Die
/// Bewertung muss aber genau in dem Moment passieren, in dem der Tipp
/// kommt — der Marker steht ja nie still. Die Position nach außen zu
/// reichen hieße, sie einen Frame zu früh oder zu spät zu lesen.
class TimingBarState extends State<TimingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Die bisher abgegebenen Tipps. Bei [TimingBar.hits] ist Schluss.
  final List<TimedHit> _results = <TimedHit>[];

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _sweepDuration)
      ..repeat(reverse: true);
  }

  /// Ein schnellerer Marker heißt: dieselbe Strecke in kürzerer Zeit.
  Duration get _sweepDuration {
    final ms = TimingBar.baseSweep.inMilliseconds / widget.spec.speed;
    return Duration(milliseconds: ms.round());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Nimmt einen Tipp entgegen und wertet die Position aus.
  ///
  /// **Es gibt keine Frist.** Der Marker läuft hin und her, bis getippt
  /// wird. Ein Zeitlimit hätte den Zug für den Spieler entschieden — und
  /// zwar mit dem schlechtestmöglichen Ergebnis, ohne dass er etwas getan
  /// hätte. Wer wartet, verliert hier nichts als Zeit.
  void lockIn() {
    if (_done) return;

    _results.add(_judge(_controller.value));

    if (_results.length < widget.hits) {
      // Nächster Tipp: Der Marker springt an den Anfang zurück, damit
      // jeder Treffer dieselbe Ausgangslage hat. Ohne den Sprung wäre der
      // zweite Tipp reine Glückssache — der Marker stünde da, wo der
      // erste ihn erwischt hat.
      setState(() {
        _controller
          ..reset()
          ..repeat(reverse: true);
      });
      return;
    }

    _done = true;
    _controller.stop();
    widget.onResult(List<TimedHit>.unmodifiable(_results));
  }

  TimedHit _judge(double position) {
    // Die Fenster der Vorlage sind über die **ganze** Breite gemessen,
    // die Entfernung hier ab der Mitte — deshalb die Halbierung.
    final distance = (position - 0.5).abs();
    if (distance <= widget.spec.perfectWindow / 2) return TimedHit.perfect;
    if (distance <= widget.spec.goodWindow / 2) return TimedHit.good;
    return TimedHit.none;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.hits - _results.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: lockIn,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            widget.hits > 1 ? 'TIPPEN — NOCH $remaining' : 'JETZT TIPPEN',
            style: const TextStyle(
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD166),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _TimingPainter(
                    position: _controller.value,
                    spec: widget.spec,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingPainter extends CustomPainter {
  const _TimingPainter({required this.position, required this.spec});

  final double position;
  final TimingSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFF232838));

    /// [width] ist die Breite der Zone über die ganze Leiste.
    void zone(double width, Color color) {
      final half = width / 2;
      final rect = Rect.fromLTRB(
        size.width * (0.5 - half),
        0,
        size.width * (0.5 + half),
        size.height,
      );
      canvas.drawRect(rect, Paint()..color = color);
    }

    zone(spec.goodWindow, const Color(0xFF35506B));
    zone(spec.perfectWindow, const Color(0xFF4E8C5A));

    final x = size.width * position;
    canvas.drawRect(
      Rect.fromLTWH(x - 2, -3, 4, size.height + 6),
      Paint()..color = const Color(0xFFFFD166),
    );
  }

  @override
  bool shouldRepaint(_TimingPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.spec != spec;
}

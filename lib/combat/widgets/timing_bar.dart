import 'package:combat/combat.dart';
import 'package:flutter/material.dart';

/// Der Timed Hit als Eingabe: ein Marker läuft über die Leiste, der Spieler
/// tippt möglichst mittig.
///
/// Diese Leiste **misst** nur. Was der Treffer wert ist, entscheidet die
/// Kampflogik anhand von [TimedHit] (ADR-0002).
class TimingBar extends StatefulWidget {
  const TimingBar({required this.onResult, super.key});

  final ValueChanged<TimedHit> onResult;

  /// Halbe Breite der Zonen, gemessen als Abstand von der Mitte (0..0.5).
  static const double perfectZone = 0.06;
  static const double goodZone = 0.17;

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
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Nimmt den Tipp entgegen und wertet die Position aus.
  ///
  /// **Es gibt keine Frist.** Der Marker läuft hin und her, bis getippt
  /// wird. Ein Zeitlimit hätte den Zug für den Spieler entschieden — und
  /// zwar mit dem schlechtestmöglichen Ergebnis, ohne dass er etwas getan
  /// hätte. Wer wartet, verliert hier nichts als Zeit.
  void lockIn() {
    if (_locked) return;
    _locked = true;
    _controller.stop();

    widget.onResult(_judge(_controller.value));
  }

  TimedHit _judge(double position) {
    final distance = (position - 0.5).abs();
    if (distance <= TimingBar.perfectZone) return TimedHit.perfect;
    if (distance <= TimingBar.goodZone) return TimedHit.good;
    return TimedHit.none;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: lockIn,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'JETZT TIPPEN',
            style: TextStyle(
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
                  painter: _TimingPainter(_controller.value),
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
  const _TimingPainter(this.position);

  final double position;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFF232838));

    void zone(double halfWidth, Color color) {
      final rect = Rect.fromLTRB(
        size.width * (0.5 - halfWidth),
        0,
        size.width * (0.5 + halfWidth),
        size.height,
      );
      canvas.drawRect(rect, Paint()..color = color);
    }

    zone(TimingBar.goodZone, const Color(0xFF35506B));
    zone(TimingBar.perfectZone, const Color(0xFF4E8C5A));

    final x = size.width * position;
    canvas.drawRect(
      Rect.fromLTWH(x - 2, -3, 4, size.height + 6),
      Paint()..color = const Color(0xFFFFD166),
    );
  }

  @override
  bool shouldRepaint(_TimingPainter oldDelegate) =>
      oldDelegate.position != position;
}

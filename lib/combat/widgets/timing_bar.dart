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
  State<TimingBar> createState() => _TimingBarState();
}

class _TimingBarState extends State<TimingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();
    _controller.addStatusListener((status) {
      // Nicht getippt heißt danebengegriffen.
      if (status == AnimationStatus.completed) _lockIn(force: TimedHit.none);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _lockIn({TimedHit? force}) {
    if (_locked) return;
    _locked = true;
    _controller.stop();

    final result = force ?? _judge(_controller.value);
    widget.onResult(result);
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
      onTap: _lockIn,
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

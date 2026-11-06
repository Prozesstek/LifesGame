import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// **Was man jetzt antippen soll, pulsiert** (06.11.2026, Frederik: „die
/// Gewohnheit … blinken/hervorheben, dass es ersichtlich ist, dass es
/// abhakbar/anklickbar ist“): ein goldener Schein, der atmet, und ein
/// Hauch größer im Takt.
///
/// **Ohne Ende, solange [aktiv] gilt** — anders als `PlatzLaedtEin`, das
/// dreimal leuchtet: Hier wartet der ganze Bildschirm auf diesen einen
/// Tipp. In Tests steht es still ([pulsiert], `flutter_test_config.dart`),
/// sonst käme `pumpAndSettle` nie zur Ruhe. Wer Bewegung abgeschaltet hat,
/// sieht den Schein ohne Atmen.
///
/// **Die Hülle bleibt immer stehen** und schaltet nur ab (`gotchas.md`):
/// Sonst baute sich das Kind beim Abhaken neu, und sein Häkchen spränge
/// nicht auf.
class Pulsieren extends StatefulWidget {
  const Pulsieren({
    required this.aktiv,
    required this.child,
    this.radius = 6,
    this.verzoegerung = Duration.zero,
    super.key,
  });

  final bool aktiv;
  final Widget child;
  final double radius;

  /// Wie lange es wartet, bevor es zu atmen beginnt — bis das Ziel
  /// hereingeflogen ist (`DerReiheNach.fertigNach`).
  final Duration verzoegerung;

  /// Ein Atemzug.
  static const Duration takt = Duration(milliseconds: 1100);

  /// Wie viel größer es auf dem Höhepunkt ist.
  static const double wachsen = 0.03;

  /// Aus in Tests (`test/flutter_test_config.dart`).
  static bool pulsiert = true;

  @override
  State<Pulsieren> createState() => _PulsierenState();
}

class _PulsierenState extends State<Pulsieren>
    with SingleTickerProviderStateMixin {
  // In `initState` angelegt, nicht faul (`gotchas.md`).
  late final AnimationController _takt;
  bool _wartet = false;

  @override
  void initState() {
    super.initState();
    _takt = AnimationController(vsync: this, duration: Pulsieren.takt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stelle();
  }

  @override
  void didUpdateWidget(Pulsieren alt) {
    super.didUpdateWidget(alt);
    if (alt.aktiv != widget.aktiv) _stelle();
  }

  void _stelle() {
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.aktiv && Pulsieren.pulsiert && !ruhig) {
      if (_takt.isAnimating || _wartet) return;
      if (widget.verzoegerung == Duration.zero) {
        _takt.repeat();
        return;
      }
      // Nur außerhalb von Tests (dort pulsiert nichts), also kein
      // Zeitgeber, der einen Test überdauert.
      _wartet = true;
      Future<void>.delayed(widget.verzoegerung, () {
        _wartet = false;
        if (mounted && widget.aktiv && !_takt.isAnimating) _takt.repeat();
      });
    } else {
      _takt
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // **Eigene Ebene**: Was ohne Ende läuft, malt sonst in jedem Bild den
    // ganzen Bildschirm um sich neu (`gotchas.md`).
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _takt,
        child: widget.child,
        builder: (context, kind) {
          // 0 bis 1 und zurück, weich. Abgeschaltet bleibt der Baum
          // derselbe, nur ohne Schein und ohne Wachsen.
          final an = widget.aktiv;
          final t = an ? 0.5 - 0.5 * math.cos(2 * math.pi * _takt.value) : 0.0;
          return Transform.scale(
            scale: 1 + Pulsieren.wachsen * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Palette.accentOnDark.withValues(
                      alpha: an ? 0.45 + 0.4 * t : 0,
                    ),
                    blurRadius: 10 + 10 * t,
                    spreadRadius: 1 + 2 * t,
                  ),
                ],
              ),
              position: DecorationPosition.background,
              child: kind,
            ),
          );
        },
      ),
    );
  }
}

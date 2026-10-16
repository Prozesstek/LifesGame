import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../gear/widgets/rarity_badge.dart';

/// Wie tief eine Ebene ist — und damit, in welcher Farbe der Schlund
/// glüht.
///
/// **Die Farbe sagt, was unten fallen kann.** Ab [GearGates.epicRung]
/// gibt es Episches, also glüht es violett; ab [GearGates.legendaryRung]
/// Legendäres, also golden — dieselben Töne wie am Rand eines Stücks
/// (`RarityBadge.rahmenOf`). Jenseits des alten Endes
/// ([PitStage.referenceStage]) ist es keine Seltenheit mehr, sondern die
/// Tiefe selbst: blutrot.
enum GlutStufe {
  feuer,
  episch,
  legendaer,
  mythisch;

  static GlutStufe fuer(int ebene) {
    if (ebene > PitStage.referenceStage) return mythisch;
    if (ebene >= GearGates.legendaryRung) return legendaer;
    if (ebene >= GearGates.epicRung) return episch;
    return feuer;
  }

  Color get farbe => switch (this) {
    feuer => const Color(0xFFE8782A),
    episch => RarityBadge.rahmenOf(GearRarity.epic),
    legendaer => RarityBadge.rahmenOf(GearRarity.legendary),
    mythisch => const Color(0xFFE0283C),
  };

  /// Wie viel Glut aufsteigt. Je tiefer, desto mehr.
  int get funken => switch (this) {
    feuer => 10,
    episch => 14,
    legendaer => 18,
    mythisch => 26,
  };
}

/// Der Schlund im Eingang: ein dunkles Loch mit glühendem Rand, ein
/// Lichtschein, der atmet, und Glut, die aus der Tiefe steigt. Die Zahl
/// der Ebene steht davor ([child]).
///
/// **Nur Bild.** Er nimmt keinen Tipp an und rechnet nichts.
class EingangsGlut extends StatefulWidget {
  const EingangsGlut({super.key, required this.ebene, required this.child});

  final int ebene;
  final Widget child;

  /// Ob der Schlund für immer atmet. **In Tests nicht**
  /// (`test/flutter_test_config.dart`): Eine Animation ohne Ende lässt
  /// `pumpAndSettle` nie zur Ruhe kommen, und jeder Test, der den Eingang
  /// zeigt, liefe in die Zeitgrenze.
  static bool atmet = true;

  static const double hoehe = 250;

  /// Ein Durchlauf. Atem und Funken laufen in Teilern davon, damit der
  /// Übergang zum nächsten Durchlauf nicht springt.
  static const Duration _runde = Duration(seconds: 12);

  @override
  State<EingangsGlut> createState() => _EingangsGlutState();
}

class _EingangsGlutState extends State<EingangsGlut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _takt = AnimationController(
    vsync: this,
    duration: EingangsGlut._runde,
    // Ohne Atem steht das Bild auf einem schönen Augenblick, nicht auf
    // null, wo alle Funken unten kleben.
    value: 0.37,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wer Bewegung abgeschaltet hat, bekommt das stehende Bild.
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (EingangsGlut.atmet && !ruhig) {
      if (!_takt.isAnimating) _takt.repeat();
    } else {
      _takt.stop();
    }
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stufe = GlutStufe.fuer(widget.ebene);
    return SizedBox(
      height: EingangsGlut.hoehe,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _takt,
                  builder: (context, _) => CustomPaint(
                    painter: _SchlundMaler(
                      stufe: stufe,
                      zeit: _takt.value * EingangsGlut._runde.inSeconds,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(alignment: const Alignment(0, -0.5), child: widget.child),
        ],
      ),
    );
  }
}

class _SchlundMaler extends CustomPainter {
  _SchlundMaler({required this.stufe, required this.zeit});

  final GlutStufe stufe;

  /// Sekunden im Durchlauf, 0 bis 12.
  final double zeit;

  /// Ein Atemzug dauert 2,4 s — fünf passen in einen Durchlauf.
  static const double _atem = 2.4;

  @override
  void paint(Canvas canvas, Size size) {
    final farbe = stufe.farbe;
    final atem = 0.82 + 0.18 * math.sin(2 * math.pi * zeit / _atem);
    final mitte = Offset(size.width / 2, size.height * 0.72);
    final breite = math.min(size.width * 0.62, 240.0);
    final loch = Rect.fromCenter(
      center: mitte,
      width: breite,
      height: breite * 0.3,
    );

    // Der Schein über allem, aus dem Loch nach oben.
    canvas.drawCircle(
      Offset(mitte.dx, mitte.dy - breite * 0.25),
      breite * 0.85,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                farbe.withValues(alpha: 0.42 * atem),
                farbe.withValues(alpha: 0.12 * atem),
                farbe.withValues(alpha: 0),
              ],
              stops: const <double>[0, 0.45, 1],
            ).createShader(
              Rect.fromCircle(
                center: Offset(mitte.dx, mitte.dy - breite * 0.25),
                radius: breite * 0.85,
              ),
            ),
    );

    // Das Loch: unten hell, wo das Licht herkommt, oben schwarz.
    canvas.drawOval(
      loch,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.6),
          radius: 0.9,
          colors: <Color>[
            Color.lerp(farbe, Colors.white, 0.25)!.withValues(alpha: atem),
            farbe.withValues(alpha: 0.55),
            const Color(0xFF050302),
          ],
          stops: const <double>[0, 0.35, 1],
        ).createShader(loch),
    );

    // Der Rand glüht — einmal weich, einmal scharf.
    canvas.drawOval(
      loch,
      Paint()
        ..color = farbe.withValues(alpha: 0.8 * atem)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(
      loch,
      Paint()
        ..color = Color.lerp(farbe, Colors.white, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (stufe == GlutStufe.mythisch) _zweiterRing(canvas, loch, farbe, atem);
    _funken(canvas, mitte, breite, farbe);
  }

  /// Jenseits von Ebene 30 liegt ein zweiter Ring darüber, der sich
  /// langsam weitet und verblasst — wie Hitze über dem Loch.
  void _zweiterRing(Canvas canvas, Rect loch, Color farbe, double atem) {
    final weite = (zeit % 3) / 3;
    canvas.drawOval(
      loch.inflate(6 + 22 * weite).translate(0, -10 * weite),
      Paint()
        ..color = farbe.withValues(alpha: 0.5 * (1 - weite) * atem)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// Glut steigt aus dem Loch, schwankt und verlischt oben. Jeder Funke
  /// hat seinen eigenen Takt (3, 4 oder 6 s — Teiler des Durchlaufs).
  void _funken(Canvas canvas, Offset mitte, double breite, Color farbe) {
    const takte = <double>[3, 4, 6];
    final hell = Color.lerp(farbe, Colors.white, 0.5)!;
    for (var i = 0; i < stufe.funken; i++) {
      final takt = takte[i % takte.length];
      final versatz = (i * 0.618) % 1;
      final t = ((zeit / takt) + versatz) % 1;
      final start = ((i * 0.37) % 1 - 0.5) * breite * 0.8;
      final x =
          mitte.dx + start + math.sin(t * math.pi * 2 + i) * 10 * (0.5 + t);
      final y = mitte.dy - t * breite * 0.95;
      final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
      final r = 1.2 + 1.6 * (1 - t);
      canvas.drawCircle(
        Offset(x, y),
        r * 2.4,
        Paint()..color = farbe.withValues(alpha: 0.25 * alpha),
      );
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = hell.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_SchlundMaler alt) =>
      alt.zeit != zeit || alt.stufe != stufe;
}

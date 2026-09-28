import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Welcher Rahmen um das Level-Abzeichen liegt — je zehn Level einer.
///
/// **Eine Tabelle, eine Stelle.** Wer die Rahmen später als Zeichnung
/// ablegt, ändert nur, wie [LevelAbzeichen] einen Rahmen malt; welcher
/// Rahmen zu welchem Level gehört, bleibt hier.
///
/// Level 50 ist das höchste und bekommt denselben Rahmen wie 40 bis 49.
/// Ein eigener Rahmen für eine einzige Stufe wäre einer, den kaum jemand
/// sieht.
enum LevelRahmen {
  holz('Holz', Palette.rahmenHolzHell, Palette.rahmenHolzDunkel, 0),
  bronze('Bronze', Palette.rahmenBronzeHell, Palette.rahmenBronzeDunkel, 2),
  silber('Silber', Palette.rahmenSilberHell, Palette.rahmenSilberDunkel, 4),
  gold('Gold', Palette.rahmenGoldHell, Palette.rahmenGoldDunkel, 6),
  edelstein('Edelstein', Palette.rahmenEdelHell, Palette.rahmenEdelDunkel, 8);

  const LevelRahmen(this.label, this.hell, this.dunkel, this.nieten);

  final String label;
  final Color hell;
  final Color dunkel;

  /// Wie viele Nieten auf dem Ring sitzen. Die Farbe allein trüge die
  /// Stufe nicht für jemanden, der Farben schlecht unterscheidet.
  final int nieten;

  /// Der Rahmen für [level]: 1–9 Holz, 10–19 Bronze, 20–29 Silber, 30–39
  /// Gold, ab 40 Edelstein.
  static LevelRahmen fuer(int level) {
    final stufe = (level ~/ 10).clamp(0, values.length - 1);
    return values[stufe];
  }
}

/// Das Level als rundes Abzeichen mit der Zahl darin.
///
/// Gemalt, nicht gezeichnet: ein Platzhalter, bis es Bilder für die
/// fünf Rahmen gibt (Frederik, 28.09.).
class LevelAbzeichen extends StatelessWidget {
  const LevelAbzeichen({required this.level, this.size = 44, super.key});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rahmen = LevelRahmen.fuer(level);
    return Semantics(
      label: 'Level $level',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RahmenMaler(rahmen),
          child: Center(
            child: Padding(
              // Innerhalb des Rings bleiben, sonst steht eine zweistellige
              // Zahl auf dem Rahmen.
              padding: EdgeInsets.all(size * 0.2),
              child: FittedBox(
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Palette.textOnDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RahmenMaler extends CustomPainter {
  const _RahmenMaler(this.rahmen);

  final LevelRahmen rahmen;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ring = radius * 0.22;

    final kreis = Rect.fromCircle(center: mitte, radius: radius);
    canvas.drawCircle(
      mitte,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[rahmen.hell, rahmen.dunkel],
        ).createShader(kreis),
    );
    canvas.drawCircle(
      mitte,
      radius - ring,
      Paint()..color = Palette.abzeichenGrund,
    );

    // Die Nieten sitzen mitten auf dem Ring, die erste oben.
    final niete = Paint()..color = rahmen.hell;
    final schatten = Paint()..color = rahmen.dunkel;
    for (var i = 0; i < rahmen.nieten; i++) {
      final winkel = -math.pi / 2 + 2 * math.pi * i / rahmen.nieten;
      final ort =
          mitte +
          Offset(math.cos(winkel), math.sin(winkel)) * (radius - ring / 2);
      canvas.drawCircle(ort, ring * 0.42, schatten);
      canvas.drawCircle(ort, ring * 0.28, niete);
    }
  }

  @override
  bool shouldRepaint(_RahmenMaler oldDelegate) => oldDelegate.rahmen != rahmen;
}

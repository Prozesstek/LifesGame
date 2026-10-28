import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../skills/gebiet_farbe.dart';

/// Welches Zeichen zu welchem Wert gehört — **eine Tabelle**.
///
/// Seit die App ohne Lesen auskommen soll, steht der Wert nicht mehr als
/// Wort da: Schwert für Angriff, Herz für Leben, Schild für Abwehr,
/// Tropfen für Mana — die Zeichen, die ein Spieler aus RPGs kennt. Einen
/// eigenen Alltagsnamen daneben gibt es seit ADR-0088 nicht mehr.
///
/// **Bis zum 28.10.2026 war Angriff eine Hantel**, ein Überbleibsel von
/// „Stärke“. Ein Schwert gibt es unter den Systemzeichen nicht; es ist
/// gezeichnet ([StatIcon]) und deshalb kein [IconData]. Wer einen Wert
/// zeigt, nimmt [StatIcon], nie [of] allein.
///
/// **Die Farbe ist die seines Gebiets** (ADR-0090): Ein Wert gehört seit
/// ADR-0088 zu genau einem, und so sieht man es ihm an. In der Grube
/// gilt das nicht — dort bleiben die Balken für Leben und Mana, wie sie
/// sind.
abstract final class StatIcons {
  /// Das Systemzeichen — für Angriff null, das Schwert zeichnet
  /// [StatIcon] selbst.
  static IconData? of(HabitStat stat) => switch (stat) {
    HabitStat.staerke => null,
    HabitStat.ausdauer => Icons.favorite_rounded,
    HabitStat.disziplin => Icons.shield_rounded,
    HabitStat.klarheit => Icons.water_drop_rounded,
  };

  /// Auf Pergament.
  static Color colorOf(HabitStat stat) => GebietFarbe.pergament(stat.gebiet);

  /// Auf Leder.
  static Color colorOnDarkOf(HabitStat stat) => GebietFarbe.leder(stat.gebiet);
}

/// Ein Wert als Zeichen; der Name steht nur für den Vorleser da.
class StatIcon extends StatelessWidget {
  const StatIcon(this.stat, {this.size = 14, this.color, super.key});

  final HabitStat stat;
  final double size;

  /// Auf Leder statt Pergament eine andere Farbe; sonst die der Tabelle.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final farbe = color ?? StatIcons.colorOf(stat);
    final icon = StatIcons.of(stat);
    if (icon != null) {
      return Icon(icon, size: size, color: farbe, semanticLabel: stat.label);
    }
    return Semantics(
      label: stat.label,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _SchwertMaler(farbe)),
      ),
    );
  }
}

/// Ein Schwert, schräg mit der Spitze nach rechts oben, als volle Fläche
/// wie ein Systemzeichen — klein muss es so gut lesbar sein wie das Herz
/// daneben.
class _SchwertMaler extends CustomPainter {
  const _SchwertMaler(this.farbe);

  final Color farbe;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final mitte = size.center(Offset.zero);
    const winkel = math.pi / 4;
    final c = math.cos(winkel);
    final si = math.sin(winkel);
    // x quer zum Schwert, y von der Spitze (negativ) zum Knauf.
    Offset p(double x, double y) =>
        mitte + Offset((x * c - y * si) * s, (x * si + y * c) * s);
    Path viereck(double links, double rechts, double oben, double unten) =>
        Path()..addPolygon(<Offset>[
          p(links, oben),
          p(rechts, oben),
          p(rechts, unten),
          p(links, unten),
        ], true);

    final schwert = Path()
      ..addPolygon(<Offset>[
        p(-0.08, 0.12),
        p(-0.08, -0.32),
        p(0, -0.46),
        p(0.08, -0.32),
        p(0.08, 0.12),
      ], true)
      ..addPath(viereck(-0.21, 0.21, 0.11, 0.2), Offset.zero)
      ..addPath(viereck(-0.045, 0.045, 0.2, 0.37), Offset.zero)
      ..addOval(Rect.fromCircle(center: p(0, 0.42), radius: 0.07 * s));
    canvas.drawPath(schwert, Paint()..color = farbe);
  }

  @override
  bool shouldRepaint(_SchwertMaler alt) => alt.farbe != farbe;
}

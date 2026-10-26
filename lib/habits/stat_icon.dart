import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../skills/gebiet_farbe.dart';

/// Welches Zeichen zu welchem Wert gehört — **eine Tabelle**.
///
/// Seit die App ohne Lesen auskommen soll, steht der Wert nicht mehr als
/// Wort da: Hantel für Angriff, Herz für Leben, Schild für Abwehr,
/// Tropfen für Mana. Einen eigenen Alltagsnamen daneben gibt es seit
/// ADR-0088 nicht mehr.
///
/// **Die Farbe ist die seines Gebiets** (ADR-0090): Ein Wert gehört seit
/// ADR-0088 zu genau einem, und so sieht man es ihm an. In der Grube
/// gilt das nicht — dort bleiben die Balken für Leben und Mana, wie sie
/// sind.
abstract final class StatIcons {
  static IconData of(HabitStat stat) => switch (stat) {
    HabitStat.staerke => Icons.fitness_center_rounded,
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
    return Icon(
      StatIcons.of(stat),
      size: size,
      color: color ?? StatIcons.colorOf(stat),
      semanticLabel: stat.label,
    );
  }
}

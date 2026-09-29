import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../ui/palette.dart';

/// Welches Zeichen zu welchem Wert gehört — **eine Tabelle**.
///
/// Seit die App ohne Lesen auskommen soll, steht „Stärke · Angriff“ nicht
/// mehr als Wort da. Dasselbe Zeichen gilt für den Alltagswert und seine
/// Wirkung im Kampf: Hantel für Stärke und Angriff, Herz für Ausdauer und
/// Leben, Schild für Disziplin und Abwehr, Tropfen für Klarheit und Mana.
abstract final class StatIcons {
  static IconData of(HabitStat stat) => switch (stat) {
    HabitStat.staerke => Icons.fitness_center_rounded,
    HabitStat.ausdauer => Icons.favorite_rounded,
    HabitStat.disziplin => Icons.shield_rounded,
    HabitStat.klarheit => Icons.water_drop_rounded,
  };

  static Color colorOf(HabitStat stat) => switch (stat) {
    HabitStat.staerke => Palette.accent,
    HabitStat.ausdauer => Palette.enemy,
    HabitStat.disziplin => Palette.gold,
    HabitStat.klarheit => Palette.textDim,
  };
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
      semanticLabel: '${stat.label}, ${stat.combatLabel}',
    );
  }
}

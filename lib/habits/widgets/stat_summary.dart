import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

/// Die vier Charakterwerte nebeneinander.
///
/// Steht bewusst über der Liste: Wer abhakt, soll im selben Blick sehen,
/// wohin es geht. Ohne diese Zeile bliebe der Kern-Loop des Konzepts
/// unsichtbar.
class StatSummary extends StatelessWidget {
  const StatSummary({required this.stats, super.key});

  final CharacterStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final stat in HabitStat.values) ...<Widget>[
          Expanded(
            child: _StatCell(stats: stats, stat: stat),
          ),
          if (stat != HabitStat.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stats, required this.stat});

  final CharacterStats stats;
  final HabitStat stat;

  @override
  Widget build(BuildContext context) {
    final bonus = stats.bonusFor(stat);
    final remaining = stats.checksToNextPoint(stat);

    return Semantics(
      label: '${stat.label} ${stats.valueFor(stat)}, ${stat.combatLabel}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              stat.label,
              style: const TextStyle(fontSize: 11, color: Palette.textDim),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  '${stats.valueFor(stat)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (bonus > 0) ...<Widget>[
                  const SizedBox(width: 3),
                  Text(
                    '+$bonus',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Palette.success,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              stats.isAtCap(stat) ? 'am Maximum' : 'noch $remaining',
              style: const TextStyle(fontSize: 10, color: Palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

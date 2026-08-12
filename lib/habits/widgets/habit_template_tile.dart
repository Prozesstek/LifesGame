import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

/// Eine freigeschaltete Vorlage, die noch nicht läuft.
///
/// Zeigt die Begründung aus der Lektion mit an: Eine Gewohnheit, deren
/// Sinn man nicht kennt, hält keine Woche.
class HabitTemplateTile extends StatelessWidget {
  const HabitTemplateTile({
    required this.template,
    required this.canActivate,
    required this.onActivate,
    super.key,
  });

  final HabitTemplate template;

  /// False, wenn die Obergrenze erreicht ist.
  final bool canActivate;

  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.why,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Palette.textDim,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${template.stat.label} · ${template.stat.combatLabel}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Palette.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: canActivate ? onActivate : null,
            icon: const Icon(Icons.add_circle_outline),
            color: Palette.accent,
            disabledColor: Palette.muted,
            tooltip: canActivate
                ? 'Täglich verfolgen'
                : 'Erst eine andere Gewohnheit beenden',
          ),
        ],
      ),
    );
  }
}

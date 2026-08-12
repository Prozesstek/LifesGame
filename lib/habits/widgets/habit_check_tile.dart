import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

/// Eine laufende Gewohnheit: abhaken, Streak sehen.
class HabitCheckTile extends StatelessWidget {
  const HabitCheckTile({
    required this.template,
    required this.isChecked,
    required this.streak,
    required this.nextMultiplier,
    required this.onToggle,
    required this.onStop,
    super.key,
  });

  final HabitTemplate template;
  final bool isChecked;

  /// Länge der Kette, die heute zählt.
  final int streak;

  /// Der Multiplikator, den das nächste Häkchen brächte.
  final double nextMultiplier;

  final VoidCallback onToggle;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isChecked ? Palette.surfaceRaised : Palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: <Widget>[
              Semantics(
                checked: isChecked,
                label: template.name,
                child: Icon(
                  isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 26,
                  color: isChecked ? Palette.success : Palette.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isChecked ? Palette.textDim : Colors.white,
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Palette.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onStop,
                icon: const Icon(Icons.close, size: 18),
                color: Palette.muted,
                tooltip: 'Nicht mehr verfolgen',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Streak und Wirkung in einer Zeile — beides ist der Grund, warum man
  /// morgen wiederkommt.
  String get _subtitle {
    final wirkung = '+1 ${template.stat.label}';
    if (streak <= 0) return '$wirkung · noch keine Streak';

    final tage = streak == 1 ? '1 Tag' : '$streak Tage';
    if (nextMultiplier <= 1.0) return '$wirkung · $tage am Stück';

    final faktor = nextMultiplier.toStringAsFixed(1).replaceAll('.', ',');
    return '$wirkung · $tage am Stück · x$faktor';
  }
}

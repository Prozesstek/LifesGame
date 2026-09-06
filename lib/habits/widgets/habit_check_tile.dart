import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

/// Eine laufende Gewohnheit: abhaken, Streak sehen, ein Tagesziel füllen.
///
/// **Zwei Griffe, damit keiner mehrdeutig wird.** Die Kachel selbst hakt
/// ganz ab oder nimmt zurück — dieselbe Geste wie vor ADR-0028, und die
/// einzige für alles ohne Ziel. Das Plus daneben füllt ein Ziel um einen
/// Schritt. Wer fünf Gläser trinkt, tippt fünfmal auf das Plus; wer schon
/// weiß, dass der Tag steht, tippt einmal auf die Kachel.
class HabitCheckTile extends StatelessWidget {
  const HabitCheckTile({
    required this.habit,
    required this.isChecked,
    required this.streak,
    required this.nextMultiplier,
    required this.progress,
    required this.onToggle,
    required this.onAdvance,
    required this.onStop,
    super.key,
  });

  final Habit habit;
  final bool isChecked;

  /// Länge der Kette, die heute zählt.
  final int streak;

  /// Der Multiplikator, den das nächste Häkchen brächte.
  final double nextMultiplier;

  /// Wie weit das Tagesziel gefüllt ist.
  final int progress;

  final VoidCallback onToggle;

  /// Ein Schritt auf das Tagesziel.
  final VoidCallback onAdvance;

  final VoidCallback onStop;

  HabitGoal? get _goal => habit.goal;

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final zeigtPlus = goal != null && !isChecked;

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
                label: habit.name,
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
                      habit.name,
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
                    if (_details.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        _details,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Palette.muted,
                        ),
                      ),
                    ],
                    if (goal != null && !isChecked) ...<Widget>[
                      const SizedBox(height: 7),
                      _GoalBar(done: progress, target: goal.target),
                    ],
                  ],
                ),
              ),
              if (zeigtPlus)
                IconButton(
                  onPressed: onAdvance,
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: Palette.accent,
                  tooltip: _plusTooltip(goal),
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

  static String _plusTooltip(HabitGoal goal) {
    return goal.step == 1 ? 'Eins mehr' : '${goal.step} ${goal.unit} mehr';
  }

  /// Streak und Wirkung in einer Zeile — beides ist der Grund, warum man
  /// morgen wiederkommt.
  String get _subtitle {
    final wirkung = '+1 ${habit.stat.label}';
    if (streak <= 0) return '$wirkung · noch keine Streak';

    final tage = streak == 1 ? '1 Tag' : '$streak Tage';
    if (nextMultiplier <= 1.0) return '$wirkung · $tage am Stück';

    final faktor = nextMultiplier.toStringAsFixed(1).replaceAll('.', ',');
    return '$wirkung · $tage am Stück · x$faktor';
  }

  /// Ziel, Schwierigkeit und Priorität — aber nur, was vom Normalfall
  /// abweicht. Eine Zeile, die bei jeder Gewohnheit „Mittel · Normal"
  /// sagt, sagt nichts.
  String get _details {
    final teile = <String>[];
    final goal = _goal;
    if (goal != null) teile.add(goal.progressLabel(progress));
    if (habit.difficulty != HabitDifficulty.mittel) {
      teile.add(habit.difficulty.label);
    }
    if (habit.priority != HabitPriority.normal) {
      teile.add(habit.priority.label);
    }
    return teile.join(' · ');
  }
}

/// Ein schmaler Balken für den angefangenen Tag.
///
/// Die Zahl steht schon in der Zeile darüber; der Balken ist für den
/// Blick im Vorbeigehen, nicht zum Ablesen.
class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.done, required this.target});

  final int done;
  final int target;

  @override
  Widget build(BuildContext context) {
    final anteil = target <= 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: anteil,
        minHeight: 4,
        backgroundColor: Palette.surfaceRaised,
        valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
      ),
    );
  }
}

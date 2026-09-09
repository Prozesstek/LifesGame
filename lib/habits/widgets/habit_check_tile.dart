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
///
/// **Ohne Untertexte seit Issue #35.** Unter dem Namen stand bis dahin
/// eine Zeile Prosa („+1 Stärke · 3 Tage am Stück · x1,2") und darunter
/// oft eine zweite. Bei fünf Gewohnheiten waren das zehn Zeilen, die sich
/// täglich kaum ändern. Die **Zahlen** sind geblieben und nach rechts
/// gewandert: Die Streak steht als Marke neben dem Namen, der Stand eines
/// Tagesziels am Balken. Verloren ist nur der Stat-Name — welcher Wert
/// wovon wächst, steht mit Herkunft auf dem Charakterbildschirm.
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
    final zeigtBalken = goal != null && !isChecked;

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
                        color: isChecked ? Palette.textDim : Palette.text,
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Palette.muted,
                      ),
                    ),
                    if (zeigtBalken) ...<Widget>[
                      const SizedBox(height: 7),
                      _GoalBar(
                        done: progress,
                        target: goal.target,
                        label: goal.progressLabel(progress),
                      ),
                    ],
                  ],
                ),
              ),
              if (streak > 0) ...<Widget>[
                const SizedBox(width: 8),
                _StreakBadge(streak: streak, nextMultiplier: nextMultiplier),
              ],
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
}

/// Die Kette als Marke neben dem Namen.
///
/// Sie ist der Grund, morgen wiederzukommen, und damit die einzige Zahl,
/// die den Weg aus dem Untertext heraus verdient hat. Ohne laufende Kette
/// erscheint sie gar nicht — „noch keine Streak" ist eine Null, die
/// niemand lesen muss.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, required this.nextMultiplier});

  final int streak;
  final double nextMultiplier;

  @override
  Widget build(BuildContext context) {
    final faktor = nextMultiplier <= 1.0
        ? null
        : 'x${nextMultiplier.toStringAsFixed(1).replaceAll('.', ',')}';

    return Semantics(
      label: streak == 1 ? '1 Tag am Stück' : '$streak Tage am Stück',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.local_fire_department,
            size: 14,
            color: Palette.gold,
          ),
          const SizedBox(width: 3),
          Text(
            faktor == null ? '$streak' : '$streak · $faktor',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Palette.gold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ein schmaler Balken für den angefangenen Tag, mit seiner Zahl daneben.
///
/// Die Zahl stand bis Issue #35 in der Zeile darüber. Sie ist mit an den
/// Balken gewandert statt zu verschwinden: Ein Balken allein sagt „etwa
/// die Hälfte", und wer fünf Gläser zählt, will wissen, ob er beim
/// dritten oder vierten steht.
class _GoalBar extends StatelessWidget {
  const _GoalBar({
    required this.done,
    required this.target,
    required this.label,
  });

  final int done;
  final int target;
  final String label;

  @override
  Widget build(BuildContext context) {
    final anteil = target <= 0 ? 0.0 : (done / target).clamp(0.0, 1.0);

    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: anteil,
              minHeight: 4,
              backgroundColor: Palette.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Palette.textDim),
          ),
        ),
      ],
    );
  }
}

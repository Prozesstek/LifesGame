import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/gold_icon.dart';
import '../../ui/palette.dart';
import '../../ui/holz.dart';
import '../../ui/druck.dart';

/// Eine laufende Gewohnheit: abhaken, Streak sehen, ein Tagesziel füllen.
///
/// **Zwei Griffe, damit keiner mehrdeutig wird.** Die Kachel selbst hakt
/// ganz ab oder nimmt zurück — dieselbe Geste wie vor ADR-0028, und die
/// einzige für alles ohne Ziel. Das Plus daneben füllt ein Ziel um einen
/// Schritt. Wer fünf Gläser trinkt, tippt fünfmal auf das Plus; wer schon
/// weiß, dass der Tag steht, tippt einmal auf die Kachel.
///
/// **Ohne Untertexte seit Issue #35 — mit Zahlen seit Issue #46.** Unter
/// dem Namen stand bis #35 eine Zeile Prosa („+1 Stärke · 3 Tage am
/// Stück · x1,2"), und sie ist zu Recht gegangen: Bei fünf Gewohnheiten
/// waren das zehn Zeilen, die sich täglich kaum ändern. Was dabei
/// verloren ging, war der **Ertrag** — die Kachel zeigte den
/// Multiplikator, aber nirgends, was er in Erfahrung bedeutet. Er steht
/// jetzt als Zahl da, vor dem Tippen: „was bringt mir das" ist die
/// Frage, die ein Tracker jeden Tag beantworten muss.
///
/// Die Zahlen kommen fertig herein und werden hier nicht gerechnet —
/// `HabitTracker.xpForNextCheck` ist die eine Stelle, die weiß, was ein
/// Häkchen wert ist.
class HabitCheckTile extends StatelessWidget {
  const HabitCheckTile({
    required this.habit,
    required this.isChecked,
    required this.streak,
    required this.nextMultiplier,
    required this.xpGain,
    required this.goldGain,
    required this.progress,
    required this.onToggle,
    required this.onAdvance,
    required this.onStop,
    super.key,
  });

  /// Wie lange der Wechsel von „offen" auf „erledigt" dauert.
  ///
  /// Kurz genug, dass niemand wartet, lang genug, dass man es sieht — ein
  /// Häkchen, das ohne Regung erscheint, fühlt sich nach Formular an.
  static const Duration checkDuration = Duration(milliseconds: 220);

  final Habit habit;
  final bool isChecked;

  /// Länge der Kette, die heute zählt.
  final int streak;

  /// Der Multiplikator, den das nächste Häkchen brächte.
  final double nextMultiplier;

  /// Erfahrung für das nächste Häkchen — oder die, die das heutige schon
  /// gebracht hat.
  final int xpGain;

  /// Gold, ebenso.
  final int goldGain;

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

    return Druck(
      child: HolzKarte(
        padding: EdgeInsets.zero,
        color: isChecked ? Palette.surfaceRaised : Palette.surface,
        edgeColor: isChecked ? Palette.success : Holz.kante,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: <Widget>[
                  _CheckMark(isChecked: isChecked, label: habit.name),
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
                        const SizedBox(height: 5),
                        RewardLine(
                          xp: xpGain,
                          gold: goldGain,
                          alreadyEarned: isChecked,
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
                    _StreakBadge(
                      streak: streak,
                      nextMultiplier: nextMultiplier,
                    ),
                  ],
                  if (zeigtPlus)
                    DruckSperre(
                      child: IconButton(
                        onPressed: onAdvance,
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        color: Palette.accent,
                        tooltip: _plusTooltip(goal),
                      ),
                    ),
                  DruckSperre(
                    child: IconButton(
                      onPressed: onStop,
                      icon: const Icon(Icons.close, size: 18),
                      color: Palette.muted,
                      tooltip: 'Nicht mehr verfolgen',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _plusTooltip(HabitGoal goal) {
    return goal.step == 1 ? 'Eins mehr' : '${goal.step} ${goal.unit} mehr';
  }
}

/// Der Kreis links, der beim Abhaken aufpoppt.
///
/// Der Sprung kommt aus einem [AnimatedSwitcher] statt aus einem eigenen
/// Zustand: Die Kachel bleibt damit zustandslos, und die Animation läuft
/// auch dann, wenn der Tracker von woanders geändert wird.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.isChecked, required this.label});

  final bool isChecked;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      label: label,
      child: AnimatedSwitcher(
        duration: HabitCheckTile.checkDuration,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
          key: ValueKey<bool>(isChecked),
          size: 26,
          color: isChecked ? Palette.success : Palette.muted,
        ),
      ),
    );
  }
}

/// Was ein Häkchen einbringt — oder eingebracht hat.
///
/// **Sie steht auf jeder Kachel, nicht nur nach dem Tippen.** Eine
/// Rückmeldung, die erst nach der Tat kommt, kann nicht zur Tat bewegen;
/// die Zahl vorher ist der Grund, die Zahl danach die Bestätigung.
class RewardLine extends StatelessWidget {
  const RewardLine({
    required this.xp,
    required this.gold,
    this.alreadyEarned = false,
    super.key,
  });

  final int xp;
  final int gold;

  /// Ob es schon geholt ist. Dann steht „Heute" davor, und die Zahlen
  /// tragen die Farbe des Erfolgs statt die des Angebots.
  final bool alreadyEarned;

  @override
  Widget build(BuildContext context) {
    final farbe = alreadyEarned ? Palette.success : Palette.accent;
    final stil = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: farbe,
    );

    return Semantics(
      label: alreadyEarned
          ? 'Heute geholt: $xp Erfahrung und $gold Gold'
          : 'Bringt $xp Erfahrung und $gold Gold',
      // **Jeder Text schrumpfbar.** Auf der vollsten Kachel — eigene
      // Gewohnheit mit Ziel, also Plus **und** Kreuz daneben, dazu die
      // Streak-Marke — bleiben für diese Spalte keine 90 Pixel. Zwei
      // feste Texte nebeneinander sind genau der Fall aus `gotchas.md`.
      child: Row(
        children: <Widget>[
          if (alreadyEarned) ...<Widget>[
            Flexible(
              child: Text(
                'Heute',
                overflow: TextOverflow.ellipsis,
                style: stil.copyWith(fontWeight: FontWeight.normal),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(Icons.auto_awesome, size: 13, color: farbe),
          const SizedBox(width: 3),
          Flexible(
            child: Text('+$xp', style: stil, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          const GoldIcon(size: 13),
          const SizedBox(width: 3),
          Flexible(
            child: Text('+$gold', style: stil, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
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

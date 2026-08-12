import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';

/// Was nach der letzten Frage steht: Ergebnis, Ertrag, nächster Schritt.
class LessonResultView extends StatelessWidget {
  const LessonResultView({
    required this.lesson,
    required this.result,
    required this.onRetry,
    required this.onDone,
    super.key,
  });

  final Lesson lesson;
  final LessonResult result;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final passed = result.isPassed;
    final color = passed ? Palette.success : Palette.enemy;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: <Widget>[
        Icon(
          passed ? Icons.verified_outlined : Icons.replay_circle_filled,
          size: 52,
          color: color,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            passed ? 'Bestanden' : 'Noch nicht bestanden',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${result.correct} von ${result.total} Fragen richtig',
            style: const TextStyle(fontSize: 14, color: Palette.textDim),
          ),
        ),
        const SizedBox(height: 24),
        if (result.xpGained > 0 || result.goldGained > 0)
          _Earnings(xp: result.xpGained, gold: result.goldGained)
        else
          _Note(
            text: passed
                ? 'Diese Lektion war schon bestanden — es gibt nichts '
                      'doppelt. Ein besseres Ergebnis zahlt die Differenz.'
                : 'Ab ${TheoryRewards.passPercent} % richtiger Antworten '
                      'gibt es Erfahrung und Gold.',
          ),
        if (passed && lesson.unlocksHabit != null) ...<Widget>[
          const SizedBox(height: 12),
          _HabitUnlock(habit: lesson.unlocksHabit ?? ''),
        ],
        const SizedBox(height: 28),
        FilledButton(onPressed: onDone, child: const Text('Weiter')),
        const SizedBox(height: 8),
        if (!result.isPerfect)
          TextButton(
            onPressed: onRetry,
            child: Text(passed ? 'Nochmal für alle Punkte' : 'Nochmal'),
          ),
      ],
    );
  }
}

class _Earnings extends StatelessWidget {
  const _Earnings({required this.xp, required this.gold});

  final int xp;
  final int gold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (xp > 0)
          _Chip(
            icon: Icons.auto_graph,
            label: '+$xp Erfahrung',
            color: Palette.accent,
          ),
        if (xp > 0 && gold > 0) const SizedBox(width: 10),
        if (gold > 0)
          _Chip(
            icon: Icons.savings_outlined,
            label: '+$gold Gold',
            color: Palette.gold,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitUnlock extends StatelessWidget {
  const _HabitUnlock({required this.habit});

  final String habit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.add_task, size: 18, color: Palette.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Habit-Vorlage freigeschaltet',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  habit,
                  style: const TextStyle(fontSize: 13, color: Palette.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, height: 1.4, color: Palette.muted),
    );
  }
}

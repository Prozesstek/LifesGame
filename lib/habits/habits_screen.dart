import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../theory/skill_tree_screen.dart';
import '../ui/palette.dart';
import 'habits_controller.dart';
import 'widgets/habit_check_tile.dart';
import 'widgets/habit_template_tile.dart';
import 'widgets/stat_summary.dart';

/// Der Tracker-Teil des Spiels: heute abhaken, Vorlagen wählen, sehen,
/// was das mit dem Charakter macht.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final unlocked = ref.watch(unlockedHabitsProvider);
    final stats = ref.watch(characterStatsProvider);
    final today = ref.watch(todayProvider);

    final active = tracker.activeTemplates;
    final available = unlocked
        .where((t) => !tracker.isActive(t.id))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Gewohnheiten')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: unlocked.isEmpty
                ? const _NothingUnlockedYet()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: <Widget>[
                      StatSummary(stats: stats),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Heute',
                        trailing:
                            '${tracker.completedOn(today)} / ${active.length}',
                      ),
                      const SizedBox(height: 10),
                      if (active.isEmpty)
                        const _Hint(
                          'Noch nichts gewählt. Unten stehen die Vorlagen, '
                          'die der Skillbaum freigeschaltet hat.',
                        )
                      else
                        for (final template in active) ...<Widget>[
                          HabitCheckTile(
                            template: template,
                            isChecked: tracker.isChecked(template.id, today),
                            streak: tracker.currentStreak(template.id, today),
                            nextMultiplier: tracker.nextMultiplier(
                              template.id,
                              today,
                            ),
                            onToggle: () => _toggle(context, ref, template),
                            onStop: () => ref
                                .read(habitTrackerProvider.notifier)
                                .deactivate(template.id),
                          ),
                          const SizedBox(height: 8),
                        ],
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Vorlagen',
                        trailing:
                            '${active.length} / ${HabitRewards.maxActiveHabits}',
                      ),
                      const SizedBox(height: 10),
                      if (available.isEmpty)
                        const _Hint(
                          'Alle freigeschalteten Vorlagen laufen bereits. '
                          'Weitere kommen aus dem Skillbaum.',
                        )
                      else
                        for (final template in available) ...<Widget>[
                          HabitTemplateTile(
                            template: template,
                            canActivate: tracker.canActivate(template.id),
                            onActivate: () => ref
                                .read(habitTrackerProvider.notifier)
                                .activate(template.id),
                          ),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _toggle(BuildContext context, WidgetRef ref, HabitTemplate template) {
    final today = ref.read(todayProvider);
    final result = ref
        .read(habitTrackerProvider.notifier)
        .toggle(template.id, today);
    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_feedback(result)),
        duration: const Duration(seconds: 2),
        backgroundColor: Palette.surfaceRaised,
      ),
    );
  }

  /// Was nach einem Häkchen in der Leiste steht.
  ///
  /// Ein erreichter Meilenstein verdrängt den Ertrag: Beides zusammen ist
  /// eine Zeile zu viel, und der Meilenstein ist die seltenere Nachricht.
  String _feedback(CheckResult result) {
    final milestone = result.reachedMilestone;
    if (milestone != null) {
      final faktor = milestone.multiplier
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      return '${milestone.days} Tage am Stück — ab jetzt x$faktor';
    }
    return '+${result.xpGained} Erfahrung · +${result.goldGained} Gold';
  }
}

/// Wenn der Skillbaum noch keine Vorlage hergegeben hat.
///
/// Kein leerer Bildschirm, sondern der Weg dorthin: Die erste Lektion im
/// Zweig „Gewohnheiten" bringt die erste Vorlage.
class _NothingUnlockedYet extends StatelessWidget {
  const _NothingUnlockedYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.spa_outlined, size: 44, color: Palette.muted),
          const SizedBox(height: 16),
          const Text(
            'Noch keine Gewohnheit freigeschaltet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jede Vorlage kommt aus einer Lektion — erst verstehen, '
            'dann verfolgen. Die erste wartet im Zweig „Gewohnheiten".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: Palette.textDim),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SkillTreeScreen()),
            ),
            icon: const Icon(Icons.account_tree_outlined, size: 18),
            label: const Text('Zum Skillbaum'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Palette.textDim,
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.4, color: Palette.muted),
      ),
    );
  }
}

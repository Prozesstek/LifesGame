import 'dart:async';

import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../character/abilities_controller.dart';
import '../character/show_ability_unlock.dart';
import '../theory/skill_tree_screen.dart';
import '../ui/palette.dart';
import 'habits_controller.dart';
import 'widgets/custom_habit_sheet.dart';
import 'widgets/habit_check_tile.dart';
import 'widgets/habit_template_tile.dart';
import 'widgets/stat_summary.dart';

/// Der Tracker-Teil des Spiels: heute abhaken, Vorlagen wählen, eigene
/// Gewohnheiten anlegen, sehen, was das mit dem Charakter macht.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final unlocked = ref.watch(unlockedHabitsProvider);
    final stats = ref.watch(characterStatsProvider);
    final today = ref.watch(todayProvider);
    final slots = ref.watch(customSlotsProvider);
    final slotsLeft = ref.watch(customSlotsLeftProvider);

    final active = tracker.activeHabitsByPriority;
    final availableTemplates = unlocked
        .where((t) => !tracker.isActive(t.id))
        .toList(growable: false);
    final ruhendeEigene = tracker.customHabits
        .where((h) => !tracker.isActive(h.id))
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
                        for (final habit in active) ...<Widget>[
                          HabitCheckTile(
                            habit: habit,
                            isChecked: tracker.isChecked(habit.id, today),
                            streak: tracker.currentStreak(habit.id, today),
                            nextMultiplier: tracker.nextMultiplier(
                              habit.id,
                              today,
                            ),
                            progress: tracker.progressOn(habit.id, today),
                            onToggle: () => _toggle(context, ref, habit),
                            onAdvance: () => _advance(context, ref, habit),
                            onStop: () => ref
                                .read(habitTrackerProvider.notifier)
                                .deactivate(habit.id),
                          ),
                          const SizedBox(height: 8),
                        ],
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Eigene',
                        trailing: '${tracker.customCount} / $slots',
                      ),
                      const SizedBox(height: 10),
                      _CustomHabitButton(
                        slotsLeft: slotsLeft,
                        listeVoll: tracker.isFull,
                        onTap: () => _createCustom(context, ref),
                      ),
                      for (final habit in ruhendeEigene) ...<Widget>[
                        const SizedBox(height: 8),
                        _RestingCustomTile(
                          habit: habit,
                          canActivate: tracker.canActivate(habit.id),
                          onActivate: () => ref
                              .read(habitTrackerProvider.notifier)
                              .activate(habit.id),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Vorlagen',
                        trailing:
                            '${tracker.activeIds.length} / '
                            '${HabitRewards.maxActiveHabits}',
                      ),
                      const SizedBox(height: 10),
                      if (availableTemplates.isEmpty)
                        const _Hint(
                          'Alle freigeschalteten Vorlagen laufen bereits. '
                          'Weitere kommen aus dem Skillbaum.',
                        )
                      else
                        for (final template in availableTemplates) ...<Widget>[
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

  /// Legt eine eigene Gewohnheit an — Formular auf, Ergebnis hinein.
  Future<void> _createCustom(BuildContext context, WidgetRef ref) async {
    final draft = await CustomHabitSheet.show(context);
    if (draft == null || !context.mounted) return;

    final habit = ref
        .read(habitTrackerProvider.notifier)
        .addCustom(
          name: draft.name,
          stat: draft.stat,
          difficulty: draft.difficulty,
          goal: draft.goal,
          priority: draft.priority,
          why: draft.why,
        );

    final tracker = ref.read(habitTrackerProvider);
    _say(context, switch (habit) {
      null =>
        'Kein Platz frei — dafür braucht es eine weitere Vorlage '
            'aus dem Skillbaum.',
      _ when tracker.isActive(habit.id) =>
        '„${habit.name}" steht ab heute auf der Liste.',
      _ =>
        '„${habit.name}" ist angelegt — die Tagesliste ist voll, '
            'sie wartet unter „Eigene".',
    });
  }

  void _toggle(BuildContext context, WidgetRef ref, Habit habit) {
    final today = ref.read(todayProvider);
    final vorher = ref.read(unlockedAbilitiesProvider);

    final result = ref
        .read(habitTrackerProvider.notifier)
        .toggle(habit.id, today);
    if (result == null) return;

    _celebrate(context, ref, vorher);
    _say(context, _feedback(result));
  }

  /// Ein Schritt auf ein Tagesziel.
  void _advance(BuildContext context, WidgetRef ref, Habit habit) {
    final today = ref.read(todayProvider);
    final vorher = ref.read(unlockedAbilitiesProvider);

    final result = ref
        .read(habitTrackerProvider.notifier)
        .advance(habit.id, today);

    if (!result.isComplete) {
      final goal = habit.goal;
      _say(
        context,
        goal == null
            ? '${result.progress} / ${result.required}'
            : goal.progressLabel(result.progress),
      );
      return;
    }

    _celebrate(context, ref, vorher);
    _say(context, _feedback(result));
  }

  /// Vier Fähigkeiten hängen an Streak-Marken (ADR-0022). Genau hier
  /// reißt eine Kette weiter — und nur hier ist der Moment, in dem sich
  /// eine Marke überschreiten lässt.
  void _celebrate(BuildContext context, WidgetRef ref, List<Ability> vorher) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(showAbilityUnlocks(context, ref, before: vorher));
    });
  }

  static void _say(BuildContext context, String text) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
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

/// Der Knopf für eine eigene Gewohnheit — und der Grund, wenn er nicht
/// geht.
///
/// Bleibt sichtbar statt zu verschwinden: Ein Knopf, der fehlt, wirft die
/// Frage auf, ob es ihn je gab. Einer, der den Weg nennt, beantwortet sie.
class _CustomHabitButton extends StatelessWidget {
  const _CustomHabitButton({
    required this.slotsLeft,
    required this.listeVoll,
    required this.onTap,
  });

  final int slotsLeft;

  /// Ob die Tagesliste voll ist. Anlegen geht trotzdem — die Gewohnheit
  /// wartet dann unter „Eigene".
  final bool listeVoll;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offen = slotsLeft > 0;
    return Material(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: offen ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: <Widget>[
              // Bewusst ein anderes Zeichen als das Plus, mit dem eine
              // fertige Vorlage gestartet wird: Hier entsteht etwas
              // Neues, dort wird etwas Vorhandenes aufgenommen.
              Icon(
                Icons.playlist_add,
                size: 22,
                color: offen ? Palette.accent : Palette.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Eigene Gewohnheit anlegen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: offen ? Colors.white : Palette.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _hinweis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Palette.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _hinweis {
    if (slotsLeft <= 0) {
      return 'Kein Platz frei. Jede freigeschaltete Vorlage gibt einen '
          'Platz für eine eigene.';
    }
    final plaetze = slotsLeft == 1 ? 'ein Platz' : '$slotsLeft Plätze';
    if (listeVoll) {
      return 'Noch $plaetze — die Tagesliste ist voll, sie wartet dann '
          'hier unten.';
    }
    return 'Noch $plaetze frei.';
  }
}

/// Eine eigene Gewohnheit, die gerade nicht auf der Tagesliste steht.
class _RestingCustomTile extends StatelessWidget {
  const _RestingCustomTile({
    required this.habit,
    required this.canActivate,
    required this.onActivate,
  });

  final CustomHabit habit;
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
                  habit.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (habit.why.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    habit.why,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Palette.textDim,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _zeile,
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

  String get _zeile {
    final teile = <String>[
      '${habit.stat.label} · ${habit.stat.combatLabel}',
      habit.difficulty.label,
    ];
    final goal = habit.goal;
    if (goal != null) teile.add(goal.label);
    return teile.join(' · ');
  }
}

/// Wenn der Skillbaum noch keine Vorlage hergegeben hat.
///
/// Kein leerer Bildschirm, sondern der Weg dorthin: Die erste Lektion im
/// Zweig „Gewohnheiten" bringt die erste Vorlage — und damit auch den
/// ersten Platz für eine eigene.
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
            'dann verfolgen. Die erste wartet im Zweig „Gewohnheiten", '
            'und sie gibt zugleich den ersten Platz für eine eigene.',
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
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            trailing,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Palette.textDim,
            ),
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

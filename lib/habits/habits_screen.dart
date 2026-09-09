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

      // **Unten rechts, wo der Daumen ist.** Der Knopf sass bis Issue #35
      // als Zeile mitten in der Liste unter „Eigene" -- also genau dort,
      // wo man ihn nur findet, wenn man ohnehin schon scrollt. Er ist
      // ausgeblendet, solange der Skillbaum keine einzige Vorlage
      // hergegeben hat: Ohne Vorlage gibt es keinen Platz (ADR-0028), und
      // ein Knopf, der nur absagen kann, ist keiner.
      floatingActionButton: unlocked.isEmpty
          ? null
          : _CustomHabitFab(
              slotsLeft: slotsLeft,
              listeVoll: tracker.isFull,
              onCreate: () => _createCustom(context, ref),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: unlocked.isEmpty
                ? const _NothingUnlockedYet()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
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
                      if (ruhendeEigene.isEmpty)
                        const _Hint(
                          'Noch keine eigene angelegt. Der Knopf unten '
                          'rechts fragt nach Name, Wert und Tagesziel.',
                        ),
                      for (final habit in ruhendeEigene) ...<Widget>[
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
/// Der schwebende Knopf, der eine eigene Gewohnheit anlegt.
///
/// **Er sagt auch ab, statt zu verschwinden.** Ohne freien Platz bleibt
/// er sichtbar, wird aber matt und erklaert beim Antippen, woran es
/// liegt. Ein Knopf, der bei fehlendem Platz einfach fehlt, laesst genau
/// die Frage offen, die dann aufkommt -- und die Antwort („jede
/// freigeschaltete Vorlage gibt einen Platz") ist der Weg zurueck in den
/// Skillbaum.
class _CustomHabitFab extends StatelessWidget {
  const _CustomHabitFab({
    required this.slotsLeft,
    required this.listeVoll,
    required this.onCreate,
  });

  final int slotsLeft;

  /// Ob die Tagesliste voll ist. Anlegen geht trotzdem — die Gewohnheit
  /// wartet dann unter „Eigene".
  final bool listeVoll;

  final VoidCallback onCreate;

  bool get _offen => slotsLeft > 0;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _offen ? onCreate() : _sageWarumNicht(context),
      backgroundColor: _offen ? Palette.accent : Palette.surfaceRaised,
      foregroundColor: _offen ? Palette.surface : Palette.muted,
      tooltip: _hinweis,
      // Dasselbe Zeichen wie vorher in der Liste, und bewusst ein
      // anderes als das Plus, mit dem eine fertige Vorlage gestartet
      // wird: Hier entsteht etwas Neues, dort wird etwas Vorhandenes
      // aufgenommen.
      child: const Icon(Icons.playlist_add),
    );
  }

  void _sageWarumNicht(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(_hinweis), duration: const Duration(seconds: 3)),
      );
  }

  String get _hinweis {
    if (!_offen) {
      return 'Kein Platz frei. Jede freigeschaltete Vorlage gibt einen '
          'Platz für eine eigene.';
    }
    final plaetze = slotsLeft == 1 ? 'ein Platz' : '$slotsLeft Plätze';
    if (listeVoll) {
      return 'Noch $plaetze — die Tagesliste ist voll, sie wartet dann '
          'unter „Eigene".';
    }
    return 'Eigene Gewohnheit anlegen — noch $plaetze frei.';
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
                    color: Palette.text,
                  ),
                ),
                const SizedBox(height: 4),
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
          const Icon(
            Icons.spa_outlined,
            size: 44,
            color: Palette.textOnDarkDim,
          ),
          const SizedBox(height: 16),
          const Text(
            'Noch keine Gewohnheit freigeschaltet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Palette.textOnDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jede Vorlage kommt aus einer Lektion — erst verstehen, '
            'dann verfolgen. Die erste wartet im Zweig „Gewohnheiten", '
            'und sie gibt zugleich den ersten Platz für eine eigene.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Palette.textOnDarkDim,
            ),
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
              color: Palette.textOnDark,
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
              color: Palette.textOnDarkDim,
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
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Palette.textOnDarkDim,
        ),
      ),
    );
  }
}

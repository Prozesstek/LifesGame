import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../audio/sound_effects.dart';
import '../combat/ladder_controller.dart';
import '../progression/show_level_up.dart';
import '../theory/review_controller.dart';
import '../theory/widgets/review_card.dart';
import '../ui/palette.dart';
import 'habit_check_flow.dart';
import 'daily_quests_provider.dart';
import 'habits_controller.dart';
import 'widgets/cue_dialog.dart';
import 'widgets/custom_habit_sheet.dart';
import 'widgets/daily_chest_card.dart';
import 'widgets/daily_form_card.dart';
import 'widgets/daily_quests_card.dart';
import 'widgets/habit_check_tile.dart';
import 'widgets/habit_template_tile.dart';
import 'widgets/stat_summary.dart';
import 'widgets/streak_freeze_card.dart';
import 'widgets/streak_ladder_card.dart';
import 'widgets/week_card.dart';
import '../ui/aufstieg.dart';
import '../ui/holz.dart';
import '../ui/druck.dart';
import '../gear/gear_controller.dart';

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

    final active = tracker.dailyListOn(today);
    // Der Tag, den ein Streak-Eis gerade noch retten kann. Die Regel
    // dafür steht in `package:habits`, nicht hier.
    final zuRetten = tracker.rescuableDay(today);
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
      // wo man ihn nur findet, wenn man ohnehin schon scrollt. Seit der
      // Startvorlage (ADR-0052) gibt es immer mindestens einen Platz, und
      // der Knopf steht immer da.
      floatingActionButton: _CustomHabitFab(
        slotsLeft: slotsLeft,
        listeVoll: tracker.isFull,
        onCreate: () => _createCustom(context, ref),
      ),
      body: AufstiegHost(
        // Ein Kontext **unter** dem Host: Die Rückrufe der Kacheln lassen
        // darüber Zahlen aufsteigen (`AufstiegHost.maybeOf`).
        child: Builder(
          builder: (context) => SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: <Widget>[
                    StatSummary(stats: stats),
                    const SizedBox(height: 12),
                    if (zuRetten != null) ...<Widget>[
                      StreakFreezeCard(
                        streakAtRisk: tracker.currentBestStreak(zuRetten),
                        freezesLeft: tracker.freezesLeft,
                        onUse: () => _useFreeze(context, ref, zuRetten),
                      ),
                      const SizedBox(height: 12),
                    ],
                    StreakLadderCard(
                      bestStreak: tracker.currentBestStreak(today),
                    ),
                    if (active.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      DailyFormCard(
                        form: ref.watch(dailyFormProvider),
                        open: active.length - tracker.completedOn(today),
                      ),
                    ],
                    if (ref.watch(dailyQuestsProvider) case final aufgaben
                        when aufgaben.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      DailyQuestsCard(
                        quests: aufgaben,
                        isClaimed: (q) => tracker.isQuestClaimed(today, q.id),
                        onClaim: (q) => claimDailyQuest(context, ref, q),
                      ),
                    ],
                    if (ref.watch(todaysReviewProvider)
                        case final frage?) ...<Widget>[
                      const SizedBox(height: 12),
                      ReviewCard(
                        question: frage,
                        answer: ref.watch(todaysReviewAnswerProvider),
                        day: dayNumberOf(today),
                        daysUntilNext: _tageBisZurRueckfrage(ref, frage, today),
                        onAnswer: (wahl) =>
                            _answerReview(context, ref, frage, wahl),
                      ),
                    ],
                    if (tracker.canOpenChest(today) ||
                        tracker.hasOpenedChest(today)) ...<Widget>[
                      const SizedBox(height: 12),
                      DailyChestCard(
                        canOpen: tracker.canOpenChest(today),
                        opened: tracker.hasOpenedChest(today)
                            ? DailyChest.forDay(today)
                            : null,
                        onOpen: () => _openChest(context, ref),
                      ),
                    ],
                    const SizedBox(height: 8),
                    WeekCard(
                      today: today,
                      thisWeek: ref.watch(thisWeekProvider),
                      lastWeek: ref.watch(lastWeekProvider),
                    ),
                    const SizedBox(height: 16),
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
                      // Offene oben, erledigte unten (`dailyListOn`).
                      // Der Schlüssel hält den Sprung des Häkchens
                      // an der Gewohnheit, wenn die Kachel die Reihe
                      // wechselt.
                      for (final habit in active) ...<Widget>[
                        HabitCheckTile(
                          key: ValueKey<String>(habit.id),
                          habit: habit,
                          isChecked: tracker.isChecked(habit.id, today),
                          streak: tracker.currentStreak(habit.id, today),
                          nextMultiplier: tracker.nextMultiplier(
                            habit.id,
                            today,
                          ),
                          xpGain: tracker.xpForNextCheck(habit.id, today),
                          goldGain: tracker.goldForNextCheck(habit.id, today),
                          progress: tracker.progressOn(habit.id, today),
                          onToggle: () => toggleHabit(context, ref, habit),
                          onAdvance: () => advanceHabit(context, ref, habit),
                          onStop: () => ref
                              .read(habitTrackerProvider.notifier)
                              .deactivate(habit.id),
                          cue: tracker.cueFor(habit.id),
                          onEditCue: () => _editCue(context, ref, habit),
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
                        onActivate: () => _activate(context, ref, habit),
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
                          onActivate: () => _activate(context, ref, template),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
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
    final laeuft = habit != null && tracker.isActive(habit.id);
    sayHabitFeedback(context, switch (habit) {
      null =>
        'Kein Platz frei — dafür braucht es eine weitere Vorlage '
            'aus dem Skillbaum.',
      _ when tracker.isActive(habit.id) =>
        '„${habit.name}" steht ab heute auf der Liste.',
      _ =>
        '„${habit.name}" ist angelegt — die Tagesliste ist voll, '
            'sie wartet unter „Eigene".',
    });

    if (laeuft) await _editCue(context, ref, habit);
  }

  /// Nimmt eine Gewohnheit auf die Tagesliste — und fragt gleich, wann
  /// sie drankommt (ADR-0052).
  ///
  /// **Jetzt, nicht später:** Wer gerade entschieden hat, etwas täglich
  /// zu tun, hat den Zeitpunkt im Kopf. Einen Tag später steht nur noch
  /// die Zeile „Wann machst du das?" auf der Kachel. Wer schon einen
  /// Auslöser hat (eine pausierte Gewohnheit), wird nicht noch einmal
  /// gefragt.
  Future<void> _activate(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    ref.read(habitTrackerProvider.notifier).activate(habit.id);
    final tracker = ref.read(habitTrackerProvider);
    if (!tracker.isActive(habit.id) || tracker.cueFor(habit.id) != null) {
      return;
    }
    await _editCue(context, ref, habit);
  }

  Future<void> _editCue(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    final text = await showCueDialog(
      context,
      habitName: habit.name,
      current: ref.read(habitTrackerProvider).cueFor(habit.id),
    );
    if (text == null || !context.mounted) return;
    ref.read(habitTrackerProvider.notifier).setCue(habit.id, text);
  }

  /// Nach wie vielen Tagen die Seite der heutigen Rückfrage wiederkommt —
  /// erst nach der Antwort bekannt.
  static int? _tageBisZurRueckfrage(
    WidgetRef ref,
    ReviewQuestion frage,
    Day today,
  ) {
    final faellig = ref.read(reviewLogProvider).dueDayOf(frage.lesson.id);
    if (faellig == null) return null;
    return faellig - dayNumberOf(today);
  }

  /// Beantwortet die Rückfrage des Tages (ADR-0045). Richtig zahlt sie
  /// Erfahrung und Gold, und die steigen dort auf, wo getippt wurde.
  void _answerReview(
    BuildContext context,
    WidgetRef ref,
    ReviewQuestion frage,
    int wahl,
  ) {
    final vorherLevel = levelBefore(ref);
    final schluesselVorher = ref.read(availableKeysProvider);
    final richtig = ref
        .read(reviewLogProvider.notifier)
        .answer(ref.read(todayProvider), frage, wahl);
    if (richtig == null) return;

    if (richtig) {
      unawaited(HapticFeedback.mediumImpact());
      ref.read(soundPlayerProvider).play(SoundEffect.haekchen);
      AufstiegHost.maybeOf(context)?.zeige(<AufstiegZeile>[
        const AufstiegZeile(
          '+${TheoryRewards.xpForReview} EP  +${TheoryRewards.goldForReview} G',
          color: Palette.goldOnDark,
        ),
        ?keyGainLine(ref, schluesselVorher),
      ]);
    } else {
      unawaited(HapticFeedback.selectionClick());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(showLevelUp(context, ref, before: vorherLevel));
    });
  }

  /// Öffnet die Tagestruhe — der seltene Moment, der laut sein darf.
  void _openChest(BuildContext context, WidgetRef ref) {
    final today = ref.read(todayProvider);
    final inhalt = ref.read(habitTrackerProvider.notifier).openChest(today);
    if (inhalt == null) return;

    unawaited(HapticFeedback.heavyImpact());
    ref
        .read(soundPlayerProvider)
        .play(
          inhalt.tier == ChestTier.schlicht
              ? SoundEffect.sieg
              : SoundEffect.errungenschaft,
        );
    unawaited(showChestReveal(context, inhalt));
  }

  /// Setzt ein Streak-Eis auf [tag].
  void _useFreeze(BuildContext context, WidgetRef ref, Day tag) {
    final today = ref.read(todayProvider);
    final gerettet = ref.read(habitTrackerProvider).currentBestStreak(tag);
    final erfolg = ref
        .read(habitTrackerProvider.notifier)
        .useStreakFreeze(tag, today);
    if (!erfolg) return;

    unawaited(HapticFeedback.mediumImpact());
    sayHabitFeedback(
      context,
      'Gestern ist gedeckt — deine Kette von $gerettet Tagen läuft '
      'weiter. Sie wird davon nicht länger.',
      icon: Icons.ac_unit,
    );
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
    return Druck(
      child: FloatingActionButton(
        onPressed: () => _offen ? onCreate() : _sageWarumNicht(context),
        backgroundColor: _offen ? Palette.accent : Palette.surfaceRaised,
        foregroundColor: _offen ? Palette.surface : Palette.muted,
        tooltip: _hinweis,
        // Dasselbe Zeichen wie vorher in der Liste, und bewusst ein
        // anderes als das Plus, mit dem eine fertige Vorlage gestartet
        // wird: Hier entsteht etwas Neues, dort wird etwas Vorhandenes
        // aufgenommen.
        child: const Icon(Icons.playlist_add),
      ),
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
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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

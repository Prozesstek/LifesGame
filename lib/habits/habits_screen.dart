import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../home/widgets/status_leiste.dart';
import '../progression/level_provider.dart';
import '../skills/widgets/gebiets_kacheln.dart';
import '../ui/palette.dart';
import 'cue_text.dart';
import 'habit_check_flow.dart';
import 'habits_controller.dart';
import 'widgets/cue_dialog.dart';
import 'widgets/habit_check_tile.dart';
import 'widgets/gewohnheit_anlegen.dart';
import 'widgets/streak_freeze_card.dart';
import 'widgets/weekday_picker.dart';
import '../ui/aufstieg.dart';
import '../ui/holz.dart';
import '../ui/druck.dart';
import '../ui/halten_und_ziehen.dart';

/// Der Tracker-Teil des Spiels: heute abhaken, sehen, was nicht heute
/// dran ist, und über den grünen Plus-Knopf eine neue Gewohnheit
/// anfangen (ADR-0089).
///
/// **Die Reiter „Eigene“ und „Vorerstellte“ sind weg**: Sie zeigten
/// dasselbe wie die Vorlagen im Plus-Knopf. Hier steht nur noch, was
/// läuft.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  /// Woran Tests den Plus-Knopf finden.
  static const Key plusKey = ValueKey<String>('neue-gewohnheit');

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);

    final active = tracker.stackOn(today);
    // Der Tag, den ein Streak-Eis gerade noch retten kann. Die Regel
    // dafür steht in `package:habits`, nicht hier.
    final zuRetten = tracker.rescuableDay(today);
    // Was läuft, aber heute nicht dran ist (ADR-0064). Es steht nicht in
    // „Heute", muss aber irgendwo stehen — sonst ließe es sich an sechs
    // von sieben Tagen weder ändern noch stoppen.
    final nichtHeute = tracker.activeHabitsByPriority
        .where((h) => !tracker.isDueOn(h.id, today))
        .toList(growable: false);

    // **Der Host liegt um den ganzen Bildschirm** (ADR-0092): Level und Gold
    // stehen in der Titelzeile, und was dorthin fliegen soll, muss sie
    // finden. Das `Material` gibt den aufsteigenden Zahlen ihre Schrift,
    // sonst stünden sie unterstrichen da.
    return Material(
      type: MaterialType.transparency,
      child: AufstiegHost(
        // Ein Kontext **unter** dem Host: Die Rückrufe der Kacheln lassen
        // darüber Zahlen aufsteigen (`AufstiegHost.maybeOf`).
        child: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Gewohnheiten'),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: StatusLeiste(
                    xp: ref.watch(effectiveXpProvider),
                    gold: ref.watch(goldProvider),
                    klein: true,
                  ),
                ),
              ],
            ),
            floatingActionButton: _PlusKnopf(
              onTap: () => _neueGewohnheit(context, ref),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Column(
                    children: <Widget>[
                      // **Die vier Gebiete stehen fest über der Liste**:
                      // Die Funken eines Häkchens fliegen hinein, also
                      // dürfen sie nicht mit weggerollt sein.
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: GebietsKacheln(),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                          children: <Widget>[
                            if (zuRetten != null) ...<Widget>[
                              StreakFreezeCard(
                                streakAtRisk: tracker.currentBestStreak(
                                  zuRetten,
                                ),
                                freezesLeft: tracker.freezesLeft,
                                onUse: () => _useFreeze(context, ref, zuRetten),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Offene oben, erledigte unten (`dailyListOn`).
                            // Der Schlüssel hält den Sprung des Häkchens
                            // an der Gewohnheit, wenn die Kachel die Reihe
                            // wechselt.
                            // Gekoppeltes steht eingerückt unter seinem Anker
                            // und leuchtet auf, sobald der abgehakt ist
                            // (ADR-0065). Die Ordnung kommt aus `stackOn`.
                            for (final eintrag in active) ...<Widget>[
                              _ImStapel(
                                key: ValueKey<String>(eintrag.habit.id),
                                depth: eintrag.depth,
                                cued: eintrag.isCued,
                                child: _kachel(
                                  context,
                                  ref,
                                  tracker,
                                  today,
                                  eintrag,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (nichtHeute.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(
                                  Icons.event_busy_rounded,
                                  size: 20,
                                  color: Palette.textOnDarkDim,
                                  semanticLabel: 'Heute nicht fällig',
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final habit in nichtHeute) ...<Widget>[
                                _NichtHeuteTile(
                                  key: ValueKey<String>(
                                    'nicht-heute-${habit.id}',
                                  ),
                                  habit: habit,
                                  weekdays: tracker.weekdaysFor(habit.id),
                                  streak: tracker.currentStreak(
                                    habit.id,
                                    today,
                                  ),
                                  onEdit: () => _editCue(context, ref, habit),
                                  onStop: () => ref
                                      .read(habitTrackerProvider.notifier)
                                      .deactivate(habit.id),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                            // Die Truhe stand bis zum 18.10. hier; sie wartet
                            // jetzt am Lagerfeuer (ADR-0076). Anlegen und die
                            // Vorlagen stehen seit ADR-0089 hinter dem
                            // Plus-Knopf.
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kachel(
    BuildContext context,
    WidgetRef ref,
    HabitTracker tracker,
    Day today,
    StackedHabit eintrag,
  ) {
    final habit = eintrag.habit;
    return HabitCheckTile(
      habit: habit,
      isChecked: tracker.isChecked(habit.id, today),
      streak: tracker.currentStreak(habit.id, today),
      xpGain: tracker.xpForNextCheck(habit.id, today),
      goldGain: tracker.goldForNextCheck(habit.id, today),
      progress: tracker.progressOn(habit.id, today),
      onToggle: () => tapHabit(context, ref, habit),
      onAdvance: () => advanceHabit(context, ref, habit),
      onTimer: tracker.hasTimer(habit.id)
          ? () => openHabitTimer(context, ref, habit)
          : null,
      onTimerDone: () => finishHabitTimer(context, ref, habit),
      onStop: () =>
          ref.read(habitTrackerProvider.notifier).deactivate(habit.id),
      cue: CueText.lineFor(tracker, habit.id),
      treat: tracker.treatFor(habit.id),
      days: Wochentage.zeile(tracker.weekdaysFor(habit.id)),
      cued: eintrag.isCued,
      onEditCue: () => _editCue(context, ref, habit),
    );
  }

  /// **Der grüne Plus-Knopf** (ADR-0089): eine neue Gewohnheit, eine
  /// Frage nach der anderen.
  ///
  /// Angelegt und gestartet wird erst hier, wenn alles beantwortet ist —
  /// wer abbricht, hat nichts verändert. Bis dahin legte das Formular
  /// an, und danach fragte ein Dialog nach dem Auslöser.
  Future<void> _neueGewohnheit(BuildContext context, WidgetRef ref) async {
    final tracker = ref.read(habitTrackerProvider);
    final wahl = await GewohnheitAnlegen.show(
      context,
      vorlagen: ref
          .read(unlockedHabitsProvider)
          .where((t) => !tracker.isActive(t.id))
          .toList(growable: false),
      ruhende: tracker.customHabits
          .where((h) => !tracker.isActive(h.id))
          .toList(growable: false),
      eigeneFrei: ref.read(customSlotsLeftProvider),
      listeVoll: tracker.isFull,
      ankerFuer: (id) => id == null
          ? tracker.activeHabitsByPriority
          : tracker.anchorCandidatesFor(id),
      hatAusloeser: (id) =>
          tracker.cueFor(id) != null || tracker.anchorFor(id) != null,
      tageFuer: tracker.weekdaysFor,
    );
    if (wahl == null || !context.mounted) return;

    final controller = ref.read(habitTrackerProvider.notifier);
    final Habit? habit = switch (wahl) {
      EigeneAngelegt(
        :final name,
        :final area,
        :final difficulty,
        :final goal,
      ) =>
        controller.addCustom(
          name: name,
          area: area,
          difficulty: difficulty,
          goal: goal,
        ),
      VorlageGestartet(:final habitId) => () {
        controller.activate(habitId);
        return ref.read(habitTrackerProvider).definitionFor(habitId);
      }(),
    };
    if (habit == null) {
      sayHabitFeedback(
        context,
        'Kein Platz frei — dafür braucht es eine weitere Vorlage '
        'aus dem Skillbaum.',
      );
      return;
    }

    final laeuft = ref.read(habitTrackerProvider).isActive(habit.id);
    if (laeuft) {
      if (wahl.einrichtung case final einrichtung?) {
        _richteEin(ref, habit.id, einrichtung);
      }
    }
    sayHabitFeedback(
      context,
      laeuft
          ? '„${habit.name}" steht ab heute auf der Liste.'
          : '„${habit.name}" ist angelegt — die Tagesliste ist voll, '
                'sie wartet bei den Vorlagen.',
    );
  }

  /// Übernimmt, was am Ende gefragt wurde: Satz oder Anker, Belohnung,
  /// Wochentage. Welcher den anderen ersetzt, entscheidet der Tracker.
  void _richteEin(WidgetRef ref, String habitId, Einrichtung einrichtung) {
    final controller = ref.read(habitTrackerProvider.notifier);
    if (einrichtung.anchorId case final anker?) {
      controller.setAnchor(habitId, anker);
    } else {
      controller
        ..setAnchor(habitId, null)
        ..setCue(habitId, einrichtung.cue);
    }
    controller
      ..setTreat(habitId, einrichtung.treat)
      ..setWeekdays(habitId, einrichtung.weekdays);
  }

  Future<void> _editCue(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    final tracker = ref.read(habitTrackerProvider);
    final today = ref.read(todayProvider);
    final wahl = await showCueDialog(
      context,
      habitName: habit.name,
      current: tracker.cueFor(habit.id),
      weekdays: tracker.weekdaysFor(habit.id),
      weekdaysFromTomorrow:
          tracker.weekdaysChangeFrom(habit.id, today) != today,
      anchors: tracker.anchorCandidatesFor(habit.id),
      currentAnchorId: tracker.anchorFor(habit.id),
      currentTreat: tracker.treatFor(habit.id),
    );
    if (wahl == null || !context.mounted) return;
    final controller = ref.read(habitTrackerProvider.notifier);
    // Satz oder Anker — welcher den anderen ersetzt, entscheidet der
    // Tracker; hier wird nur das Gewählte hingereicht.
    final anker = wahl.anchorId;
    if (anker != null) {
      controller.setAnchor(habit.id, anker);
    } else {
      controller
        ..setAnchor(habit.id, null)
        ..setCue(habit.id, wahl.cue);
    }
    controller
      ..setTreat(habit.id, wahl.treat)
      ..setWeekdays(habit.id, wahl.weekdays);
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

/// **Der grüne Plus-Knopf unten rechts** (ADR-0089) — der einzige Weg zu
/// einer neuen Gewohnheit, eigen oder aus einer Vorlage. Er ist immer
/// da; was gerade nicht geht, sagt das Blatt dahinter.
class _PlusKnopf extends StatelessWidget {
  const _PlusKnopf({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Druck(
      child: FloatingActionButton(
        key: HabitsScreen.plusKey,
        onPressed: onTap,
        backgroundColor: Palette.successOnDark,
        foregroundColor: Palette.background,
        shape: const CircleBorder(),
        tooltip: 'Neue Gewohnheit',
        child: const Icon(Icons.add_rounded, size: 34),
      ),
    );
  }
}

/// Rückt eine Kachel unter ihren Anker und lässt sie aufleuchten, wenn
/// sie **jetzt dran** ist (ADR-0065).
class _ImStapel extends StatelessWidget {
  const _ImStapel({
    required this.depth,
    required this.cued,
    required this.child,
    super.key,
  });

  /// Je Stufe so weit nach rechts — und nie weiter als drei Stufen: Ein
  /// Stapel aus fünf Gliedern ließe der letzten Kachel sonst keine Breite.
  static const double _schritt = 14;
  static const int _hoechstens = 3;

  final int depth;
  final bool cued;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stufen = depth > _hoechstens ? _hoechstens : depth;
    return Padding(
      padding: EdgeInsets.only(left: _schritt * stufen),
      child: PlatzLaedtEin(aktiv: cued, child: child),
    );
  }
}

/// Eine laufende Gewohnheit, die heute nicht dran ist: ihr Name, ihre
/// Tage, ihre Kette. Antippen ändert Auslöser und Tage, das Kreuz stoppt.
///
/// **Nicht abhakbar**, und so sieht sie auch aus: matt und ohne Kreis
/// links (ADR-0064).
class _NichtHeuteTile extends StatelessWidget {
  const _NichtHeuteTile({
    required this.habit,
    required this.weekdays,
    required this.streak,
    required this.onEdit,
    required this.onStop,
    super.key,
  });

  final Habit habit;
  final Set<int> weekdays;
  final int streak;
  final VoidCallback onEdit;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Druck(
      child: HolzKarte(
        padding: EdgeInsets.zero,
        color: Palette.surfaceRaised,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Palette.textDim,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Wochentage.zeile(weekdays) ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Palette.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (streak > 0) ...<Widget>[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Palette.gold,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$streak',
                      semanticsLabel: '$streak am Stück',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Palette.gold,
                      ),
                    ),
                  ],
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
}

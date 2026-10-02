import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../ui/palette.dart';
import 'cue_text.dart';
import 'habit_check_flow.dart';
import 'habits_controller.dart';
import 'stat_icon.dart';
import 'widgets/cue_dialog.dart';
import 'widgets/custom_habit_sheet.dart';
import 'widgets/daily_chest_card.dart';
import 'widgets/habit_check_tile.dart';
import 'widgets/habit_template_tile.dart';
import 'widgets/streak_freeze_card.dart';
import 'widgets/weekday_picker.dart';
import '../ui/aufstieg.dart';
import '../ui/holz.dart';
import '../ui/druck.dart';
import '../ui/halten_und_ziehen.dart';

/// Der Tracker-Teil des Spiels: heute abhaken, Vorlagen wählen, eigene
/// Gewohnheiten anlegen, sehen, was das mit dem Charakter macht.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final unlocked = ref.watch(unlockedHabitsProvider);
    final today = ref.watch(todayProvider);
    final slots = ref.watch(customSlotsProvider);
    final slotsLeft = ref.watch(customSlotsLeftProvider);

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
    final availableTemplates = unlocked
        .where((t) => !tracker.isActive(t.id))
        .toList(growable: false);
    final ruhendeEigene = tracker.customHabits
        .where((h) => !tracker.isActive(h.id))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Gewohnheiten')),

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
                    // **„Heute“ steht oben** (Issue #88). Werte, Kette,
                    // Tagesform, Aufgaben, Rückfrage und Woche standen bis
                    // zum 28.09. darüber und sind umgezogen: Werte und
                    // Woche in den Charakter, Tagesform in die Grube, die
                    // Aufgaben auf die Startseite, die Rückfrage in die
                    // Theorie. Die Kette steht an jeder Kachel.
                    if (zuRetten != null) ...<Widget>[
                      StreakFreezeCard(
                        streakAtRisk: tracker.currentBestStreak(zuRetten),
                        freezesLeft: tracker.freezesLeft,
                        onUse: () => _useFreeze(context, ref, zuRetten),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionHeader(
                      trailing:
                          '${tracker.completedOn(today)} / ${active.length}',
                    ),
                    const SizedBox(height: 10),
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
                        child: _kachel(context, ref, tracker, today, eintrag),
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
                          key: ValueKey<String>('nicht-heute-${habit.id}'),
                          habit: habit,
                          weekdays: tracker.weekdaysFor(habit.id),
                          streak: tracker.currentStreak(habit.id, today),
                          onEdit: () => _editCue(context, ref, habit),
                          onStop: () => ref
                              .read(habitTrackerProvider.notifier)
                              .deactivate(habit.id),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    if (tracker.canOpenChest(today) ||
                        tracker.hasOpenedChest(today)) ...<Widget>[
                      const SizedBox(height: 4),
                      DailyChestCard(
                        canOpen: tracker.canOpenChest(today),
                        opened: tracker.hasOpenedChest(today)
                            ? DailyChest.forDay(today)
                            : null,
                        onOpen: () => openDailyChest(context, ref),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // **Über den Reitern, nicht in einem**: Anlegen soll
                    // man immer sehen, auch wenn „Vorerstellte“ offen ist.
                    _NeueGewohnheitKnopf(
                      slotsLeft: slotsLeft,
                      listeVoll: tracker.isFull,
                      onCreate: () => _createCustom(context, ref),
                    ),
                    const SizedBox(height: 12),
                    _VorlagenReiter(
                      startMitEigenen: tracker.customCount > 0,
                      eigeneZaehler: '${tracker.customCount} / $slots',
                      vorerstellteZaehler:
                          '${tracker.activeIds.length} / '
                          '${HabitRewards.maxActiveHabits}',
                      eigene: <Widget>[
                        for (final habit in ruhendeEigene)
                          _RestingCustomTile(
                            habit: habit,
                            canActivate: tracker.canActivate(habit.id),
                            onActivate: () => _activate(context, ref, habit),
                          ),
                      ],
                      vorerstellte: <Widget>[
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
                  ],
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
      nextMultiplier: tracker.nextMultiplier(habit.id, today),
      xpGain: tracker.xpForNextCheck(habit.id, today),
      goldGain: tracker.goldForNextCheck(habit.id, today),
      progress: tracker.progressOn(habit.id, today),
      onToggle: () => toggleHabit(context, ref, habit),
      onAdvance: () => advanceHabit(context, ref, habit),
      onStop: () =>
          ref.read(habitTrackerProvider.notifier).deactivate(habit.id),
      cue: CueText.lineFor(tracker, habit.id),
      days: Wochentage.zeile(tracker.weekdaysFor(habit.id)),
      cued: eintrag.isCued,
      onEditCue: () => _editCue(context, ref, habit),
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
    if (!tracker.isActive(habit.id) ||
        tracker.cueFor(habit.id) != null ||
        tracker.anchorFor(habit.id) != null) {
      return;
    }
    await _editCue(context, ref, habit);
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
    controller.setWeekdays(habit.id, wahl.weekdays);
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

/// „Neue Gewohnheit“ über den Reitern — und der Grund, wenn es nicht
/// geht.
///
/// **Bis zum 28.09. ein schwebender Knopf unten rechts** (Issue #35).
/// Seit Eigene und Vorerstellte Reiter sind (Issue #88), steht er über
/// ihnen, als Knopf in voller Breite. Ohne freien Platz bleibt er sichtbar, wird aber
/// matt und erklärt beim Antippen, woran es liegt: Die Antwort („jede
/// freigeschaltete Vorlage gibt einen Platz“) ist der Weg zurück in den
/// Skillbaum.
class _NeueGewohnheitKnopf extends StatelessWidget {
  const _NeueGewohnheitKnopf({
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
    // Die Planke kommt aus dem Theme. Ohne freien Platz wird sie matt,
    // bleibt aber tippbar — der Tipp sagt, warum.
    return Tooltip(
      message: _hinweis,
      child: Opacity(
        opacity: _offen ? 1 : 0.5,
        child: FilledButton.icon(
          onPressed: () => _offen ? onCreate() : _sageWarumNicht(context),
          icon: const Icon(Icons.playlist_add),
          // Kein Wort, nur wie viele Plätze frei sind; der Tooltip sagt
          // den Rest.
          label: Text(
            '$slotsLeft',
            semanticsLabel: 'Neue Gewohnheit, $slotsLeft frei',
          ),
        ),
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

/// „Eigene“ und „Vorerstellte“ als zwei Reiter unter der Tagesliste
/// (Issue #88). Bis zum 28.09. standen beide als Abschnitte untereinander,
/// und wer eine eigene anlegen wollte, suchte den Knopf unten rechts.
///
/// **Die Wahl gehört zur Ansicht**, nicht zum Spielstand. Wer noch keine
/// eigene hat, sieht zuerst die vorerstellten — dort ist etwas zu
/// starten; sonst die eigenen.
class _VorlagenReiter extends StatefulWidget {
  const _VorlagenReiter({
    required this.startMitEigenen,
    required this.eigene,
    required this.vorerstellte,
    required this.eigeneZaehler,
    required this.vorerstellteZaehler,
  });

  final bool startMitEigenen;
  final List<Widget> eigene;
  final List<Widget> vorerstellte;
  final String eigeneZaehler;
  final String vorerstellteZaehler;

  @override
  State<_VorlagenReiter> createState() => _VorlagenReiterState();
}

class _VorlagenReiterState extends State<_VorlagenReiter> {
  late bool _eigene = widget.startMitEigenen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _Reiter(
                icon: Icons.person_rounded,
                titel: 'Eigene',
                zaehler: widget.eigeneZaehler,
                aktiv: _eigene,
                onTap: () => setState(() => _eigene = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Reiter(
                icon: Icons.auto_stories_rounded,
                titel: 'Vorerstellte',
                zaehler: widget.vorerstellteZaehler,
                aktiv: !_eigene,
                onTap: () => setState(() => _eigene = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_eigene ? widget.eigene : widget.vorerstellte),
      ],
    );
  }
}

class _Reiter extends StatelessWidget {
  const _Reiter({
    required this.icon,
    required this.titel,
    required this.zaehler,
    required this.aktiv,
    required this.onTap,
  });

  final IconData icon;

  /// Nur für den Vorleser — zu sehen ist das Zeichen.
  final String titel;
  final String zaehler;
  final bool aktiv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: aktiv,
      label: titel,
      child: Druck(
        child: Material(
          color: aktiv ? Palette.accentOnDark : Palette.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 20, color: Palette.text),
                  const SizedBox(width: 8),
                  Text(
                    zaehler,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.textDim,
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
                Row(
                  children: <Widget>[
                    StatIcon(habit.stat, size: 16),
                    const SizedBox(width: 8),
                    _Grad(habit.difficulty),
                    if (habit.goal case final goal?) ...<Widget>[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          goal.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Palette.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
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

/// Der Schwierigkeitsgrad als ein bis drei Punkte statt als Wort.
class _Grad extends StatelessWidget {
  const _Grad(this.grad);

  final HabitDifficulty grad;

  @override
  Widget build(BuildContext context) {
    final stufe = HabitDifficulty.values.indexOf(grad) + 1;
    return Semantics(
      label: grad.label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < HabitDifficulty.values.length; i++)
            Icon(
              Icons.circle,
              size: 7,
              color: i < stufe ? Palette.accent : Palette.surfaceSunken,
            ),
        ],
      ),
    );
  }
}

/// „Heute“ als Zeichen, daneben der Stand.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.trailing});

  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Icon(
          Icons.checklist_rounded,
          size: 22,
          color: Palette.textOnDark,
          semanticLabel: 'Heute',
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

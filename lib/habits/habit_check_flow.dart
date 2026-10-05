/// Was ein Häkchen auslöst — Klang, Stoß, Feiern, aufsteigende Zahlen,
/// die Leiste unten.
///
/// **Eine Stelle für jeden Ort, an dem abgehakt wird.** Bis zur Startseite
/// mit „Heute" gab es nur den Gewohnheiten-Bildschirm, und alles stand
/// dort. Zwei Kopien davon wären der Fall aus `gotchas.md`: Irgendwann
/// feiert die eine eine Errungenschaft, die andere nicht.
///
/// Rechnet nichts — die Zahlen kommen aus dem Tracker und den Providern.
library;

import 'dart:async';

import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../achievements/show_achievement_unlock.dart';
import '../audio/sound_effects.dart';
import '../character/abilities_controller.dart';
import '../character/show_ability_unlock.dart';
import '../gear/gear_controller.dart';
import '../gear/gear_icon.dart';
import '../progression/show_level_up.dart';
import '../ui/aufstieg.dart';
import '../ui/palette.dart';
import 'daily_form_text.dart';
import 'habits_controller.dart';
import 'widgets/daily_chest_card.dart';
import 'widgets/habit_timer_sheet.dart';

/// Hakt [habit] ab oder nimmt das Häkchen zurück.
void toggleHabit(BuildContext context, WidgetRef ref, Habit habit) {
  final today = ref.read(todayProvider);
  _mitFeier(context, ref, habit, (tracker) => tracker.toggle(habit.id, today));
}

/// **Der Tipp auf eine Gewohnheit** — auf der Kachel wie in „Heute“.
///
/// Eine offene Gewohnheit mit Zeitziel öffnet ihren Timer (ADR-0067):
/// Zwanzig Minuten hakt man nicht mit einem Tipp ab. Alles andere hakt
/// ab oder nimmt zurück, wie immer.
void tapHabit(BuildContext context, WidgetRef ref, Habit habit) {
  final tracker = ref.read(habitTrackerProvider);
  final offen = !tracker.isChecked(habit.id, ref.read(todayProvider));
  if (offen && tracker.hasTimer(habit.id)) {
    unawaited(openHabitTimer(context, ref, habit));
    return;
  }
  toggleHabit(context, ref, habit);
}

/// Öffnet den Timer von [habit] und hakt ab, wenn das Blatt es meldet —
/// weil die Zeit abgelaufen ist oder weil jemand „schon erledigt“ sagt.
///
/// Gefeiert wird **hier**, mit dem Kontext dessen, der geöffnet hat: Der
/// des Blatts ist dann schon weg.
Future<void> openHabitTimer(
  BuildContext context,
  WidgetRef ref,
  Habit habit,
) async {
  final ende = await showHabitTimerSheet(context, habit);
  if (ende == null || !context.mounted) return;

  // Einen Bildaufbau später, wie nach jedem Dialog (`gotchas.md`).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    switch (ende) {
      case HabitTimerEnde.abgelaufen:
        finishHabitTimer(context, ref, habit);
      case HabitTimerEnde.erledigt:
        final heute = ref.read(todayProvider);
        if (ref.read(habitTrackerProvider).isChecked(habit.id, heute)) return;
        toggleHabit(context, ref, habit);
    }
  });
}

/// Rechnet den laufenden Timer ab: Ist er bei null, ist [habit] damit
/// abgehakt — mit allem, was ein Häkchen von Hand auslöst.
///
/// Harmlos, wenn es nichts abzurechnen gibt. Blatt und Kachel dürfen
/// beide rufen; gefeiert wird nur beim ersten.
void finishHabitTimer(BuildContext context, WidgetRef ref, Habit habit) {
  _mitFeier(context, ref, habit, (tracker) => tracker.settleTimer());
}

/// Führt [tat] aus und macht daraus ein Häkchen, das sich anfühlt wie
/// eins — **die eine Stelle** für Tipp, Plus und Timer.
///
/// [tat] gibt null zurück, wenn nichts verdient wurde (zurückgenommen,
/// Timer noch nicht fertig). Ein Schritt, der das Ziel noch nicht
/// erreicht, geht an [halb].
void _mitFeier(
  BuildContext context,
  WidgetRef ref,
  Habit habit,
  CheckResult? Function(HabitsController tracker) tat, {
  void Function(CheckResult result)? halb,
}) {
  final vorher = ref.read(unlockedAbilitiesProvider);
  final vorherErrungen = achievementsBefore(ref);
  final vorherLevel = levelBefore(ref);
  final werteVorher = ref.read(characterStatsProvider);
  final formVorher = ref.read(dailyFormProvider);
  final schluesselVorher = ref.read(availableKeysProvider);

  final result = tat(ref.read(habitTrackerProvider.notifier));
  if (result == null) return;
  if (!result.isComplete) {
    halb?.call(result);
    return;
  }

  // Ein Häkchen soll sich anfühlen wie eins. Auf einem Handy ist das
  // ein kurzer Stoß; im Browser und im Test passiert nichts.
  unawaited(HapticFeedback.mediumImpact());
  ref.read(soundPlayerProvider).play(_klang(ref, habit, werteVorher));
  _celebrate(context, ref, vorher, vorherErrungen, vorherLevel);
  sayHabitFeedback(
    context,
    _feedback(result, _gains(ref, habit, werteVorher, formVorher)),
    treat: _danach(ref, habit),
  );
  _steigen(
    context,
    ref,
    result,
    habit,
    werteVorher,
    formVorher,
    schluesselVorher,
  );
}

/// Holt eine erledigte Tagesaufgabe ab (ADR-0055): Klang, Stoß, und
/// der Schlüssel steigt dort auf, wo getippt wurde.
///
/// Ist der Vorrat voll, verfällt der Schlüssel (`GearKeys`) — dann steht
/// das auch da, statt „+1 Schlüssel" zu behaupten.
void claimDailyQuest(BuildContext context, WidgetRef ref, DailyQuest quest) {
  final schluesselVorher = ref.read(availableKeysProvider);
  final geaendert = ref.read(habitTrackerProvider.notifier).claimQuest(quest);
  if (!geaendert) return;

  unawaited(HapticFeedback.mediumImpact());
  ref.read(soundPlayerProvider).play(SoundEffect.beute);
  AufstiegHost.maybeOf(context)?.zeige(<AufstiegZeile>[
    keyGainLine(ref, schluesselVorher) ??
        const AufstiegZeile(
          'Aufgabe erledigt — Schlüssel voll',
          color: Palette.goldOnDark,
        ),
  ]);
}

/// Öffnet die Tagestruhe (ADR-0044) — der seltene Moment, der laut sein
/// darf. **Eine Stelle** für Startseite und Gewohnheiten-Bildschirm.
void openDailyChest(BuildContext context, WidgetRef ref) {
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

/// Ein Schritt auf ein Tagesziel.
void advanceHabit(BuildContext context, WidgetRef ref, Habit habit) {
  final today = ref.read(todayProvider);
  _mitFeier(
    context,
    ref,
    habit,
    (tracker) => tracker.advance(habit.id, today),
    halb: (result) {
      unawaited(HapticFeedback.selectionClick());
      final goal = habit.goal;
      sayHabitFeedback(
        context,
        goal == null
            ? '${result.progress} / ${result.required}'
            : goal.progressLabel(result.progress),
      );
    },
  );
}

/// Vier Fähigkeiten hängen an Streak-Marken (ADR-0022). Genau hier
/// reißt eine Kette weiter — und nur hier ist der Moment, in dem sich
/// eine Marke überschreiten lässt.
/// **Errungenschaften zuerst, Faehigkeiten danach.** Eine
/// Errungenschaft kann eine Faehigkeit mitbringen (ADR-0033, Punkt 7);
/// andersherum stuende die Faehigkeit da, bevor gesagt waere, woher sie
/// kommt.
void _celebrate(
  BuildContext context,
  WidgetRef ref,
  List<Ability> vorher,
  Set<String> vorherErrungen,
  int vorherLevel,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    unawaited(() async {
      await showAchievementUnlocks(context, ref, before: vorherErrungen);
      if (!context.mounted) return;
      await showLevelUp(context, ref, before: vorherLevel);
      if (!context.mounted) return;
      await showAbilityUnlocks(context, ref, before: vorher);
    }());
  });
}

/// Was es nach [habit] gibt — die Belohnung, die sich jemand selbst
/// versprochen hat (ADR-0066), oder null.
String? _danach(WidgetRef ref, Habit habit) =>
    ref.read(habitTrackerProvider).treatFor(habit.id);

/// Die Rückmeldung unten.
///
/// Mit [treat] steht darunter groß „Jetzt: Kaffee" — das Versprechen wird
/// in dem Moment fällig, in dem das Häkchen sitzt.
///
/// Das Zeichen ist bewusst **nicht** `Icons.check_circle`: Das trägt
/// die Kachel, und zwei gleiche Zeichen im selben Bild lesen sich als
/// dasselbe Ding. Hier steht der Ertrag, nicht das Häkchen.
void sayHabitFeedback(
  BuildContext context,
  String text, {
  IconData icon = Icons.auto_awesome,
  String? treat,
}) {
  final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: Palette.success),
          const SizedBox(width: 10),
          Expanded(
            child: treat == null
                ? Text(text, style: const TextStyle(color: Palette.text))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(text, style: const TextStyle(color: Palette.text)),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.redeem_rounded,
                            size: 18,
                            color: Palette.gold,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Jetzt: $treat',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: Palette.surfaceRaised,
    ),
  );
}

/// Der Punkt, den dieses Häkchen auf einem Charakterwert gebracht hat —
/// oder ein leerer Text.
///
/// **Fünf Häkchen sind ein Punkt Stärke**, das Abhaken zahlt also nur
/// jedes fünfte Mal sichtbar aus. Der Balken in der Kopfzeile bewegt
/// sich jedes Mal; wenn der Punkt fällt, soll es außerdem jemand sagen.
String _statGain(WidgetRef ref, Habit habit, CharacterStats vorher) {
  final nachher = ref.read(characterStatsProvider);
  final zuwachs = nachher.valueFor(habit.stat) - vorher.valueFor(habit.stat);
  if (zuwachs <= 0) return '';
  return ' · +$zuwachs ${habit.stat.label}';
}

/// Welcher Klang zu diesem Häkchen gehört: der seltenere, wenn dabei ein
/// Punkt gefallen ist. Fünf Häkchen sind ein Punkt Stärke — der fünfte
/// soll anders klingen als die vier davor.
SoundEffect _klang(WidgetRef ref, Habit habit, CharacterStats werteVorher) {
  final nachher = ref.read(characterStatsProvider).valueFor(habit.stat);
  return nachher > werteVorher.valueFor(habit.stat)
      ? SoundEffect.statPunkt
      : SoundEffect.haekchen;
}

/// **Die Zahlen steigen dort auf, wo getippt wurde** — Erfahrung, Gold,
/// ein gewonnener Punkt und die Tagesform. Dasselbe, was die Leiste unten
/// sagt, nur dort, wo der Blick ist.
void _steigen(
  BuildContext context,
  WidgetRef ref,
  CheckResult result,
  Habit habit,
  CharacterStats werteVorher,
  DailyForm formVorher,
  int schluesselVorher,
) {
  final nachher = ref.read(characterStatsProvider);
  final punkt = nachher.valueFor(habit.stat) - werteVorher.valueFor(habit.stat);
  final form = DailyFormText.gainAfterCheck(
    stat: habit.stat,
    vorher: formVorher,
    nachher: ref.read(dailyFormProvider),
  );
  AufstiegHost.maybeOf(context)?.zeige(<AufstiegZeile>[
    AufstiegZeile(
      '+${result.xpGained} EP  +${result.goldGained} G',
      color: Palette.goldOnDark,
    ),
    if (punkt > 0)
      AufstiegZeile(
        '+$punkt ${habit.stat.label}',
        color: Palette.successOnDark,
      ),
    if (form.isNotEmpty)
      AufstiegZeile(
        form.startsWith('In Form') ? 'In Form!' : form,
        color: Palette.accentOnDark,
      ),
    ?keyGainLine(ref, schluesselVorher),
  ]);
}

/// „+1 Schlüssel" — aber nur, wenn wirklich einer dazukam. Bei zehn auf
/// Vorrat verfällt er (`GearKeys`), und dann wäre die Zeile gelogen.
AufstiegZeile? keyGainLine(WidgetRef ref, int vorher) {
  if (ref.read(availableKeysProvider) <= vorher) return null;
  return const AufstiegZeile(
    '+1 Schlüssel',
    color: Palette.goldOnDark,
    bild: GearIcons.schluessel,
  );
}

/// Alles, was sich an ein Häkchen anhängt: ein gewonnener Punkt und
/// die Tagesform, die es heute gehoben hat.
String _gains(
  WidgetRef ref,
  Habit habit,
  CharacterStats werteVorher,
  DailyForm formVorher,
) {
  final form = DailyFormText.gainAfterCheck(
    stat: habit.stat,
    vorher: formVorher,
    nachher: ref.read(dailyFormProvider),
  );
  final punkt = _statGain(ref, habit, werteVorher);
  return form.isEmpty ? punkt : '$punkt · $form';
}

/// Was nach einem Häkchen in der Leiste steht.
///
/// Ein erreichter Meilenstein verdrängt den Ertrag: Beides zusammen ist
/// eine Zeile zu viel, und der Meilenstein ist die seltenere Nachricht.
/// Ein gewonnener Charakterpunkt hängt sich dagegen an beides an — er
/// ist die Verbindung zum Kampf und damit der Grund für das Ganze.
String _feedback(CheckResult result, String statGain) {
  final milestone = result.reachedMilestone;
  if (milestone != null) {
    final faktor = milestone.multiplier.toStringAsFixed(1).replaceAll('.', ',');
    return '${milestone.days} Tage am Stück — ab jetzt x$faktor$statGain';
  }
  return '+${result.xpGained} Erfahrung · +${result.goldGained} Gold'
      '$statGain';
}

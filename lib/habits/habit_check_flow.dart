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

/// Hakt [habit] ab oder nimmt das Häkchen zurück.
void toggleHabit(BuildContext context, WidgetRef ref, Habit habit) {
  final today = ref.read(todayProvider);
  final vorher = ref.read(unlockedAbilitiesProvider);
  final vorherErrungen = achievementsBefore(ref);
  final vorherLevel = levelBefore(ref);
  final werteVorher = ref.read(characterStatsProvider);
  final formVorher = ref.read(dailyFormProvider);
  final schluesselVorher = ref.read(availableKeysProvider);

  final result = ref
      .read(habitTrackerProvider.notifier)
      .toggle(habit.id, today);
  if (result == null) return;

  // Ein Häkchen soll sich anfühlen wie eins. Auf einem Handy ist das
  // ein kurzer Stoß; im Browser und im Test passiert nichts.
  unawaited(HapticFeedback.mediumImpact());
  ref.read(soundPlayerProvider).play(_klang(ref, habit, werteVorher));
  _celebrate(context, ref, vorher, vorherErrungen, vorherLevel);
  sayHabitFeedback(
    context,
    _feedback(result, _gains(ref, habit, werteVorher, formVorher)),
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

/// Ein Schritt auf ein Tagesziel.
void advanceHabit(BuildContext context, WidgetRef ref, Habit habit) {
  final today = ref.read(todayProvider);
  final vorher = ref.read(unlockedAbilitiesProvider);
  final vorherErrungen = achievementsBefore(ref);
  final vorherLevel = levelBefore(ref);
  final werteVorher = ref.read(characterStatsProvider);
  final formVorher = ref.read(dailyFormProvider);
  final schluesselVorher = ref.read(availableKeysProvider);

  final result = ref
      .read(habitTrackerProvider.notifier)
      .advance(habit.id, today);

  if (!result.isComplete) {
    unawaited(HapticFeedback.selectionClick());
    final goal = habit.goal;
    sayHabitFeedback(
      context,
      goal == null
          ? '${result.progress} / ${result.required}'
          : goal.progressLabel(result.progress),
    );
    return;
  }

  unawaited(HapticFeedback.mediumImpact());
  ref.read(soundPlayerProvider).play(_klang(ref, habit, werteVorher));
  _celebrate(context, ref, vorher, vorherErrungen, vorherLevel);
  sayHabitFeedback(
    context,
    _feedback(result, _gains(ref, habit, werteVorher, formVorher)),
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

/// Die Rückmeldung unten.
///
/// Das Zeichen ist bewusst **nicht** `Icons.check_circle`: Das trägt
/// die Kachel, und zwei gleiche Zeichen im selben Bild lesen sich als
/// dasselbe Ding. Hier steht der Ertrag, nicht das Häkchen.
void sayHabitFeedback(
  BuildContext context,
  String text, {
  IconData icon = Icons.auto_awesome,
}) {
  final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: Palette.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Palette.text)),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../habits/daily_quests_provider.dart';
import '../habits/habit_check_flow.dart';
import '../habits/habits_controller.dart';
import '../habits/widgets/daily_chest_card.dart';
import '../habits/widgets/daily_quests_card.dart';
import '../habits/widgets/week_card.dart';
import '../home/erster_start_provider.dart';
import '../theory/review_controller.dart';
import '../theory/widgets/review_section.dart';
import '../ui/aufstieg.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'am_feuer_provider.dart';
import 'widgets/feuer_bild.dart';
import 'widgets/morgen_zuerst.dart';

/// **Das Lagerfeuer** (ADR-0076): Der Tag endet an einer Stelle.
///
/// Unter dem Feuer liegt, was sonst an drei Orten verfiel: die Rückfrage
/// des Tages, die Truhe, die Tagesaufgaben — sonntags und montags dazu
/// der Wochenrückblick. Zum Schluss tippt man an, was morgen zuerst
/// drankommt, und ein Satz schickt einen weg.
///
/// **Truhe und Aufgaben gibt es nur noch hier**; die Rückfrage steht
/// zusätzlich in der Theorie. Alles verfällt weiter um Mitternacht, und
/// das Feuer erzeugt keine eigene Zahl.
class LagerfeuerScreen extends ConsumerWidget {
  const LagerfeuerScreen({super.key});

  /// Der Satz zum Schluss — das Spiel, das dich wegschickt (ADR-0071).
  static const String schluss = 'Genug für heute. Leg das Handy weg.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final morgen = today.next;
    final tracker = ref.watch(habitTrackerProvider);
    final amFeuer = ref.watch(amFeuerProvider);
    final aufgaben = ref.watch(dailyQuestsProvider);
    final lastWeek = ref.watch(lastWeekProvider);
    final zeigtAufgaben =
        ref.watch(ersterStartProvider).zeigtTagesaufgaben &&
        aufgaben.isNotEmpty;

    // Die Reihenfolge ohne Vorsatz, damit die Knöpfe beim Wählen stehen
    // bleiben (`MorgenZuerst`).
    final morgenFaellig = <Habit>[
      for (final habit in tracker.activeHabitsByPriority)
        if (tracker.isDueOn(habit.id, morgen)) habit,
    ];

    final teile = <Widget>[
      if (ref.watch(todaysReviewProvider) != null) const ReviewSection(),
      if (tracker.canOpenChest(today) || tracker.hasOpenedChest(today))
        DailyChestCard(
          canOpen: tracker.canOpenChest(today),
          opened: tracker.hasOpenedChest(today)
              ? DailyChest.forDay(today)
              : null,
          onOpen: () => openDailyChest(context, ref),
        ),
      if (zeigtAufgaben)
        DailyQuestsCard(
          quests: aufgaben,
          isClaimed: (q) => tracker.isQuestClaimed(today, q.id),
          onClaim: (q) => claimDailyQuest(context, ref, q),
        ),
      if (WeekCard.istGross(today, lastWeek))
        WeekCard(
          today: today,
          thisWeek: ref.watch(thisWeekProvider),
          lastWeek: lastWeek,
        ),
      MorgenZuerst(
        habits: morgenFaellig,
        gewaehlt: tracker.firstUpOn(morgen),
        onWaehle: (id) =>
            ref.read(habitTrackerProvider.notifier).setFirstUp(morgen, id),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lagerfeuer'),
        // Derselbe Himmel wie oben im Bild — der Balken ist ein Stück
        // Nacht, keine Leiste aus Leder darüber.
        backgroundColor: FeuerBild.nachtOben,
        surfaceTintColor: Colors.transparent,
      ),
      body: AufstiegHost(
        child: OnDark(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              FeuerBild(brennt: amFeuer.brennt, hoehe: 240),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Jeder Teil ein eigener Knoten für den Vorleser,
                        // und darin jede Zeile: Die Liste hat nur einen
                        // Eintrag, und ohne Grenze läsen sich Rückfrage,
                        // Truhe und Aufgaben als ein einziger Satz.
                        for (final teil in teile) ...<Widget>[
                          Semantics(
                            container: true,
                            explicitChildNodes: true,
                            child: teil,
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          schluss,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            color: Palette.textOnDarkDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

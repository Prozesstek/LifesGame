import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../achievements/achievements_controller.dart';
import '../character/abilities_controller.dart';
import '../combat/ladder_controller.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../theory/theory_controller.dart';
import 'erster_start.dart';

/// Welche Bereiche die Startseite zeigt — **rechnet nichts**, trägt nur
/// zusammen (ADR-0068).
///
/// Die meisten Zahlen kommen aus [achievementStatsProvider]: Dort steht
/// schon, was nur wachsen darf. Tests anderer Bereiche überschreiben
/// diesen Provider mit [ErsterStart.allesOffen].
final ersterStartProvider = Provider<ErsterStart>((ref) {
  final zahlen = ref.watch(achievementStatsProvider);
  final habits = ref.watch(habitTrackerProvider);
  final reihe = ref.watch(ladderProvider);

  return ErsterStart.aus(
    ErsterStartStand(
      hatGewohnheit:
          habits.activeIds.isNotEmpty || habits.customHabits.isNotEmpty,
      haekchen: zahlen.totalChecks,
      // Gewonnen oder verloren — beides ist „war unten“.
      hatGekaempft: reihe.highestDefeated > 0 || reihe.defeats.isNotEmpty,
      seiten: zahlen.passedLessons,
      handbuchFertig: ref.watch(handbookDoneProvider),
      gelernt: ref.watch(unlockedAbilitiesProvider).length,
      // Der erste Eintrag ist immer der Waffenzug.
      angelegt: ref.watch(activeMovesProvider).length - 1,
      goldVerdient: ref.watch(goldEarnedProvider),
      billigstesStueck: GearCatalog.cheapestPrice,
      jeBesessen: zahlen.everOwnedCount,
      level: ref.watch(playerLevelProvider).level,
    ),
  );
});

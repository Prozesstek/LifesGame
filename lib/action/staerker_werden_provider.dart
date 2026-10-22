import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:progression/progression.dart';

import '../character/abilities_controller.dart';
import '../combat/ladder_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../theory/theory_controller.dart';
import 'staerker_werden.dart';

/// Die Zahlen für die Tipps nach einer Niederlage (ADR-0083).
///
/// **Trägt zusammen, rechnet nichts**: welche Tipps es werden, steht in
/// [StaerkerWerden.tipps].
final staerkerStandProvider = Provider<StaerkerStand>((ref) {
  final level = ref.watch(playerLevelProvider).level;
  final gewaehlt = ref.watch(chosenAbilitiesProvider).moveIds;
  final freigeschaltet = ref.watch(unlockedAbilitiesProvider);
  final loadout = ref.watch(loadoutProvider);
  final gold = ref.watch(goldProvider);
  final stufe = ref.watch(ladderProvider).highestDefeated;
  final habits = ref.watch(habitTrackerProvider);
  final heute = ref.watch(todayProvider);

  // Slot 1 gehört der Waffe (ADR-0013), die übrigen sind wählbar.
  final freiePlaetze = AbilitySlots.openAt(level) - 1;
  final belegt = gewaehlt.length.clamp(0, freiePlaetze);

  return StaerkerStand(
    leerePlaetze: freiePlaetze - belegt,
    ungenutzteFaehigkeiten: freigeschaltet
        .where((a) => !gewaehlt.contains(a.moveId))
        .length,
    besseresImRucksack: loadout.ownedCopies
        .where(
          (c) =>
              !loadout.isEquipped(c.uid) &&
              loadout.vergleiche(c) == GearVergleich.besser,
        )
        .length,
    freiePunkte: ref.watch(availableTheoryPointsProvider),
    offeneHaekchen: habits
        .dueIdsOn(heute)
        .where((id) => !habits.isChecked(id, heute))
        .length,
    inForm: habits.isDayComplete(heute),
    besseresImLaden: ref
        .watch(dailyOffersProvider)
        .where(
          (c) =>
              loadout.vergleiche(c) == GearVergleich.besser &&
              loadout.blockFor(c, availableGold: gold, highestRung: stufe) ==
                  null,
        )
        .length,
  );
});

/// Die drei Tipps nach einer Niederlage.
final staerkerTippsProvider = Provider<List<StaerkerTipp>>((ref) {
  return StaerkerWerden.tipps(ref.watch(staerkerStandProvider));
});

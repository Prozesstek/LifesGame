import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:progression/progression.dart';

import '../dev/dev_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../save/save_providers.dart';
import '../theory/theory_controller.dart';

/// Bindeglied zwischen Fähigkeiten und Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Welche Fähigkeit woher kommt, steht
/// in `package:abilities`; was sie tut, in `package:combat`; wie viele
/// Plätze offen sind, in `package:progression`. Dieser Controller reicht
/// durch und hält den laufenden Zustand (ADR-0017).
class AbilitiesController extends Notifier<ChosenAbilities> {
  @override
  ChosenAbilities build() => ref.watch(savedGameProvider).abilities;

  /// Legt [moveId] auf den freien Slot [index].
  ///
  /// Ob die Fähigkeit verdient ist, prüft die Oberfläche, bevor sie sie
  /// anbietet — und [activeMovesProvider] ein zweites Mal auf dem Weg in
  /// den Kampf. Der Controller entscheidet das nicht, sonst stünde die
  /// Bedingung an einer dritten Stelle.
  void choose(int index, String moveId) {
    state = state.withAt(index, moveId);
  }

  void clear(int index) {
    state = state.clearedAt(index);
  }
}

final chosenAbilitiesProvider =
    NotifierProvider<AbilitiesController, ChosenAbilities>(
      AbilitiesController.new,
    );

/// Der Fortschritt, an dem die Freischaltungen hängen.
///
/// **Die vierte Naht des Kern-Loops.** `package:abilities` kennt weder
/// `gear` noch `habits` noch `theory`. Hier laufen sie zusammen — und nur
/// hier.
///
/// [HabitTracker.longestStreak] ist bewusst die längste je gelaufene
/// Kette: Eine Fähigkeit aus einer Streak-Marke bleibt, auch wenn die
/// Kette reisst (ADR-0013, `konzept.md` 3.7).
final abilityProgressProvider = Provider<AbilityProgress>((ref) {
  final loadout = ref.watch(loadoutProvider);
  final habits = ref.watch(habitTrackerProvider);
  final theory = ref.watch(theoryProgressProvider);

  return AbilityProgress(
    equippedWeaponId: loadout.equippedIn(GearSlot.waffe)?.id,
    longestStreak: habits.longestStreak,
    // **Bestanden, nicht bezahlt.** Einen Knoten zu öffnen kostet einen
    // Theoriepunkt; die Fähigkeit gibt es erst, wenn seine Seite sitzt
    // (ADR-0013, ADR-0019). Die Regel steht in `package:theory` und wird
    // hier nur benutzt.
    passedNodeIds: <String>{
      for (final node in ref.watch(theoryGraphProvider).nodes)
        if (theory.isPassed(node.lesson.id)) node.id,
    },
  );
});

/// Alle wählbaren Fähigkeiten, die der Spieler freigeschaltet hat.
///
/// Der Entwicklermodus kann welche dazulegen, ohne ihre Bedingung zu
/// erfüllen. Der Zuschlag steht bewusst **hier** und nicht in
/// [abilityProgressProvider]: Dort stünde er als erfundene Streak oder
/// erfundene Seite und wäre nicht mehr als Geschenk erkennbar (ADR-0021).
/// Ohne Entwicklermodus ist die Menge leer.
final unlockedAbilitiesProvider = Provider<List<Ability>>((ref) {
  final verdient = AbilityCatalog.unlockedBy(
    ref.watch(abilityProgressProvider),
  );
  final geschenkt = ref.watch(grantedAbilityIdsProvider);
  if (geschenkt.isEmpty) return verdient;

  final ids = <String>{for (final a in verdient) a.moveId};
  return List<Ability>.unmodifiable(<Ability>[
    ...verdient,
    for (final ability in AbilityCatalog.choosable)
      if (geschenkt.contains(ability.moveId) && !ids.contains(ability.moveId))
        ability,
  ]);
});

/// Was in Slot 1 liegt — die Fähigkeit der getragenen Waffe.
///
/// Nie null: Ohne Waffe greift der Kurzbogen. Slot 1 ist auf Level 1 der
/// einzige offene, er darf nicht leer sein (ADR-0016, ADR-0017).
final weaponMoveProvider = Provider<Move>((ref) {
  final weaponId = ref.watch(abilityProgressProvider).equippedWeaponId;
  final moveId = AbilityCatalog.weaponMoveFor(weaponId);

  return Moves.byId(moveId) ?? Moves.basicAttack;
});

/// Das Moveset, mit dem der Spieler tatsächlich in den Kampf geht.
///
/// **Hier gilt die Bedingung, und nur hier.** Drei Dinge werden auf dem
/// Weg abgeräumt, und keines davon fasst den Spielstand an:
///
/// 1. Was nicht mehr verdient ist, kommt nicht mit.
/// 2. Was über die offenen Plätze hinausgeht, kommt nicht mit — die Zahl
///    steht in `package:progression` (ADR-0016).
/// 3. Was es als Move nicht gibt, kommt nicht mit. Eine Id kann veralten;
///    ein Kampf ohne Knöpfe wäre die schlechtere Antwort darauf.
final activeMovesProvider = Provider<List<Move>>((ref) {
  final progress = ref.watch(abilityProgressProvider);
  final chosen = ref.watch(chosenAbilitiesProvider);
  final level = ref.watch(playerLevelProvider);

  // Slot 1 gehört der Waffe, die übrigen sind gewählt.
  final freeSlots = AbilitySlots.openAt(level.level) - 1;

  final moves = <Move>[ref.watch(weaponMoveProvider)];
  for (final moveId in chosen.moveIds) {
    if (moves.length > freeSlots) break;
    if (!AbilityCatalog.isUnlocked(moveId, progress)) continue;

    final move = Moves.byId(moveId);
    if (move != null) moves.add(move);
  }

  return List<Move>.unmodifiable(moves);
});

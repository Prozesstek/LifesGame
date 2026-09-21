import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gear/gear_controller.dart';
import '../progression/level_provider.dart';
import '../ui/holz.dart';
import 'abilities_controller.dart';
import 'ability_unlock.dart';
import 'widgets/ability_unlock_sheet.dart';

/// Feiert jede Fähigkeit, die seit [before] dazugekommen ist.
///
/// **Aufgerufen wird das an genau zwei Stellen**, und beide sind
/// Handlungen des Spielers: eine Seite bestehen und ein Häkchen setzen.
/// Ein Provider, der von selbst auf Änderungen horcht, wäre der
/// naheliegende Weg und der falsche — er feuerte auch beim Laden des
/// Spielstands, beim Waffenwechsel und im Entwicklermodus.
///
/// [before] wird **vor** der Handlung gelesen. Danach ist es zu spät: Der
/// Fortschritt ist dann schon drin und der Unterschied verschwunden.
Future<void> showAbilityUnlocks(
  BuildContext context,
  WidgetRef ref, {
  required List<Ability> before,
}) async {
  final neu = newlyUnlocked(
    before: before,
    after: ref.read(unlockedAbilitiesProvider),
  );

  for (final ability in neu) {
    final move = Moves.byId(ability.moveId);
    // Eine Id ohne Move ist ein Fehler im Katalog, den
    // `abilities_seam_test.dart` findet. Hier ist Schweigen die richtige
    // Antwort: eine leere Feier wäre schlimmer als keine.
    if (move == null) continue;
    if (!context.mounted) return;

    final slot = firstFreeSlot(
      chosen: ref.read(chosenAbilitiesProvider),
      level: ref.read(playerLevelProvider).level,
    );

    final choice = await showModalBottomSheet<UnlockChoice>(
      context: context,
      // Die Feier hängt im Holzrahmen; das Blatt selbst ist durchsichtig.
      backgroundColor: Colors.transparent,
      elevation: 0,
      // **So hoch, wie der Rahmen braucht.** Ohne das kappt das Blatt bei
      // neun Sechzehnteln der Höhe, und „Weiter" liegt unter der Kante.
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: HolzRahmen(
          child: AbilityUnlockSheet(
            ability: ability,
            move: move,
            attack: ref.read(equippedStatsProvider).attack,
            hasFreeSlot: slot != null,
            nextSlotLevel: nextSlotLevel(ref.read(playerLevelProvider).level),
          ),
        ),
      ),
    );

    if (choice != UnlockChoice.equip || slot == null) continue;

    // **Einen Bildaufbau später.** `showModalBottomSheet` kehrt zurück,
    // während das Blatt noch abgebaut wird; ein Provider-Wechsel fällt
    // dann mitten in den Abbau. Der Fall steht in `gotchas.md` — und ein
    // Widget-Test findet ihn nicht.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chosenAbilitiesProvider.notifier).choose(slot, ability.moveId);
    });
  }
}

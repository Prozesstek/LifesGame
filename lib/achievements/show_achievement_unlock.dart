import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_effects.dart';
import '../ui/holz.dart';
import 'achievements_controller.dart';
import 'widgets/achievement_unlock_sheet.dart';

/// Feiert jede Errungenschaft, die seit [before] dazugekommen ist.
///
/// **Ein Vergleich und kein gespeichertes „schon gefeiert"** — dieselbe
/// Bauform wie bei den Fähigkeiten (`ability_unlock.dart`), und aus
/// demselben Grund: Verdient ist abgeleitet, es gibt keinen Moment, den
/// der Spielstand festhält (ADR-0033, Punkt 2). Ein Merkzettel wäre eine
/// zweite Wahrheit über etwas, das sich aus der Historie ergibt — und
/// müsste bei jedem neuen Katalogeintrag nachgezogen werden.
///
/// Der Preis ist ehrlich: Wer die App im selben Augenblick abwürgt,
/// verpasst die Feier. Die Errungenschaft selbst geht nie verloren, und
/// der Bildschirm zeigt sie weiterhin.
///
/// [before] wird **vor** der Handlung gelesen. Danach ist es zu spät.
Future<void> showAchievementUnlocks(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> before,
}) async {
  final nachher = ref.read(earnedAchievementIdsProvider);
  final neu = <Achievement>[
    for (final achievement in AchievementCatalog.all)
      if (nachher.contains(achievement.id) && !before.contains(achievement.id))
        achievement,
  ];

  for (final achievement in neu) {
    if (!context.mounted) return;

    ref.read(soundPlayerProvider).play(SoundEffect.errungenschaft);
    await showModalBottomSheet<void>(
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
          child: AchievementUnlockSheet(achievement: achievement),
        ),
      ),
    );
  }
}

/// Die verdienten Ids **vor** einer Handlung — der Gegenwert zu [before].
///
/// Steht hier als eigene Zeile, damit die Aufrufer nicht selbst wissen
/// müssen, welcher Provider gemeint ist.
Set<String> achievementsBefore(WidgetRef ref) {
  return ref.read(earnedAchievementIdsProvider);
}

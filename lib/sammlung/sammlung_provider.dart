import 'package:achievements/achievements.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../achievements/achievements_controller.dart';
import '../character/abilities_controller.dart';
import '../combat/ladder_controller.dart';
import '../gear/gear_controller.dart';
import '../theory/theory_controller.dart';
import 'sammlung.dart';

/// Die Einträge eines Reiters — **rechnet nichts**, trägt nur zusammen,
/// was schon abgeleitet ist. Die Errungenschaften haben keine Einträge
/// hier: Sie stehen mit ihrer eigenen Ansicht in der Sammlung.
final sammelEintraegeProvider = Provider.family<List<SammelEintrag>, SammelArt>(
  (ref, art) {
    return switch (art) {
      SammelArt.ausruestung => Sammlung.ausruestung(
        ref.watch(loadoutProvider).everOwnedIds,
      ),
      SammelArt.faehigkeiten => Sammlung.faehigkeiten(<String>{
        for (final a in ref.watch(unlockedAbilitiesProvider)) a.moveId,
        for (final a in ref.watch(unlockedUltimatesProvider)) a.moveId,
      }),
      SammelArt.gegner => Sammlung.gegner(ref.watch(ladderProvider).bestiarium),
      SammelArt.titel => Sammlung.titel(ref.watch(earnedTitleIdsProvider)),
      SammelArt.seiten => Sammlung.seiten(
        ref.watch(theoryGraphProvider),
        ref.watch(theoryProgressProvider),
      ),
      SammelArt.errungenschaften => const <SammelEintrag>[],
    };
  },
);

/// Wie weit ein Reiter gefüllt ist.
final sammelStandProvider = Provider.family<SammelStand, SammelArt>((ref, art) {
  if (art == SammelArt.errungenschaften) {
    return SammelStand(
      ref.watch(earnedAchievementIdsProvider).length,
      AchievementCatalog.all.length,
    );
  }
  return SammelStand.aus(ref.watch(sammelEintraegeProvider(art)));
});

/// Die ganze Sammlung in einer Zahl — alle Reiter zusammen.
final sammelGesamtProvider = Provider<SammelStand>((ref) {
  var stand = const SammelStand(0, 0);
  for (final art in SammelArt.values) {
    stand = stand + ref.watch(sammelStandProvider(art));
  }
  return stand;
});

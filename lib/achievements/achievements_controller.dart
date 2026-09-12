import 'package:achievements/achievements.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ladder_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../theory/theory_controller.dart';
import 'achievement_stats.dart';

/// Die Zahlen, an denen die Errungenschaften hängen.
///
/// **Die dreizehnte Stelle, an der etwas zusammenläuft** — und die
/// breiteste: Sie zieht aus allen vier Spielbereichen.
/// `package:achievements` kennt keines der anderen sieben Packages; hier
/// treffen sie sich, und nur hier.
///
/// **Der Entwicklermodus steht bewusst nicht darin.** Er schenkt
/// Summanden auf Erfahrung und Gold, keine Historie (ADR-0021); eine
/// geschenkte Stufe schaltet deshalb keine Errungenschaft frei
/// (ADR-0033, Punkt 10).
final achievementStatsProvider = Provider<AchievementStats>((ref) {
  return buildAchievementStats(
    habits: ref.watch(habitTrackerProvider),
    theory: ref.watch(theoryProgressProvider),
    graph: ref.watch(theoryGraphProvider),
    handbook: ref.watch(handbookProvider),
    passedPages: ref.watch(passedPagesProvider),
    ladder: ref.watch(ladderProvider),
    loadout: ref.watch(loadoutProvider),
  );
});

/// Alle verdienten Errungenschaften, in Katalogreihenfolge.
final earnedAchievementsProvider = Provider<List<Achievement>>((ref) {
  return AchievementCatalog.earnedBy(ref.watch(achievementStatsProvider));
});

/// Nur die Ids — für Vergleiche und für `package:abilities`.
final earnedAchievementIdsProvider = Provider<Set<String>>((ref) {
  return AchievementCatalog.earnedIdsBy(ref.watch(achievementStatsProvider));
});

/// Die Titel, die verdient sind.
///
/// **Die einzige Stelle, an der ein Titel verdient wird** (ADR-0033,
/// Punkt 6). Vorher rechnete `package:identity` das aus drei Zahlen;
/// jetzt steht die Bedingung im Errungenschaftskatalog, und dort nur
/// einmal.
final earnedTitleIdsProvider = Provider<Set<String>>((ref) {
  return AchievementCatalog.earnedTitleIdsBy(
    ref.watch(achievementStatsProvider),
  );
});

/// Der Ruhm-Stand.
///
/// **Eine Zahl zum Vergleichen, kein Guthaben** (ADR-0033, Punkt 5). Sie
/// steht auf dem Charakter neben Level und Gold, und niemand kann sie
/// ausgeben. Ihr Zweck ist Ziel 7: „340 gegen 410", wie „17 / 30" bei der
/// Reihe.
final fameProvider = Provider<int>((ref) {
  return AchievementCatalog.fameFor(ref.watch(achievementStatsProvider));
});

/// Erfahrung aus Errungenschaften — der fünfte Zufluss in die Kurven.
final achievementXpProvider = Provider<int>((ref) {
  return AchievementCatalog.xpFor(ref.watch(achievementStatsProvider));
});

/// Gold aus Errungenschaften.
final achievementGoldProvider = Provider<int>((ref) {
  return AchievementCatalog.goldFor(ref.watch(achievementStatsProvider));
});

/// Wie viele Errungenschaften eines Bereichs verdient sind — für die
/// Reiterzeile „3 / 11".
final areaProgressProvider =
    Provider.family<({int earned, int total}), AchievementArea>((ref, area) {
      final earned = ref.watch(earnedAchievementIdsProvider);
      final alle = AchievementCatalog.inArea(area);

      return (
        earned: alle.where((a) => earned.contains(a.id)).length,
        total: alle.length,
      );
    });

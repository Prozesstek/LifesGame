import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity/identity.dart';

import '../habits/habits_controller.dart';
import '../save/save_providers.dart';
import '../theory/theory_controller.dart';

/// Bindeglied zwischen Identität und Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Welche Titel es gibt, was sie kosten
/// und ab wann sie verdient sind, steht in `package:identity`. Dieser
/// Controller reicht durch und hält den laufenden Zustand (ADR-0013).
class IdentityController extends Notifier<Identity> {
  @override
  Identity build() => ref.watch(savedGameProvider).identity;

  void setName(String name) {
    state = state.withName(name);
  }

  /// Wählt einen Titel oder legt ihn ab (null).
  ///
  /// Ob er verdient ist, prüft die Oberfläche, bevor sie ihn überhaupt
  /// anbietet — und `Identity.titleFor` ein zweites Mal beim Anzeigen. Der
  /// Controller entscheidet das nicht, sonst stünde die Bedingung an einer
  /// dritten Stelle.
  void chooseTitle(String? titleId) {
    state = state.withTitle(titleId);
  }
}

final identityProvider = NotifierProvider<IdentityController, Identity>(
  IdentityController.new,
);

/// Die drei Zahlen, an denen die Titel hängen.
///
/// **Die dritte Naht des Kern-Loops.** `package:habits` weiß nichts von
/// Titeln, `package:theory` nichts von Streaks, und `package:identity`
/// kennt keines von beiden. Hier laufen sie zusammen — und nur hier.
///
/// [HabitTracker.longestStreak] ist bewusst die längste je gelaufene
/// Kette, nicht die laufende: Ein verdienter Titel darf beim Reißen der
/// Streak nicht verschwinden (ADR-0013, `konzept.md` 3.7).
final titleStatsProvider = Provider<TitleStats>((ref) {
  final habits = ref.watch(habitTrackerProvider);

  return TitleStats(
    longestStreak: habits.longestStreak,
    passedLessons: ref.watch(passedPagesProvider),
    totalChecks: habits.totalChecks,
  );
});

/// Alle Titel, die der Spieler tragen darf.
final earnedTitlesProvider = Provider<List<CharacterTitle>>((ref) {
  return TitleCatalog.earnedBy(ref.watch(titleStatsProvider));
});

import 'package:achievements/achievements.dart';
import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../combat/ladder_controller.dart';
import '../habits/habits_controller.dart';
import '../theory/theory_controller.dart';

/// Die Schwellen, die zu einer Bedingung gehören und nicht zu dem
/// Package, das sie beantwortet.
///
/// **Warum sie hier stehen und nicht dort.** „Drei Niederlagen" ist keine
/// Kampfregel und „drei Tage Pause" keine Streak-Regel — beides sind
/// Bedingungen von Errungenschaften. `package:combat` und
/// `package:habits` liefern deshalb nur die *Frage* („wie viele Sprossen
/// fielen nach mindestens n Niederlagen?"), und die Zahl kommt von hier.
///
/// Der Wortlaut daneben steht im Katalog (`requirement`). Wer hier dreht,
/// zieht ihn von Hand nach — kein Test liest Fließtext.
abstract final class AchievementThresholds {
  /// Wie viele Häkchen ein Tag braucht, um als „voll" zu zählen
  /// (Durchatmen, der Mönch).
  static const int checksPerFullDay = 3;

  /// Wie lang die Pause vor dem Comeback sein muss (der Stoiker).
  static const int pauseDays = 3;

  /// Wie oft man an einer Sprosse verloren haben muss (der Unbeugsame).
  static const int comebackDefeats = 3;

  /// Der Grad, der als „schwer" zählt (der Herausforderer).
  static const HabitDifficulty hardDifficulty = HabitDifficulty.schwer;
}

/// Setzt die Zahlen zusammen, an denen die Errungenschaften hängen.
///
/// **Als Funktion mit ausgeschriebenen Parametern und nicht als Provider,
/// der sich alles selbst holt** — und das ist kein Stilfrage, sondern die
/// Abzweigung um einen Kreis. Errungenschaften im Laden zahlen Gold, und
/// der `GearController` fragt beim Kauf, wie viel Gold da ist. Läse er
/// dafür eine Zahl, die über die Errungenschaften wieder auf
/// `loadoutProvider` zeigt, wäre das der `CircularDependencyError` aus
/// `gotchas.md`. So kann er stattdessen seinen eigenen Zustand
/// hereinreichen — dieselbe Auflösung wie damals bei
/// `spendableIncomeProvider`.
///
/// **Jede Zahl darf nur steigen** (ADR-0033, Punkt 3). Deshalb steht hier
/// `longestStreak` und nicht die laufende Kette, „je besessen" und nicht
/// der Besitz, `highestDefeated` und nicht die nächste Sprosse. Wer eine
/// Zahl ergänzt, die fallen kann, macht eine Errungenschaft
/// zurücknehmbar.
AchievementStats buildAchievementStats({
  required HabitTracker habits,
  required TheoryProgress theory,
  required TheoryGraph graph,
  required TheoryBranch handbook,
  required int passedPages,
  required LadderProgress ladder,
  required Loadout loadout,
}) {
  return AchievementStats(
    // --- Gewohnheiten ---
    totalChecks: habits.totalChecks,
    longestStreak: habits.longestStreak,
    customHabitCount: habits.customCount,
    daysWithThreeChecks: habits.daysWithAtLeast(
      AchievementThresholds.checksPerFullDay,
    ),
    longestRunWithThreeChecks: habits.longestRunWithAtLeast(
      AchievementThresholds.checksPerFullDay,
    ),
    checksOnHardCustomHabits: habits.checksOnCustomWith(
      AchievementThresholds.hardDifficulty,
    ),
    comebackStreak: habits.comebackStreakAfterPause(
      AchievementThresholds.pauseDays,
    ),

    // --- Theorie ---
    //
    // Die Seitenzahl kommt von außen, aus `passedPagesProvider`. Sie hier
    // noch einmal aus Handbuch und Graph zu addieren wären zwei Stellen
    // für dieselbe Frage — und die eine hat sich schon einmal verzählt
    // (`passedCountIn(theoryTree)` nach ADR-0019).
    passedLessons: passedPages,
    perfectLessons:
        theory.perfectCount(handbook) + theory.perfectNodeCount(graph),
    completedAreas: theory.completedAreaCount(graph),
    areasWithPassedNode: theory.areasWithPassedNodeCount(graph),
    retriedLessons:
        theory.retriedCount(handbook) + theory.retriedNodeCount(graph),

    // --- Kampf ---
    highestRung: ladder.highestDefeated,
    comebackVictories: ladder.comebackVictoriesAfter(
      AchievementThresholds.comebackDefeats,
    ),

    // --- Laden ---
    everOwnedCount: loadout.everOwnedCount,
    slotsEverOwned: loadout.slotsEverOwned,
    completeSetsEverOwned: loadout.completeSetsEverOwned,
    soldCount: loadout.soldCount,
  );
}

/// Dieselben Zahlen, aber mit einem hereingereichten Inventar.
///
/// Nur für den `GearController` gedacht, der seinen eigenen Zustand
/// mitbringen muss — siehe [buildAchievementStats].
///
/// **Diese Datei importiert bewusst kein `gear_controller.dart`.** Täte
/// sie es, entstünde ein Import-Kreis zwischen beiden Dateien, und der
/// hat in diesem Projekt schon einmal die Typinferenz auf `num`
/// zurückfallen lassen (`gotchas.md`, Entwicklermodus).
AchievementStats achievementStatsWithLoadout(Ref ref, Loadout loadout) {
  return buildAchievementStats(
    habits: ref.read(habitTrackerProvider),
    theory: ref.read(theoryProgressProvider),
    graph: ref.read(theoryGraphProvider),
    handbook: ref.read(handbookProvider),
    passedPages: ref.read(passedPagesProvider),
    ladder: ref.read(ladderProvider),
    loadout: loadout,
  );
}

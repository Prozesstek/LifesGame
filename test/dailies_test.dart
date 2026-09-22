import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

/// Die vier Stufen des Tages in der App (ADR-0040): Sie zahlen nur an
/// Tagen mit einem Häkchen, einmal je Stufe, und fliessen in Erfahrung
/// und Gold wie alles andere.
void main() {
  const heute = Day(2026, 9, 22);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(heute)],
    );
    addTearDown(c.dispose);
    // Zehn Stufen geschafft — genug für vier Dailies.
    final reihe = c.read(ladderProvider.notifier);
    for (var s = 1; s <= 10; s++) {
      reihe.defeat(s);
    }
    return c;
  }

  void hakeAb(ProviderContainer c) {
    final theorie = c.read(theoryProgressProvider.notifier);
    for (final lesson in habitsBranch.lessons) {
      theorie.submit(
        lesson,
        lesson.questions.map<int?>((q) => q.correctIndex).toList(),
      );
    }
    final id = c.read(unlockedHabitsProvider).first.id;
    final gewohnheiten = c.read(habitTrackerProvider.notifier);
    gewohnheiten.activate(id);
    gewohnheiten.toggle(id, heute);
  }

  test('ohne Häkchen zahlt ein Daily nichts', () {
    final c = container();
    final stufe = c.read(todayDailiesProvider).first.stage;

    expect(c.read(dailiesUnlockedProvider), isFalse);
    final ertrag = c.read(ladderProvider.notifier).recordRun(stufe, won: true);
    expect(ertrag.xp, 0);
    expect(ertrag.gold, 0);
  });

  test('mit Häkchen zahlt es ein Viertel — einmal', () {
    final c = container();
    hakeAb(c);
    final stufe = c.read(todayDailiesProvider).first.stage;
    final vorher = c.read(totalXpProvider);

    final reihe = c.read(ladderProvider.notifier);
    final erst = reihe.recordRun(stufe, won: true);
    final zweit = reihe.recordRun(stufe, won: true);

    expect(erst.xp, LadderRewards.dailyXpFor(stufe));
    expect(erst.gold, LadderRewards.dailyGoldFor(stufe));
    expect(zweit.xp, 0);
    expect(c.read(totalXpProvider), vorher + erst.xp);
    expect(c.read(todayDailiesProvider).first.cleared, isTrue);
  });

  test('eine geschaffte Stufe, die heute kein Daily ist, zahlt nichts', () {
    final c = container();
    hakeAb(c);
    final heuteDaily = c.read(todayDailiesProvider).map((d) => d.stage);
    final andere = List<int>.generate(
      10,
      (i) => i + 1,
    ).firstWhere((s) => !heuteDaily.contains(s));

    final ertrag = c.read(ladderProvider.notifier).recordRun(andere, won: true);
    expect(ertrag.xp, 0);
  });

  test('ein neuer Erstsieg verschiebt die vier des Tages nicht', () {
    final c = container();
    final morgens = c.read(todayDailiesProvider).map((d) => d.stage).toList();

    c.read(ladderProvider.notifier).recordRun(11, won: true);
    expect(c.read(ladderProvider).highestDefeated, 11);
    expect(c.read(todayDailiesProvider).map((d) => d.stage).toList(), morgens);
  });
}

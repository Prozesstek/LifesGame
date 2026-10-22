import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';

/// Erfahrung und Gold je Gegner, durch die App (ADR-0041): Seit
/// ADR-0083 nimmt eine Niederlage, was gefallen ist, und der Sieg zahlt
/// den ganzen Topf.
void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(const Day(2026, 9, 22))],
    );
    addTearDown(c.dispose);
    final reihe = c.read(ladderProvider.notifier);
    for (var s = 1; s <= 6; s++) {
      reihe.defeat(s);
    }
    return c;
  }

  test('verloren bringt nichts, gewonnen den ganzen Topf (ADR-0083)', () {
    final c = container();
    final reihe = c.read(ladderProvider.notifier);
    final voll = (xp: LadderRewards.xpFor(7), gold: LadderRewards.goldFor(7));
    final vorher = c.read(totalXpProvider);

    expect(reihe.potFor(7), voll);
    final verloren = reihe.recordRun(7, won: false);
    expect(verloren, (xp: 0, gold: 0));
    expect(c.read(totalXpProvider), vorher);
    expect(reihe.potFor(7), voll);

    final gewonnen = reihe.recordRun(7, won: true);
    expect(gewonnen, voll);
    expect(c.read(totalXpProvider), vorher + voll.xp);
  });
}

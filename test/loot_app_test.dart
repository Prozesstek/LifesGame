import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/action/damage_popup.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';

/// Erfahrung und Gold je Gegner, durch die App (ADR-0041): Ein
/// verlorener Lauf behält, was gefallen ist, und der Sieg zahlt genau den
/// Rest — zusammen so viel wie vorher der Abschluss allein.
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

  test('verloren behalten, gewonnen den Rest — zusammen der Abschluss', () {
    final c = container();
    final reihe = c.read(ladderProvider.notifier);
    final voll = (xp: LadderRewards.xpFor(7), gold: LadderRewards.goldFor(7));
    final vorher = c.read(totalXpProvider);

    expect(reihe.potFor(7), voll);
    final verloren = reihe.recordRun(
      7,
      won: false,
      collected: (xp: 20, gold: 5),
    );
    expect(verloren, (xp: 20, gold: 5));
    expect(c.read(totalXpProvider), vorher + 20);
    expect(reihe.potFor(7), (xp: voll.xp - 20, gold: voll.gold - 5));

    final gewonnen = reihe.recordRun(7, won: true);
    expect(gewonnen, (xp: voll.xp - 20, gold: voll.gold - 5));
    expect(c.read(totalXpProvider), vorher + voll.xp);
  });

  test('über einem gefallenen Gegner steht, was er gebracht hat', () {
    final popup = DamagePopup.forLoot(
      const LootDropped(at: Vec2(10, 10), xp: 7, gold: 3),
    );
    expect(popup?.text, '+7 EP  +3 G');
    expect(
      DamagePopup.forLoot(const LootDropped(at: Vec2.zero, xp: 0, gold: 0)),
      isNull,
    );
  });
}

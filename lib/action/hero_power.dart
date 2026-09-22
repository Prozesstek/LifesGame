import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:progression/progression.dart';

import '../gear/gear_controller.dart';
import '../progression/level_provider.dart';

/// Womit der Held in die Grube geht, und warum (ADR-0042).
class HeroPower {
  const HeroPower({
    required this.stats,
    required this.levelFactor,
    required this.weaponFactor,
    required this.armorFactor,
  });

  /// Die Werte für die Welt — [ActionStats.combatAttack] und die anderen
  /// sind die Zahlen, die der Kampf führt.
  final ActionStats stats;

  final double levelFactor;
  final double weaponFactor;
  final double armorFactor;
}

/// Die Stärke in der Grube — **rechnet nicht**: Gewohnheiten und Boni
/// kommen aus [equippedStatsProvider], der Levelfaktor aus
/// `PowerCurve`, die Seltenheit aus `GearRarity.powerFactor`, und
/// zusammengesetzt wird in `PitPower.hero`.
///
/// Die Grube, der Prototyp und der Charakterbildschirm fragen alle hier —
/// sonst zeigte der Charakter eine andere Zahl, als der Kampf rechnet.
final heroPowerProvider = Provider<HeroPower>((ref) {
  final werte = ref.watch(equippedStatsProvider);
  final level = ref.watch(playerLevelProvider).level;
  final loadout = ref.watch(loadoutProvider);

  final stufe = PowerCurve.factorFor(level);
  final waffe = loadout.equippedIn(GearSlot.waffe)?.rarity.powerFactor ?? 1.0;
  final ruestung =
      loadout.equippedIn(GearSlot.ruestung)?.rarity.powerFactor ?? 1.0;

  return HeroPower(
    stats: PitPower.hero(
      attack: werte.attack,
      maxHp: werte.maxHp,
      defense: werte.defense,
      energy: werte.maxEnergy,
      levelFactor: stufe,
      weaponFactor: waffe,
      armorFactor: ruestung,
    ),
    levelFactor: stufe,
    weaponFactor: waffe,
    armorFactor: ruestung,
  );
});

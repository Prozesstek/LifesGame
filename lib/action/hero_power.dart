import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';

import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';

/// Womit der Held in die Grube geht, und warum (ADR-0042).
class HeroPower {
  const HeroPower({
    required this.stats,
    required this.levelFactor,
    required this.weaponFactor,
    required this.armorFactor,
    this.form = const DailyForm.none(),
  });

  /// Die Werte für die Welt — [ActionStats.combatAttack] und die anderen
  /// sind die Zahlen, die der Kampf führt.
  final ActionStats stats;

  final double levelFactor;
  final double weaponFactor;
  final double armorFactor;

  /// Die Tagesform, die in [stats] schon steckt — für die Anzeige.
  final DailyForm form;
}

/// Die Stärke in der Grube — **rechnet nicht**: Gewohnheiten und Boni
/// kommen aus [equippedStatsProvider], der Levelfaktor aus
/// `PowerCurve`, die Seltenheit aus `GearRarity.powerFactor`, die
/// Tagesform aus [dailyFormProvider], und zusammengesetzt wird in
/// `PitPower.hero`.
///
/// Die Grube, der Prototyp und der Charakterbildschirm fragen alle hier —
/// sonst zeigte der Charakter eine andere Zahl, als der Kampf rechnet.
final heroPowerProvider = Provider<HeroPower>((ref) {
  final werte = ref.watch(equippedStatsProvider);
  final level = ref.watch(playerLevelProvider).level;
  final loadout = ref.watch(loadoutProvider);
  final form = ref.watch(dailyFormProvider);

  final stufe = PowerCurve.factorFor(level);
  final waffe = loadout.equippedIn(GearSlot.waffe)?.rarity.powerFactor ?? 1.0;
  final ruestung =
      loadout.equippedIn(GearSlot.ruestung)?.rarity.powerFactor ?? 1.0;

  return HeroPower(
    // Alltag im kleinen Massstab, Ausrüstung schon im Kampfmassstab —
    // getrennt, damit der Wurf eines Stücks nicht in der Rundung
    // verschwindet (ADR-0048).
    stats: PitPower.hero(
      attack: werte.base.attack,
      maxHp: werte.base.maxHp,
      defense: werte.base.defense,
      energy: werte.base.maxEnergy,
      gearAttack: werte.bonus.attack,
      gearMaxHp: werte.bonus.maxHp,
      gearDefense: werte.bonus.defense,
      gearEnergy: werte.bonus.maxEnergy,
      levelFactor: stufe,
      weaponFactor: waffe,
      armorFactor: ruestung,
      formAttack: form.factorFor(HabitStat.staerke),
      formHp: form.factorFor(HabitStat.ausdauer),
      formDefense: form.factorFor(HabitStat.disziplin),
      formMana: form.factorFor(HabitStat.klarheit),
    ),
    levelFactor: stufe,
    weaponFactor: waffe,
    armorFactor: ruestung,
    form: form,
  );
});

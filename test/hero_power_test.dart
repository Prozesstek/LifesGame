import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/action/hero_power.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

/// Womit der Held in die Grube geht (ADR-0042): Gewohnheiten und Boni
/// addiert, Level und Seltenheit vervielfacht — an einer Stelle.
void main() {
  ProviderContainer mit(SaveData stand) {
    final c = ProviderContainer(
      overrides: [savedGameProvider.overrideWithValue(stand)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('ein frischer Charakter geht mit ×1 und mal zehn hinein', () {
    final c = mit(const SaveData());
    final macht = c.read(heroPowerProvider);
    final werte = c.read(equippedStatsProvider);

    expect(macht.levelFactor, 1);
    expect(macht.weaponFactor, 1);
    expect(macht.armorFactor, 1);
    expect(macht.stats.combatAttack, werte.attack * ActionBalance.powerScale);
  });

  test('eine legendäre Waffe vervielfacht den Angriff, nicht das Leben', () {
    final waffe = GearCatalog.forSlot(
      GearSlot.waffe,
    ).firstWhere((i) => i.rarity == GearRarity.legendary);
    final ohne = mit(const SaveData()).read(heroPowerProvider);
    final mitWaffe = mit(
      SaveData(
        loadout: const Loadout.empty().buy(
          waffe.id,
          availableGold: waffe.price,
          highestRung: GearGates.legendaryRung,
        ),
      ),
    ).read(heroPowerProvider);

    expect(mitWaffe.weaponFactor, GearRarity.legendary.powerFactor);
    // Die Waffe bringt auch ihre Boni mit; der Faktor liegt darüber.
    expect(
      mitWaffe.stats.combatAttack,
      greaterThan(ohne.stats.combatAttack * GearRarity.legendary.powerFactor),
    );
    expect(mitWaffe.armorFactor, 1);
  });
}

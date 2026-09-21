import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';

import '../action/pit_text.dart';

/// Was eine Waffe aus dem Grundangriff in der Grube macht, als eine Zeile
/// für den Laden (ADR-0039).
///
/// **Vor dem Kauf, nicht danach.** Acht Waffen mit acht Arten zu
/// schlagen sind nur dann eine Entscheidung, wenn man sieht, welche man
/// bekommt. Die Zahlen kommen aus `PitWeapons`, hier werden sie nur in
/// Worte gesetzt — wer eine Waffe ändert, muss die Zeile nicht nachziehen.
///
/// `null` für alles, was keine Waffe ist.
String? weaponAbilityLine(GearItem item) {
  if (item.slot != GearSlot.waffe) return null;

  final zug = AbilityCatalog.weaponMoveFor(item.id);
  final waffe = PitWeapons.byMoveId(zug);
  if (waffe == null) return null;

  return 'Grundangriff: ${waffe.name} — ${pitWeaponSummary(waffe)}';
}

/// Die legendäre Kraft eines Stücks, als Zeile für den Laden.
///
/// `null` für alles, was keine trägt — und für eine Id, die in der Grube
/// nicht ankommt. Dass es die nicht gibt, prüft `test/pit_test.dart`.
String? legendaryPowerLine(GearItem item) {
  final kraft = PitLegendaries.byId(item.legendaryPower);
  if (kraft == null) return null;
  return 'Legendär: ${kraft.name} — ${kraft.description}';
}

/// Alles, was ein Stück an Fähigkeiten verändert, in einer Fläche.
String? itemAbilityText(GearItem item) {
  final zeilen = <String>[?weaponAbilityLine(item), ?legendaryPowerLine(item)];
  return zeilen.isEmpty ? null : zeilen.join('\n');
}

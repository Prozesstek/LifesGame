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

/// Die Kraft eines Stücks, als Zeile für den Laden — seit ADR-0077 an
/// jeder Seltenheit, nicht nur an legendären.
///
/// `null` für alles, was keine trägt — und für eine Id, die in der Grube
/// nicht ankommt. Dass es die nicht gibt, prüft `test/pit_test.dart`.
String? gearPowerLine(GearItem item) {
  final kraft = PitGearPowers.byId(item.power);
  if (kraft == null) return null;
  return 'Kraft: ${kraft.name} — ${kraft.description}';
}

/// Was eine Stufe eines Sets tut, in Worten: ihre Zahlen und ihre
/// Kräfte (ADR-0077). Eine Stelle für das Blatt und die Set-Karte.
String setPerkText(GearSet set, SetPerk perk) {
  final teile = <String>[
    if (perk.labels.isNotEmpty)
      '${perk.labels.join(', ')} auf ${set.target.label}',
    for (final id in perk.powers)
      if (PitGearPowers.byId(id) case final kraft?)
        '${kraft.name} — ${kraft.description}',
  ];
  return teile.join(' · ');
}

/// Alles, was ein Stück an Fähigkeiten verändert, in einer Fläche.
String? itemAbilityText(GearItem item) {
  final zeilen = <String>[?weaponAbilityLine(item), ?gearPowerLine(item)];
  return zeilen.isEmpty ? null : zeilen.join('\n');
}

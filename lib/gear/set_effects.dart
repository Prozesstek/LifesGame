import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';

/// Was getragene Sets und legendäre Stücke an den Fähigkeiten der Grube
/// ändern (ADR-0039).
///
/// **Die Naht zwischen zwei Packages, die einander nicht kennen.**
/// `package:gear` weiß, welche Stücke ein Set sind und welche Kraft ein
/// legendäres trägt; `package:action_combat` weiß, was eine Fähigkeit
/// tut. Gerechnet wird hier nichts: Faktoren kommen aus `GearSets`, die
/// legendären Kräfte aus `PitLegendaries`. Die eine Umrechnung — ein
/// Energiepunkt Rabatt ist so viel Mana wie ein Energiepunkt Vorrat —
/// liest ihren Kurs aus `ActionBalance`, statt ihn zu wiederholen.
List<PitModifier> pitModifiersFor(
  Iterable<ActiveSet> active,
  Iterable<GearItem> equipped,
) {
  return <PitModifier>[
    for (final entry in active) ..._setModifiers(entry),
    for (final item in equipped)
      ...?PitLegendaries.byId(item.legendaryPower)?.modifiers,
  ];
}

List<PitModifier> _setModifiers(ActiveSet entry) {
  final art = pitKindFor(entry.set.target);
  final perk = entry.perk;
  return <PitModifier>[
    if (perk.damageFactor != 1.0)
      ScaleDamage(factor: perk.damageFactor, kind: art),
    if (perk.energyDiscount != 0)
      ReduceManaCost(
        amount: perk.energyDiscount * ActionBalance.manaPerEnergy,
        kind: art,
      ),
    if (perk.protectionFactor != 1.0)
      ScaleProtection(factor: perk.protectionFactor, kind: art),
  ];
}

/// Welche Art von Fähigkeit zu welchem Set-Ziel gehört.
///
/// **Die einzige Stelle, an der die beiden Aufzählungen aufeinandertreffen.**
/// Ein `switch` ohne Standardfall sorgt dafür, dass ein neuer Wert auf der
/// einen Seite hier einen Fehler erzeugt statt still durchzurutschen.
PitKind pitKindFor(SetTarget target) {
  return switch (target) {
    SetTarget.angriff => PitKind.angriff,
    SetTarget.umgebung => PitKind.umgebung,
    SetTarget.schutz => PitKind.schutz,
  };
}

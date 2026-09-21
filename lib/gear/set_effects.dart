import 'package:action_combat/action_combat.dart';
import 'package:combat/combat.dart';
import 'package:gear/gear.dart';

/// Übersetzt getragene Sets in das, was die Engine davon versteht.
///
/// **Die Naht zwischen zwei Packages, die einander nicht kennen.**
/// `package:gear` weiß, welche vier Stücke ein Set sind und was es gibt;
/// `package:combat` weiß, was ein Zug ist und wie Schaden entsteht. Keines
/// von beiden kennt das andere — genau wie bei den Kampfwerten, die aus
/// `habits` und `gear` in der App zusammenkommen.
///
/// **Eine reine Funktion, kein Provider.** Dieselbe Trennung wie bei
/// `weaponAbilityLine` und `damageReadoutFor`: Die Umrechnung ist in zehn
/// Zeilen zu testen, ein Provider nicht.
///
/// Gerechnet wird hier nichts — jede Zahl kommt unverändert aus
/// `GearSets`. Wer eine Set-Wirkung ändert, ändert sie dort.
List<SetEffect> setEffectsFor(Iterable<ActiveSet> active) {
  return <SetEffect>[
    for (final entry in active)
      SetEffect(
        kind: moveKindFor(entry.set.target),
        damageFactor: entry.perk.damageFactor,
        energyDiscount: entry.perk.energyDiscount,
        timingSpeedFactor: entry.perk.timingSpeedFactor,
        timingWindowFactor: entry.perk.timingWindowFactor,
      ),
  ];
}

/// Welche Art von Zug zu welchem Set-Ziel gehört.
///
/// **Die einzige Stelle, an der die beiden Aufzählungen aufeinandertreffen.**
/// Sie sind bewusst getrennt — `SetTarget` in `gear`, `MoveKind` in
/// `combat` —, und dass sie vollständig aufeinander abgebildet sind, prüft
/// `test/gear_sets_seam_test.dart`. Ein `switch` ohne Standardfall sorgt
/// dafür, dass ein neuer Wert auf der einen Seite hier einen Fehler
/// erzeugt statt still durchzurutschen.
MoveKind moveKindFor(SetTarget target) {
  return switch (target) {
    SetTarget.angriff => MoveKind.angriff,
    SetTarget.umgebung => MoveKind.umgebung,
    SetTarget.schutz => MoveKind.schutz,
  };
}

/// Was getragene Sets und legendäre Stücke an den Fähigkeiten der Grube
/// ändern (ADR-0039).
///
/// **Dieselbe Naht wie [setEffectsFor], für den Kampf, der jetzt gilt.**
/// Gerechnet wird auch hier nichts: Faktoren kommen aus `GearSets`, die
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

/// Welche Art von Fähigkeit in der Grube zu welchem Set-Ziel gehört —
/// dieselbe Rolle wie [moveKindFor] für den Rundenkampf.
PitKind pitKindFor(SetTarget target) {
  return switch (target) {
    SetTarget.angriff => PitKind.angriff,
    SetTarget.umgebung => PitKind.umgebung,
    SetTarget.schutz => PitKind.schutz,
  };
}

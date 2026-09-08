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

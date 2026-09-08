import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:gear/gear.dart';

/// Was eine Waffe an Fähigkeit mitbringt, als eine Zeile für den Laden.
///
/// Null für alles, was keine Waffe ist — nur der Waffenplatz trägt eine
/// Fähigkeit (ADR-0017).
///
/// **Eine reine Funktion, kein Widget.** Dieselbe Trennung wie bei
/// `damageReadoutFor` und `moveHelpFor`: Was angezeigt wird, entscheidet
/// eine Stelle, die ein Test in zehn Zeilen erreicht.
///
/// **Gerechnet wird hier nichts.** `power` und `energyDelta` kommen
/// unverändert aus `package:combat`; die Schichtregel aus `CLAUDE.md`
/// verbietet, in `lib/` eine Spielzahl zu erzeugen. Wer eine Waffe
/// umbaut, ändert den Katalog — diese Zeile zieht nach.
String? weaponAbilityLine(GearItem item) {
  if (item.slot != GearSlot.waffe) return null;

  final move = Moves.byId(AbilityCatalog.weaponMoveFor(item.id));
  if (move == null) return null;

  final teile = <String>[
    if (move.power > 0) '×${_komma(move.power)} Schaden',
    if (move.energyDelta > 0) '+${move.energyDelta} Energie je Runde',
  ];

  if (teile.isEmpty) return 'Bringt ${move.name} mit';
  return 'Bringt ${move.name} mit — ${teile.join(', ')}';
}

/// Deutsches Dezimalkomma. `1.3` liest sich hier sonst wie ein Tippfehler.
String _komma(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

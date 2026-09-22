/// Wie eine Fähigkeit oder ein Waffenzug in Worten heisst und was er tut
/// — für Charakterbildschirm, Laden und Feier (ADR-0039).
///
/// **Reine Rechnung, kein Widget.** Die Zahlen stehen in `PitAbilities`
/// und `PitWeapons`; hier werden sie nur vorgelesen. Eine Stelle für alle
/// drei Bildschirme, damit sie dieselbe Fähigkeit nicht verschieden
/// beschreiben (`gotchas.md`, zwei Stellen für eine Frage).
library;

import 'package:action_combat/action_combat.dart';

/// Der Name zu einer Id — Fähigkeit oder Waffenzug. `null`, wenn die
/// Grube die Id nicht kennt.
String? pitNameOf(String id) {
  return PitAbilities.byId(id)?.name ?? PitWeapons.byMoveId(id)?.name;
}

/// Was sie kostet und tut, in einer Zeile.
String? pitSummaryOf(String id) {
  final ability = PitAbilities.byId(id);
  if (ability != null) return pitAbilitySummary(ability);

  final waffe = PitWeapons.byMoveId(id);
  if (waffe != null) return pitWeaponSummary(waffe);
  return null;
}

/// „12 Mana · 1,5 s — Ein Funke fliegt geradeaus."
String pitAbilitySummary(PitAbility ability) {
  final kosten = ability.manaCost == 0
      ? 'kein Mana'
      : '${ability.manaCost} Mana';
  return '$kosten · ${pitNumber(ability.cooldown)} s — ${ability.description}';
}

/// „schießt, ×0,8 Schaden" — was die Waffe aus dem Grundangriff macht.
String pitWeaponSummary(PitWeapon waffe) {
  final teile = <String>[
    if (waffe.ranged) 'schießt',
    if (waffe.hits > 1)
      '${waffe.hits} Treffer à ×${pitNumber(waffe.power)}'
    else
      '×${pitNumber(waffe.power)} Schaden',
    if (waffe.cleave) 'trifft alle in Reichweite',
    if (waffe.cooldownFactor > 1) 'langsam',
    if (waffe.cooldownFactor < 1) 'schnell',
    if (waffe.manaOnHit > 0) '+${waffe.manaOnHit} Mana je Treffer',
    if (waffe.burnPerSecond > 0) 'lässt brennen',
  ];
  return teile.join(', ');
}

/// Eine Zahl mit Komma und ohne überflüssige Nullen: 1,25 · 0,8 · 2.
String pitNumber(double value) {
  var text = value.toStringAsFixed(2);
  while (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  return text.replaceAll('.', ',');
}

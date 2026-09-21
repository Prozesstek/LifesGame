import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';

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

  final teile = <String>[
    if (waffe.ranged) 'schießt',
    if (waffe.hits > 1)
      '${waffe.hits} Treffer à ×${_zahl(waffe.power)}'
    else
      '×${_zahl(waffe.power)} Schaden',
    if (waffe.cleave) 'trifft alle in Reichweite',
    if (waffe.cooldownFactor > 1) 'langsam',
    if (waffe.cooldownFactor < 1) 'schnell',
    if (waffe.manaOnHit > 0) '+${waffe.manaOnHit} Mana je Treffer',
    if (waffe.burnPerSecond > 0) 'lässt brennen',
  ];

  return 'Grundangriff: ${waffe.name} — ${teile.join(', ')}';
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

/// Eine Zahl mit Komma und ohne überflüssige Nullen: 1,25 · 0,8 · 2.
String _zahl(double value) {
  var text = value.toStringAsFixed(2);
  while (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  return text.replaceAll('.', ',');
}

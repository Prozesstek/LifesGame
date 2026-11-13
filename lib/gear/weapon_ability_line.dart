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

  return 'Grundangriff: ${waffe.name}. ${weaponKampfText(waffe)}';
}

/// Was ein Grundangriff tut, in ganzen Sätzen — **wie in LoL oder
/// Diablo** (AktivesBrett, 13.11.2026): „Trifft 2-mal pro Schlag, jeder
/// Treffer mit 60 % deines Angriffsschadens. Rund 2 Schläge pro
/// Sekunde.“ Bis dahin stand „2 Treffer à ×0,6, schnell“, und niemand
/// wusste, was ×0,6 wovon ist.
String weaponKampfText(PitWeapon waffe) {
  final wert = _deinWert(waffe.fs);
  final prozent = _prozent(waffe.power);
  final schlag = waffe.ranged ? 'Schuss' : 'Schlag';
  final saetze = <String>[
    if (waffe.hits > 1)
      '${waffe.ranged ? 'Schießt' : 'Trifft'} ${waffe.hits}-mal pro '
          '$schlag, jeder Treffer mit $prozent $wert.'
    else if (waffe.ranged)
      'Schießt ein Geschoss mit $prozent $wert.'
    else
      'Trifft mit $prozent $wert.',
    if (waffe.cleave) 'Trifft alle Gegner in Reichweite.',
    if (waffe.pierce) 'Durchbohrt alle Gegner in einer Linie.',
    if (waffe.arcDegrees > 0)
      'Trifft alle Gegner in einem Bogen von ${waffe.arcDegrees.round()}°.',
    if (waffe.burnPerSecond > 0)
      'Setzt in Brand: ${_prozent(waffe.burnPerSecond)} $wert pro '
          'Sekunde, ${pitNumber(ActionBalance.weaponBurnSeconds)} '
          'Sekunden lang.',
    if (waffe.manaOnHit > 0) '+${waffe.manaOnHit} Mana pro Treffer.',
    'Rund ${_tempo(waffe)} ${waffe.ranged ? 'Schüsse' : 'Schläge'} '
        'pro Sekunde.',
  ];
  return saetze.join(' ');
}

String _prozent(double faktor) => '${(faktor * 100).round()} %';

/// „deines Angriffsschadens“ oder „deiner Fähigkeitsstärke“ — je nachdem,
/// womit die Waffe skaliert (ADR-0100).
String _deinWert(double fs) {
  if (fs >= 1) return 'deiner Fähigkeitsstärke';
  if (fs <= 0) return 'deines Angriffsschadens';
  return 'deines Angriffsschadens und deiner Fähigkeitsstärke';
}

/// Schläge je Sekunde ohne Ausrüstung, auf eine Stelle: „1,8“.
String _tempo(PitWeapon waffe) {
  final s = 1 / (ActionBalance.heroAttackCooldown * waffe.cooldownFactor);
  return pitNumber((s * 10).round() / 10);
}

/// Was die Seltenheit im Kampf vervielfacht, als ein Satz (ADR-0042):
/// „Ungewöhnlich: +15 % Schaden im Kampf“. Die der Waffe trifft
/// Angriffsschaden **und** Fähigkeitsstärke, die der Rüstung das Leben;
/// nichts bei Gewöhnlich und auf den übrigen Plätzen.
String? rarityKampfText(GearItem item) {
  final f = item.rarity.powerFactor;
  final was = switch (item.slot) {
    GearSlot.waffe => 'Schaden',
    GearSlot.ruestung => 'Leben',
    _ => null,
  };
  if (f == 1 || was == null) return null;
  return '${item.rarity.label}: +${_prozent(f - 1)} $was im Kampf';
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
  final zeilen = <String>[
    ?weaponAbilityLine(item),
    ?gearPowerLine(item),
    ?rarityKampfText(item),
  ];
  return zeilen.isEmpty ? null : zeilen.join('\n');
}

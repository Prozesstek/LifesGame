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

/// Eine Zeile im Blatt, das eine Fähigkeit erklärt: „Mana" → „18".
typedef PitStat = ({String label, String value});

/// Alles, was über eine Fähigkeit zu sagen ist — Kosten, Zielen,
/// Reichweite und jede einzelne Wirkung.
///
/// **Die Wirkungen kommen aus [PitAbility.effects], nicht aus einer
/// zweiten Liste.** `PitEffect` ist `sealed`: Wer eine neue Art baut,
/// bekommt hier einen Compilerfehler statt ein Blatt, das die Hälfte
/// verschweigt. Dieselbe Naht wie in `world.dart`, nur fürs Lesen.
///
/// [attack] ist der Angriff, mit dem der Spieler gerade in die Grube
/// geht ([ActionStats.combatAttack]). Ist er da, steht neben dem Faktor
/// die Zahl, die dabei herauskommt — **flach**, ohne Abwehr des Gegners,
/// ohne Streuung und ohne kritische Treffer. Dieselbe Regel wie beim
/// alten `move_help.dart`: Was sich ausrechnen lässt, wird ausgerechnet.
List<PitStat> pitAbilityStats(PitAbility ability, {int? attack}) {
  final stats = <PitStat>[
    (label: 'Art', value: ability.kind.label),
    (
      label: 'Mana',
      value: ability.manaCost == 0 ? 'kostet nichts' : '${ability.manaCost}',
    ),
    (label: 'Abklingzeit', value: '${pitNumber(ability.cooldown)} s'),
    (label: 'Zielen', value: _zielen(ability.aim)),
  ];

  // **Reichweite und Umkreis stehen einmal oben**, nicht an jeder
  // Wirkung: Frostnebel bremst und friert auf denselben 160 Punkten,
  // und zweimal „Umkreis 160" untereinander liest sich wie ein Fehler.
  if (ability.reach > 0) {
    stats.add((
      label: ability.aim == PitAim.bereich ? 'Wurfweite' : 'Reichweite',
      value: '${ability.reach.round()}',
    ));
  }
  if (ability.areaRadius > 0) {
    stats.add((label: 'Umkreis', value: '${ability.areaRadius.round()}'));
  }

  for (final effect in ability.effects) {
    switch (effect) {
      case BoltAtNearest(:final power, :final leech):
        stats.add((label: 'Schaden', value: _schaden(power, attack)));
        if (leech > 0) {
          stats.add((
            label: 'Lebensraub',
            value: '${(leech * 100).round()} % des Schadens',
          ));
        }
      case StrikeNearest(:final power):
        stats.add((label: 'Schaden', value: _schaden(power, attack)));
      case StrikeAround(:final power):
        stats.add((label: 'Schaden', value: _schaden(power, attack)));
      case HealSelf(:final share):
        stats.add((
          label: 'Heilung',
          value: '${(share * 100).round()} % der vollen Gesundheit',
        ));
      case GainMana(:final amount):
        stats.add((label: 'Mana zurück', value: '+$amount'));
      case ReduceIncoming(:final factor, :final seconds):
        stats.add((
          label: 'Schutz',
          value:
              '${((1 - factor) * 100).round()} % weniger Schaden, '
              '${pitNumber(seconds)} s',
        ));
      case ReflectIncoming(:final share, :final seconds):
        stats.add((
          label: 'Rückwurf',
          value:
              '${(share * 100).round()} % des Nahkampfschadens, '
              '${pitNumber(seconds)} s',
        ));
      case SlowAround(:final factor, :final seconds):
        stats.add((
          label: 'Verlangsamung',
          value:
              'auf ${(factor * 100).round()} % Tempo, '
              '${pitNumber(seconds)} s',
        ));
      case DamageOverTime(:final perSecond, :final seconds):
        stats.add((
          label: 'Dauerschaden',
          value:
              '${_schaden(perSecond, attack)} je Sekunde, '
              '${pitNumber(seconds)} s',
        ));
    }
  }

  return List<PitStat>.unmodifiable(stats);
}

/// Dasselbe für einen Waffenzug — er ist der Grundangriff und hat
/// deshalb weder Mana noch Abklingzeit.
List<PitStat> pitWeaponStats(PitWeapon waffe, {int? attack}) {
  return List<PitStat>.unmodifiable(<PitStat>[
    (label: 'Art', value: 'Grundangriff — schlägt von selbst'),
    (label: 'Schaden', value: _schaden(waffe.power, attack)),
    if (waffe.hits > 1) (label: 'Treffer je Schlag', value: '${waffe.hits}'),
    (
      label: 'Reichweite',
      value:
          '${waffe.range.round()} (${waffe.ranged ? 'schießt' : 'Nahkampf'})',
    ),
    if (waffe.cooldownFactor != 1)
      (
        label: 'Tempo',
        value: waffe.cooldownFactor > 1
            ? '×${pitNumber(waffe.cooldownFactor)} langsamer'
            : '×${pitNumber(1 / waffe.cooldownFactor)} schneller',
      ),
    if (waffe.cleave) (label: 'Trifft', value: 'alle in Reichweite'),
    if (waffe.manaOnHit > 0)
      (label: 'Mana je Treffer', value: '+${waffe.manaOnHit}'),
    if (waffe.burnPerSecond > 0)
      (
        label: 'Brand',
        value: '${_schaden(waffe.burnPerSecond, attack)} je Sekunde',
      ),
  ]);
}

/// „×1,2" allein, oder „×1,2 · etwa 34", wenn der Angriff bekannt ist.
String _schaden(double power, int? attack) {
  final faktor = '×${pitNumber(power)}';
  if (attack == null) return faktor;
  return '$faktor · etwa ${(attack * power).round()}';
}

String _zielen(PitAim aim) {
  return switch (aim) {
    PitAim.selbst => 'wirkt auf dich',
    PitAim.richtung => 'Richtung — daneben ist daneben',
    PitAim.umDenHelden => 'Umkreis um dich',
    PitAim.bereich => 'Fläche, die man absetzt',
  };
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

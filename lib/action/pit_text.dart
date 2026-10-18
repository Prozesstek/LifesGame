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
  return pitAbilityOf(id)?.name ?? PitWeapons.byMoveId(id)?.name;
}

/// Die Fähigkeit zu [id] — auch eine Ultimate (ADR-0073), die
/// `PitAbilities.byId` nicht findet, weil sie auf keinem der drei Plätze
/// liegt.
PitAbility? pitAbilityOf(String id) {
  return PitAbilities.byId(id) ?? PitAbilities.ultimateById(id);
}

/// Was sie kostet und tut, in einer Zeile.
String? pitSummaryOf(String id) {
  final ability = pitAbilityOf(id);
  if (ability != null) return pitAbilitySummary(ability);

  final waffe = PitWeapons.byMoveId(id);
  if (waffe != null) return pitWeaponSummary(waffe);
  return null;
}

/// „12 Mana · 1,5 s — Ein Funke fliegt geradeaus."
String pitAbilitySummary(PitAbility ability) {
  if (ability.isUltimate) return 'Ultimate — ${ability.description}';
  if (ability.isPassive) return ability.description;
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
    (
      label: 'Art',
      value: ability.isUltimate
          ? 'Ultimate'
          : ability.isPassive
          ? 'Passiv — wirkt dauernd, ohne Knopf'
          : ability.kind.label,
    ),
    if (ability.isPassive)
      ...<PitStat>[]
    else if (ability.isUltimate)
      (
        label: 'Lädt sich',
        value:
            'mit jedem Kill um ein Achtel, auch am Wächter; '
            'jeder Lauf beginnt leer',
      )
    else ...<PitStat>[
      (
        label: 'Mana',
        value: ability.manaCost == 0 ? 'kostet nichts' : '${ability.manaCost}',
      ),
      (label: 'Abklingzeit', value: '${pitNumber(ability.cooldown)} s'),
    ],
    if (!ability.isPassive) (label: 'Zielen', value: _zielen(ability.aim)),
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
    _wirkung(effect, attack, stats);
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

/// Eine Wirkung als Zeilen im Blatt. **`PitEffect` ist `sealed`**: Eine
/// neue Art ohne Zeile hier ist ein Compilerfehler.
void _wirkung(PitEffect effect, int? attack, List<PitStat> stats) {
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
    case Dash(
      :final distance,
      :final trailPerSecond,
      :final trailSeconds,
      :final impactPower,
      :final impactStun,
    ):
      stats.add((
        label: 'Sturm',
        value: '${distance.round()} weit, durch Gegner',
      ));
      if (impactPower > 0) {
        stats.add((label: 'Rammt', value: _schaden(impactPower, attack)));
        stats.add((
          label: 'Stillstand',
          value: '${pitNumber(impactStun)} s, zur Seite geworfen',
        ));
      }
      if (trailPerSecond > 0) {
        stats.add((
          label: 'Spur',
          value:
              '${_schaden(trailPerSecond, attack)} je Sekunde, '
              '${pitNumber(trailSeconds)} s',
        ));
      }
    case HookNearest(:final power, :final stunSeconds):
      stats.add((label: 'Haken', value: 'zieht einen Gegner heran'));
      stats.add((label: 'Schaden', value: _schaden(power, attack)));
      stats.add((label: 'Stillstand', value: '${pitNumber(stunSeconds)} s'));
    case PullToCenter(:final stunSeconds):
      stats.add((label: 'Strudel', value: 'zieht alle zur Mitte'));
      stats.add((label: 'Stillstand', value: '${pitNumber(stunSeconds)} s'));
    case SelfBuff(
      :final seconds,
      :final attack,
      :final haste,
      :final moveSpeed,
    ):
      final teile = <String>[
        if (attack != 1) 'Angriff +${((attack - 1) * 100).round()} %',
        if (haste != 1) 'Schlagtempo +${((haste - 1) * 100).round()} %',
        if (moveSpeed != 1) 'Lauftempo +${((moveSpeed - 1) * 100).round()} %',
      ];
      stats.add((
        label: 'Stärkung',
        value: '${teile.join(', ')}, ${pitNumber(seconds)} s',
      ));
    case RandomOf(:final outcomes):
      final summe = outcomes.fold<int>(0, (s, o) => s + o.weight);
      for (final o in outcomes) {
        final teil = <PitStat>[];
        for (final e in o.effects) {
          _wirkung(e, attack, teil);
        }
        // Ein Wurf mit mehreren Wirkungen ist der Jackpot: alle davor
        // zugleich. Sie noch einmal aufzuzählen, verdoppelte das Blatt.
        stats.add((
          label: 'Wurf ${(o.weight * 100 / summe).round()} %',
          value: o.effects.length > 1
              ? 'alles zugleich'
              : teil.map((t) => t.value).join(' · '),
        ));
      }
    case Boomerang(:final power):
      stats.add((label: 'Hin und zurück', value: _schaden(power, attack)));
    case Trap(:final power, :final stunSeconds, :final seconds):
      stats.add((label: 'Falle', value: _schaden(power, attack)));
      stats.add((label: 'Stillstand', value: '${pitNumber(stunSeconds)} s'));
      stats.add((
        label: 'Liegt',
        value: '${pitNumber(seconds)} s, höchstens ${ActionBalance.maxTraps}',
      ));
    case Companion(:final power, :final seconds, mirror: true):
      stats.add((
        label: 'Abbild',
        value:
            'bleibt stehen, wo du es rufst, und schlägt mit deinem '
            'Grundangriff zu ${(power * 100).round()} %, '
            '${pitNumber(seconds)} s lang',
      ));
    case Companion(
      :final power,
      :final interval,
      :final seconds,
      :final devourBelow,
    ):
      stats.add((
        label: 'Begleiter',
        value:
            '${_schaden(power, attack)} alle ${pitNumber(interval)} s, '
            '${pitNumber(seconds)} s lang',
      ));
      if (devourBelow > 0) {
        stats.add((
          label: 'Frisst',
          value:
              'unter ${(devourBelow * 100).round()} % Leben, '
              'nie den Wächter',
        ));
      }
    case Rock(:final seconds):
      stats.add((
        label: 'Fels',
        value: 'ein Feld Wand, ${pitNumber(seconds)} s',
      ));
    case SweepCone(:final power, :final fling):
      stats.add((label: 'Schaden', value: _schaden(power, attack)));
      stats.add((label: 'Schleudert', value: '${fling.round()} zur Seite'));
    case FreezeBolt(:final power, :final stunSeconds):
      stats.add((label: 'Schaden', value: _schaden(power, attack)));
      stats.add((
        label: 'Gefroren',
        value: '${pitNumber(stunSeconds)} s; der nächste Treffer ist kritisch',
      ));
    // --- ADR-0074 ---
    case Blink(:final distance):
      stats.add((
        label: 'Sprung',
        value: 'bis ${distance.round()}, nie durch Wand oder Tor',
      ));
    case Vanish(:final seconds, :final ambush):
      stats.add((
        label: 'Unsichtbar',
        value: '${pitNumber(seconds)} s, bis zum ersten eigenen Treffer',
      ));
      if (ambush > 1) {
        stats.add((
          label: 'Erster Treffer',
          value: '×${pitNumber(ambush)} Schaden',
        ));
      }
    case StunAround(:final seconds):
      stats.add((
        label: 'Stillstand',
        value: '${pitNumber(seconds)} s für alle im Umkreis',
      ));
    case Parry(:final seconds, :final stunSeconds):
      stats.add((
        label: 'Parade',
        value: '${pitNumber(seconds)} s offen, fängt einen Treffer ganz ab',
      ));
      stats.add((
        label: 'Stillstand',
        value: '${pitNumber(stunSeconds)} s für den Angreifer',
      ));
    case Stacking(:final step, :final window, :final maxStacks):
      stats.add((
        label: 'Zinseszins',
        value:
            '+${(step * 100).round()} % je Wiederholung binnen '
            '${pitNumber(window)} s, bis $maxStacks×',
      ));
    case ChainBolt(:final power, :final jumps, :final falloff):
      stats.add((label: 'Schaden', value: _schaden(power, attack)));
      stats.add((
        label: 'Springt',
        value:
            'auf bis zu $jumps weitere, je ${(falloff * 100).round()} % '
            'der Wucht davor',
      ));
    case Overdrive(
      :final seconds,
      :final abilityPower,
      :final attackPower,
      :final cooldownRate,
    ):
      stats.add((
        label: 'Bestform',
        value:
            '${pitNumber(seconds)} s: Fähigkeiten '
            '+${((abilityPower - 1) * 100).round()} %, ohne Mana, '
            'Abklingzeit ×${pitNumber(cooldownRate)} so schnell',
      ));
      stats.add((
        label: 'Grundangriff',
        value: '+${((attackPower - 1) * 100).round()} %',
      ));
    case Rewind(:final seconds, :final invulnerableSeconds):
      stats.add((
        label: 'Zurück',
        value: 'an Ort und Leben von vor ${pitNumber(seconds)} s',
      ));
      stats.add((
        label: 'Unverwundbar',
        value: '${pitNumber(invulnerableSeconds)} s',
      ));
    case RageOnHit(:final perHit, :final maxStacks, :final decaySeconds):
      stats.add((
        label: 'Kampfrausch',
        value:
            '+${(perHit * 100).round()} % je eingesteckten Treffer, bis '
            '$maxStacks×; fällt nach ${pitNumber(decaySeconds)} s ab',
      ));
    case RestMana(:final factor, :final idleSeconds):
      stats.add((
        label: 'Ruhepuls',
        value:
            'Mana ${((factor - 1) * 100).round()} % schneller nach '
            '${pitNumber(idleSeconds)} s ohne eigenen Treffer',
      ));
    case LastStand(
      :final threshold,
      :final heal,
      :final wardFactor,
      :final wardSeconds,
    ):
      stats.add((
        label: 'Zweiter Atem',
        value: 'einmal je Lauf unter ${(threshold * 100).round()} % Leben',
      ));
      stats.add((
        label: 'Heilung',
        value: '${(heal * 100).round()} % der vollen Gesundheit',
      ));
      stats.add((
        label: 'Schutz',
        value:
            '${((1 - wardFactor) * 100).round()} % weniger Schaden, '
            '${pitNumber(wardSeconds)} s',
      ));
  }
}

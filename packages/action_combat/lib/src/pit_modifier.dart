import 'dart:math' as math;

import 'pit_ability.dart';

/// Was eine Fähigkeit ist — die Einteilung, auf die Sets wirken
/// (ADR-0030, ADR-0039).
///
/// **Dieselben drei Arten wie im Rundenkampf**, und für jede Fähigkeit
/// dieselbe Zuordnung. Dort wurde die Art aus dem Zug abgeleitet; in der
/// Grube geht das nicht sauber (Wurzelgriff verlangsamt und ist trotzdem
/// ein Angriff), also steht sie am Eintrag, und ein Test in der App hält
/// sie gleich, solange es `package:combat` noch gibt.
enum PitKind {
  angriff('Angriff'),
  umgebung('Umgebung'),
  schutz('Schutz');

  const PitKind(this.label);

  final String label;
}

/// Eine Veränderung an Fähigkeiten — von einem Set oder einem legendären
/// Stück (Issue #65: „Effekte, die sich leicht durch Sets oder
/// Legendaries verändern lassen").
///
/// **Sie verändert Daten, nicht die Welt.** [PitModifiers.apply] nimmt
/// eine Fähigkeit und gibt eine neue zurück; die Welt sieht nur das
/// Ergebnis. Ein Set braucht deshalb keine Zeile in `world.dart`.
///
/// [kind] `null` heisst: wirkt auf jede Fähigkeit.
sealed class PitModifier {
  const PitModifier();
}

/// Mehr Schaden: Geschosse, Schläge und Dauerschaden mal [factor].
final class ScaleDamage extends PitModifier {
  const ScaleDamage({required this.factor, this.kind});

  final double factor;
  final PitKind? kind;
}

/// Nur Dauerschaden mal [factor] — Gift, Brand, Frost.
final class ScaleOverTime extends PitModifier {
  const ScaleOverTime({required this.factor, this.kind});

  final double factor;
  final PitKind? kind;
}

/// Billiger: erst mal [factor], dann minus [amount], nie unter null.
final class ReduceManaCost extends PitModifier {
  const ReduceManaCost({this.amount = 0, this.factor = 1, this.kind});

  final int amount;
  final double factor;
  final PitKind? kind;
}

/// Schutz wirkt stärker: Heilung mal [factor], Schadensminderung und
/// Zurückwerfen halten mal [factor] so lange.
final class ScaleProtection extends PitModifier {
  const ScaleProtection({required this.factor, this.kind});

  final double factor;
  final PitKind? kind;
}

/// Schneller wieder bereit: Abklingzeit mal [factor].
final class ScaleCooldown extends PitModifier {
  const ScaleCooldown({required this.factor, this.kind});

  final double factor;
  final PitKind? kind;
}

/// Eine Fähigkeit bekommt zusätzliche Wirkungen — der Stoff, aus dem
/// legendäre Kräfte sind.
final class AddEffects extends PitModifier {
  const AddEffects({required this.abilityId, required this.effects});

  final String abilityId;
  final List<PitEffect> effects;
}

/// **Kein Umbau einer Fähigkeit, sondern eine Wirkung am Helden** — die
/// Kräfte der Ausrüstung seit ADR-0077 (Lebensraub, Frostreif,
/// Irrlichter …). [PitModifiers.apply] lässt jede Fähigkeit dabei, wie
/// sie ist; `ActionWorld` sammelt das [passive] zu den Passiven der
/// Plätze.
final class GrantPassive extends PitModifier {
  const GrantPassive(this.passive);

  final PitPassive passive;
}

/// Wendet Veränderungen an.
abstract final class PitModifiers {
  /// [ability] mit allen [modifiers], in Reihenfolge.
  ///
  /// **Faktoren multiplizieren sich**: Zwei Sets mit +10 % geben +21 %,
  /// nicht +20 %. Das ist die einfachste Regel, die in jeder Reihenfolge
  /// dasselbe ergibt.
  static PitAbility apply(PitAbility ability, List<PitModifier> modifiers) {
    var ergebnis = ability;
    for (final modifier in modifiers) {
      ergebnis = _one(ergebnis, modifier);
    }
    return ergebnis;
  }

  static PitAbility _one(PitAbility a, PitModifier m) {
    switch (m) {
      case ScaleDamage(:final factor, :final kind):
        if (!_trifft(a, kind)) return a;
        return _mitWirkungen(a, (e) => _schaden(e, factor, factor));
      case ScaleOverTime(:final factor, :final kind):
        if (!_trifft(a, kind)) return a;
        return _mitWirkungen(a, (e) => _schaden(e, 1, factor));
      case ReduceManaCost(:final amount, :final factor, :final kind):
        if (!_trifft(a, kind)) return a;
        final kosten = math.max(0, (a.manaCost * factor).round() - amount);
        return _kopie(a, manaCost: kosten);
      case ScaleProtection(:final factor, :final kind):
        if (!_trifft(a, kind)) return a;
        return _mitWirkungen(a, (e) => _schutz(e, factor));
      case ScaleCooldown(:final factor, :final kind):
        if (!_trifft(a, kind)) return a;
        return _kopie(a, cooldown: a.cooldown * factor);
      case AddEffects(:final abilityId, :final effects):
        if (a.id != abilityId) return a;
        return _kopie(a, effects: <PitEffect>[...a.effects, ...effects]);
      case GrantPassive():
        return a;
    }
  }

  static bool _trifft(PitAbility a, PitKind? kind) {
    return kind == null || a.kind == kind;
  }

  static PitAbility _mitWirkungen(
    PitAbility a,
    PitEffect Function(PitEffect) wandle,
  ) {
    return _kopie(a, effects: a.effects.map(wandle).toList());
  }

  /// Schaden: [direkt] auf Treffer, [dauer] auf Dauerschaden.
  static PitEffect _schaden(PitEffect e, double direkt, double dauer) {
    return switch (e) {
      BoltAtNearest(:final power, :final range, :final leech) =>
        BoltAtNearest(power: power * direkt, range: range, leech: leech),
      StrikeNearest(:final power, :final range) =>
        StrikeNearest(power: power * direkt, range: range),
      StrikeAround(:final power, :final radius) =>
        StrikeAround(power: power * direkt, radius: radius),
      DamageOverTime(:final radius, :final perSecond, :final seconds) =>
        DamageOverTime(
          radius: radius,
          perSecond: perSecond * dauer,
          seconds: seconds,
        ),
      FreezeBolt(:final power, :final range, :final stunSeconds) => FreezeBolt(
          power: power * direkt,
          range: range,
          stunSeconds: stunSeconds,
        ),
      HookNearest(:final range, :final power, :final stunSeconds) =>
        HookNearest(
          range: range,
          power: power * direkt,
          stunSeconds: stunSeconds,
        ),
      Boomerang(:final power, :final range) =>
        Boomerang(power: power * direkt, range: range),
      Trap(:final power, :final stunSeconds, :final seconds) => Trap(
          power: power * direkt,
          stunSeconds: stunSeconds,
          seconds: seconds,
        ),
      SweepCone(:final power, :final range, :final fling) =>
        SweepCone(power: power * direkt, range: range, fling: fling),
      Companion() => Companion(
          power: e.power * direkt,
          interval: e.interval,
          seconds: e.seconds,
          reach: e.reach,
          stationary: e.stationary,
          devourBelow: e.devourBelow,
          mirror: e.mirror,
        ),
      Dash() => Dash(
          distance: e.distance,
          trailPerSecond: e.trailPerSecond * dauer,
          trailSeconds: e.trailSeconds,
          trailRadius: e.trailRadius,
          impactPower: e.impactPower * direkt,
          impactFling: e.impactFling,
          impactStun: e.impactStun,
        ),
      ChainBolt() => ChainBolt(
          power: e.power * direkt,
          range: e.range,
          jumps: e.jumps,
          jumpRange: e.jumpRange,
          falloff: e.falloff,
        ),
      RandomOf(:final outcomes) => RandomOf(
          outcomes: <PitOutcome>[
            for (final o in outcomes)
              PitOutcome(
                weight: o.weight,
                effects: <PitEffect>[
                  for (final w in o.effects) _schaden(w, direkt, dauer),
                ],
              ),
          ],
        ),
      HealSelf() ||
      GainMana() ||
      ReduceIncoming() ||
      ReflectIncoming() ||
      SlowAround() ||
      PullToCenter() ||
      SelfBuff() ||
      Rock() ||
      Blink() ||
      Vanish() ||
      StunAround() ||
      Parry() ||
      Stacking() ||
      Overdrive() ||
      Rewind() ||
      PitPassive() =>
        e,
    };
  }

  static PitEffect _schutz(PitEffect e, double factor) {
    return switch (e) {
      HealSelf(:final share) => HealSelf(share: share * factor),
      ReduceIncoming(factor: final minderung, :final seconds) =>
        ReduceIncoming(factor: minderung, seconds: seconds * factor),
      ReflectIncoming(:final share, :final seconds) =>
        ReflectIncoming(share: share, seconds: seconds * factor),
      SelfBuff() => SelfBuff(
          seconds: e.seconds * factor,
          attack: e.attack,
          haste: e.haste,
          moveSpeed: e.moveSpeed,
        ),
      RandomOf(:final outcomes) => RandomOf(
          outcomes: <PitOutcome>[
            for (final o in outcomes)
              PitOutcome(
                weight: o.weight,
                effects: <PitEffect>[
                  for (final w in o.effects) _schutz(w, factor),
                ],
              ),
          ],
        ),
      BoltAtNearest() ||
      StrikeNearest() ||
      StrikeAround() ||
      GainMana() ||
      SlowAround() ||
      DamageOverTime() ||
      Dash() ||
      HookNearest() ||
      PullToCenter() ||
      Boomerang() ||
      Trap() ||
      Companion() ||
      Rock() ||
      SweepCone() ||
      FreezeBolt() ||
      Blink() ||
      Vanish() ||
      StunAround() ||
      Parry() ||
      Stacking() ||
      ChainBolt() ||
      Overdrive() ||
      Rewind() ||
      PitPassive() =>
        e,
    };
  }

  static PitAbility _kopie(
    PitAbility a, {
    int? manaCost,
    double? cooldown,
    List<PitEffect>? effects,
  }) {
    return PitAbility(
      id: a.id,
      name: a.name,
      kind: a.kind,
      manaCost: manaCost ?? a.manaCost,
      cooldown: cooldown ?? a.cooldown,
      effects: List<PitEffect>.unmodifiable(effects ?? a.effects),
      description: a.description,
      aim: a.aim,
      castRange: a.castRange,
      tint: a.tint,
      isUltimate: a.isUltimate,
    );
  }
}

/// Eine Kraft der Ausrüstung: was ein Stück oder ein Set in der Grube
/// ändert — an den Fähigkeiten oder, über [GrantPassive], am Helden.
///
/// **Bis ADR-0077 trugen nur legendäre Stücke eine**; seitdem kann jedes
/// Stück eine haben, und ein Set auch (`SetPerk.powers`).
///
/// **Die Id steht am Stück in `package:gear`** (`GearItem.power`),
/// die Wirkung hier. Dieselbe Naht wie bei den Fähigkeiten: Ids, die
/// über eine Package-Grenze zeigen, und ein Test in der App, der prüft,
/// dass keine ins Leere zeigt.
class PitGearPower {
  const PitGearPower({
    required this.id,
    required this.name,
    required this.description,
    required this.modifiers,
  });

  final String id;
  final String name;
  final String description;
  final List<PitModifier> modifiers;
}

/// Die Kräfte der Ausrüstung: die sechs legendären, dazu seit ADR-0077
/// die der neuen Stücke und des Vampirsets.
///
/// **Jede verändert, statt nur zu verstärken.** Ein legendäres Stück, das
/// nur „+15 % Schaden" gibt, ist ein teures episches. Diese hier ändern,
/// was eine Fähigkeit *tut* oder wie oft man sie drückt.
abstract final class PitGearPowers {
  static const PitGearPower sonnenglut = PitGearPower(
    id: 'legendaer-sonnenglut',
    name: 'Sonnenglut',
    description: 'Jeder Dauerschaden brennt anderthalbmal so heiss.',
    modifiers: <PitModifier>[ScaleOverTime(factor: 1.5)],
  );

  static const PitGearPower steinerneHaut = PitGearPower(
    id: 'legendaer-steinerne-haut',
    name: 'Steinerne Haut',
    description: 'Steinhaut und Sammeln werfen zusätzlich ein Drittel des '
        'Schadens zurück.',
    modifiers: <PitModifier>[
      AddEffects(
        abilityId: 'steinhaut',
        effects: <PitEffect>[ReflectIncoming(share: 0.33, seconds: 5)],
      ),
      AddEffects(
        abilityId: 'mend',
        effects: <PitEffect>[ReflectIncoming(share: 0.33, seconds: 4)],
      ),
    ],
  );

  static const PitGearPower weitblick = PitGearPower(
    id: 'legendaer-weitblick',
    name: 'Weitblick',
    description: 'Jede Fähigkeit ist ein Fünftel schneller wieder bereit.',
    modifiers: <PitModifier>[ScaleCooldown(factor: 0.8)],
  );

  static const PitGearPower beben = PitGearPower(
    id: 'legendaer-beben',
    name: 'Beben',
    description: 'Kraftschlag und Wurzelgriff lassen den Boden beben: Alles '
        'in der Nähe wird getroffen und gebremst.',
    modifiers: <PitModifier>[
      AddEffects(
        abilityId: 'heavy_attack',
        effects: <PitEffect>[
          StrikeAround(power: 1.0, radius: 80),
          SlowAround(radius: 80, factor: 0.5, seconds: 2),
        ],
      ),
      AddEffects(
        abilityId: 'wurzelgriff',
        effects: <PitEffect>[StrikeAround(power: 1.0, radius: 90)],
      ),
    ],
  );

  static const PitGearPower erzhunger = PitGearPower(
    id: 'legendaer-erzhunger',
    name: 'Erzhunger',
    description: 'Jede Fähigkeit kostet ein Drittel weniger Mana.',
    modifiers: <PitModifier>[ReduceManaCost(factor: 0.67)],
  );

  static const PitGearPower lebensquell = PitGearPower(
    id: 'legendaer-lebensquell',
    name: 'Lebensquell',
    description: 'Heilung und Schutz wirken anderthalbmal so stark.',
    modifiers: <PitModifier>[ScaleProtection(factor: 1.5)],
  );

  // --- Seit ADR-0077 ---

  static const PitGearPower frostreif = PitGearPower(
    id: 'kraft-frostreif',
    name: 'Frostreif',
    description: 'Ein Kreis aus Eis geht mit dir. Wer darin steht, läuft '
        'langsamer und friert.',
    modifiers: <PitModifier>[
      GrantPassive(FrostAura(radius: 60, slowFactor: 0.7, perSecond: 0.1)),
    ],
  );

  static const PitGearPower irrlichter = PitGearPower(
    id: 'kraft-irrlichter',
    name: 'Irrlichter',
    description: 'Alle fünf Sekunden ein Irrlicht, höchstens drei. Sie '
        'kreisen um dich, suchen Gegner in der Nähe und zerplatzen an '
        'ihnen.',
    modifiers: <PitModifier>[
      GrantPassive(
        Wisps(
          interval: 5,
          maxCount: 3,
          seekRange: 160,
          power: 1.2,
          blastRadius: 40,
        ),
      ),
    ],
  );

  static const PitGearPower flickwerk = PitGearPower(
    id: 'kraft-flickwerk',
    name: 'Flickwerk',
    description: 'Drei Sekunden ohne Treffer, und ein Schild aus einem '
        'Zehntel deines Lebens legt sich um dich.',
    modifiers: <PitModifier>[
      GrantPassive(IdleShield(idleSeconds: 3, share: 0.1)),
    ],
  );

  static const PitGearPower falkenblick = PitGearPower(
    id: 'kraft-falkenblick',
    name: 'Falkenblick',
    description: 'Fünf Prozent mehr kritische Treffer, und jeder bringt '
        'drei Mana.',
    // Erst 6 % und 5 Mana: Stufe 13 stieg von 18 auf 58 % — mehr als
    // jede andere Kraft, auf einer ungewöhnlichen Haube.
    modifiers: <PitModifier>[
      GrantPassive(CritEdge(chance: 0.05, manaOnCrit: 3)),
    ],
  );

  static const PitGearPower hasenlauf = PitGearPower(
    id: 'kraft-hasenlauf',
    name: 'Hasenlauf',
    description: 'Nach jedem Kill zwei Sekunden lang ein Drittel schneller.',
    modifiers: <PitModifier>[
      GrantPassive(KillRush(seconds: 2, speed: 1.3)),
    ],
  );

  static const PitGearPower seelenernte = PitGearPower(
    id: 'kraft-seelenernte',
    name: 'Seelenernte',
    description: 'Jeder Kill bringt acht Mana.',
    modifiers: <PitModifier>[GrantPassive(ManaOnKill(amount: 8))],
  );

  static const PitGearPower echo = PitGearPower(
    id: 'kraft-echo',
    name: 'Echo',
    description: 'Jede vierte Fähigkeit, die Schaden macht, trifft ein '
        'zweites Mal mit halber Wucht.',
    modifiers: <PitModifier>[GrantPassive(Echo(every: 4, power: 0.5))],
  );

  // Das Vampirset: vier Teile mit Lebensraub, zwei Stufen am Set.

  static const PitGearPower blutsichel = PitGearPower(
    id: 'kraft-lebensraub-sichel',
    name: 'Lebensraub',
    description: 'Vier Prozent deines Schadens heilen dich.',
    modifiers: <PitModifier>[GrantPassive(LifeSteal(share: 0.04))],
  );

  static const PitGearPower nachtmantel = PitGearPower(
    id: 'kraft-lebensraub-mantel',
    name: 'Lebensraub',
    description: 'Drei Prozent deines Schadens heilen dich.',
    modifiers: <PitModifier>[GrantPassive(LifeSteal(share: 0.03))],
  );

  static const PitGearPower fledermaushaube = PitGearPower(
    id: 'kraft-lebensraub-haube',
    name: 'Lebensraub',
    description: 'Zwei Prozent deines Schadens heilen dich.',
    modifiers: <PitModifier>[GrantPassive(LifeSteal(share: 0.02))],
  );

  static const PitGearPower schattenstiefel = PitGearPower(
    id: 'kraft-lebensraub-stiefel',
    name: 'Lebensraub',
    description: 'Drei Prozent deines Schadens heilen dich.',
    modifiers: <PitModifier>[GrantPassive(LifeSteal(share: 0.03))],
  );

  /// Zwei Teile des Vampirsets.
  static const PitGearPower blutdurst = PitGearPower(
    id: 'kraft-blutdurst',
    name: 'Blutdurst',
    description: 'Jeder Kill heilt drei Prozent deines Lebens.',
    modifiers: <PitModifier>[GrantPassive(HealOnKill(share: 0.03))],
  );

  /// Alle vier Teile: ersetzt [blutdurst], wie die volle Stufe jedes Sets
  /// die kleine ersetzt — deshalb steht die Kill-Heilung hier noch einmal.
  static const PitGearPower blutpakt = PitGearPower(
    id: 'kraft-blutpakt',
    name: 'Blutpakt',
    description: 'Jede Sekunde verlierst du zwei Prozent deines Lebens. '
        'Der Lebensraub zählt doppelt, und ein Fünftel dessen, was er '
        'heilen könnte, trifft den Gegner. Sonst heilt dich nichts: Jede '
        'andere Heilung trifft stattdessen den nächsten Gegner.',
    modifiers: <PitModifier>[
      GrantPassive(HealOnKill(share: 0.03)),
      GrantPassive(
        BloodPact(drainShare: 0.02, stealFactor: 2, stealDamageShare: 0.2),
      ),
    ],
  );

  static const List<PitGearPower> all = <PitGearPower>[
    sonnenglut,
    steinerneHaut,
    weitblick,
    beben,
    erzhunger,
    lebensquell,
    frostreif,
    irrlichter,
    flickwerk,
    falkenblick,
    hasenlauf,
    seelenernte,
    echo,
    blutsichel,
    nachtmantel,
    fledermaushaube,
    schattenstiefel,
    blutdurst,
    blutpakt,
  ];

  static PitGearPower? byId(String? id) {
    if (id == null) return null;
    for (final kraft in all) {
      if (kraft.id == id) return kraft;
    }
    return null;
  }
}

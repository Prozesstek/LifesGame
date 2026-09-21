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
      HealSelf() ||
      GainMana() ||
      ReduceIncoming() ||
      ReflectIncoming() ||
      SlowAround() =>
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
      BoltAtNearest() ||
      StrikeNearest() ||
      StrikeAround() ||
      GainMana() ||
      SlowAround() ||
      DamageOverTime() =>
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
    );
  }
}

/// Eine legendäre Kraft: was ein legendäres Stück an Fähigkeiten ändert.
///
/// **Die Id steht am Stück in `package:gear`** (`GearItem.legendaryPower`),
/// die Wirkung hier. Dieselbe Naht wie bei den Fähigkeiten: Ids, die
/// über eine Package-Grenze zeigen, und ein Test in der App, der prüft,
/// dass keine ins Leere zeigt.
class PitLegendary {
  const PitLegendary({
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

/// Die sechs legendären Kräfte — eine je legendärem Stück.
///
/// **Jede verändert, statt nur zu verstärken.** Ein legendäres Stück, das
/// nur „+15 % Schaden" gibt, ist ein teures episches. Diese hier ändern,
/// was eine Fähigkeit *tut* oder wie oft man sie drückt.
abstract final class PitLegendaries {
  static const PitLegendary sonnenglut = PitLegendary(
    id: 'legendaer-sonnenglut',
    name: 'Sonnenglut',
    description: 'Jeder Dauerschaden brennt anderthalbmal so heiss.',
    modifiers: <PitModifier>[ScaleOverTime(factor: 1.5)],
  );

  static const PitLegendary steinerneHaut = PitLegendary(
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

  static const PitLegendary weitblick = PitLegendary(
    id: 'legendaer-weitblick',
    name: 'Weitblick',
    description: 'Jede Fähigkeit ist ein Fünftel schneller wieder bereit.',
    modifiers: <PitModifier>[ScaleCooldown(factor: 0.8)],
  );

  static const PitLegendary beben = PitLegendary(
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

  static const PitLegendary erzhunger = PitLegendary(
    id: 'legendaer-erzhunger',
    name: 'Erzhunger',
    description: 'Jede Fähigkeit kostet ein Drittel weniger Mana.',
    modifiers: <PitModifier>[ReduceManaCost(factor: 0.67)],
  );

  static const PitLegendary lebensquell = PitLegendary(
    id: 'legendaer-lebensquell',
    name: 'Lebensquell',
    description: 'Heilung und Schutz wirken anderthalbmal so stark.',
    modifiers: <PitModifier>[ScaleProtection(factor: 1.5)],
  );

  static const List<PitLegendary> all = <PitLegendary>[
    sonnenglut,
    steinerneHaut,
    weitblick,
    beben,
    erzhunger,
    lebensquell,
  ];

  static PitLegendary? byId(String? id) {
    if (id == null) return null;
    for (final kraft in all) {
      if (kraft.id == id) return kraft;
    }
    return null;
  }
}

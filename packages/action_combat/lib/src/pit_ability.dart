/// Die Fähigkeiten der Grube — Mana, Abklingzeit, Wirkung (ADR-0039).
///
/// **Die Ids sind dieselben wie im Rundenkampf.** Freigeschaltet wird
/// weiterhin über `package:abilities` (Baum, Streak-Marken,
/// Errungenschaften); hier steht nur, was eine Fähigkeit in Echtzeit
/// **tut**. Eine Id ohne Eintrag hier liegt auf ihrem Platz und tut in der
/// Grube nichts.
///
/// **Eine Wirkung ist ein Datum, kein Code.** Eine Fähigkeit ist eine
/// Liste von [PitEffect]s, und die Welt kennt jede Art genau einmal. Das
/// ist die Naht für Sets und Legendäre: Sie verändern eine Liste (mehr
/// Schaden, zweites Geschoss, zusätzlich heilen), statt Sonderfälle in
/// die Welt zu schreiben. Die neunzehn Fähigkeiten unten sind aus nur
/// neun Arten gebaut.
library;

import 'pit_modifier.dart';

/// Was eine Fähigkeit bewirkt. Neue Arten kommen hier dazu, und der
/// Analyzer zeigt danach auf die eine Stelle in der Welt, die sie
/// ausführen muss — dafür ist die Klasse `sealed`.
sealed class PitEffect {
  const PitEffect();
}

/// Ein Geschoss, das [range] weit fliegt — gezielt in eine Richtung, oder
/// beim kurzen Tippen auf den nächsten **sichtbaren** Gegner.
///
/// Der Schaden fällt beim Einschlag und rechnet wie ein Schlag des
/// Helden: `Angriff × power`, minus Verteidigung, mit Streuung und
/// kritischen Treffern. Damit hängt die Fähigkeit am Angriffswert und
/// über ihn an den Gewohnheiten — dieselbe Regel wie im Rundenkampf
/// (ADR-0022).
///
/// [leech] heilt den Helden um diesen Anteil des angerichteten Schadens.
final class BoltAtNearest extends PitEffect {
  const BoltAtNearest({
    required this.power,
    required this.range,
    this.leech = 0,
  });

  final double power;
  final double range;
  final double leech;
}

/// Ein Schlag in Nahkampfreichweite [range] — gezielt auf den nächsten
/// Gegner im Kegel davor, beim kurzen Tippen auf den nächsten überhaupt.
final class StrikeNearest extends PitEffect {
  const StrikeNearest({required this.power, required this.range});

  final double power;
  final double range;
}

/// Trifft alles im Umkreis [radius] — um den Helden, oder um den
/// Punkt, an dem ein [PitAim.bereich] abgesetzt wurde.
final class StrikeAround extends PitEffect {
  const StrikeAround({required this.power, required this.radius});

  final double power;
  final double radius;
}

/// Heilt einen Anteil der vollen Gesundheit.
///
/// Ein Anteil statt einer festen Zahl, aus demselben Grund wie bei den
/// Heilkugeln: Er ist auf jeder Machtstufe gleich viel wert.
final class HealSelf extends PitEffect {
  const HealSelf({required this.share});

  final double share;
}

/// Bringt Mana zurück — die Fähigkeiten, die andere bezahlen.
final class GainMana extends PitEffect {
  const GainMana({required this.amount});

  final int amount;
}

/// Eingehender Schaden mal [factor], für [seconds] Sekunden.
///
/// Mehrere davon verrechnen sich nicht: Es gilt die stärkere, und die
/// Dauer beginnt neu. Sonst stapelte ein Set mit einer Fähigkeit zu
/// Unverwundbarkeit.
final class ReduceIncoming extends PitEffect {
  const ReduceIncoming({required this.factor, required this.seconds});

  final double factor;
  final double seconds;
}

/// Wirft [share] des Schadens, den ein Nahkämpfer anrichtet, auf ihn
/// zurück — [seconds] Sekunden lang. Pfeile werden nicht zurückgeworfen:
/// Wer schiesst, steht nicht daneben.
final class ReflectIncoming extends PitEffect {
  const ReflectIncoming({required this.share, required this.seconds});

  final double share;
  final double seconds;
}

/// Verlangsamt alle Gegner im Umkreis [radius]: Laufen **und** Zuschlagen
/// geschehen mit [factor] ihres Tempos, [seconds] Sekunden lang.
///
/// Wie bei der Schadensminderung gilt bei zweien die stärkere.
final class SlowAround extends PitEffect {
  const SlowAround({
    required this.radius,
    required this.factor,
    required this.seconds,
  });

  final double radius;
  final double factor;
  final double seconds;
}

/// Schaden über Zeit auf alle Gegner im Umkreis [radius] — Gift, Brand,
/// Frost, je nach Fähigkeit. Je Sekunde `Angriff × perSecond`, **ohne**
/// Abzug der Verteidigung: Dauerschaden ist die Antwort auf zähe Gegner.
///
/// Wie im Rundenkampf ein Vielfaches des Angriffswerts, nie eine feste
/// Zahl (`CLAUDE.md`, Fähigkeiten).
final class DamageOverTime extends PitEffect {
  const DamageOverTime({
    required this.radius,
    required this.perSecond,
    required this.seconds,
  });

  final double radius;
  final double perSecond;
  final double seconds;
}

/// Wie eine Fähigkeit gezielt wird.
///
/// **Kurz tippen zielt von selbst, halten zielt von Hand** — bei allen
/// Arten gleich, nur was gezeigt und wohin gewirkt wird, unterscheidet
/// sich. Die Welt zeigt es vorher (`ActionWorld.aimPreview`) und wirkt
/// danach genau dorthin (`ActionWorld.castAt`).
enum PitAim {
  /// Wirkt auf den Helden selbst — Heilung, Mana, Schutz. Nichts zu zielen.
  selbst,

  /// Eine Richtung: ein Geschoss fliegt geradeaus bis zu seiner
  /// Reichweite, ein Schlag trifft, wer davor steht. **Daneben ist
  /// daneben** — das Mana ist dann trotzdem weg.
  richtung,

  /// Ein Kreis um den Helden. Zu zielen gibt es nichts, aber man sieht
  /// vorher, was er erfasst.
  umDenHelden,

  /// Ein Kreis, den man bis [PitAbility.castRange] entfernt absetzt. Was
  /// darin bremst oder brennt, **bleibt liegen** und wirkt auf jeden,
  /// der hineinläuft — das Eisfeld, der Giftboden.
  bereich,
}

/// Welche Farbe die Fläche einer Fähigkeit trägt — beim Zielen und, wo
/// sie liegen bleibt, am Boden. **Rot ist dem Wächter vorbehalten**:
/// Seine Ankündigungen müssen von allem zu unterscheiden sein, was der
/// Held selbst auslöst.
enum PitTint {
  funke,
  blitz,
  seele,
  klinge,
  natur,
  eis,
  sand,
  gift,
  zeit,
  lava,
  stern,
  schutz
}

/// Eine Fähigkeit, wie die Grube sie kennt.
class PitAbility {
  const PitAbility({
    required this.id,
    required this.name,
    required this.kind,
    required this.manaCost,
    required this.cooldown,
    required this.effects,
    required this.description,
    required this.aim,
    required this.castRange,
    required this.tint,
  });

  /// Dieselbe Id wie in `package:combat` und `package:abilities`.
  final String id;
  final String name;

  /// Worauf ein Set wirkt (ADR-0030).
  final PitKind kind;

  /// 0 bei den Fähigkeiten, die Mana **bringen** statt es zu kosten.
  final int manaCost;

  /// Sekunden bis zum nächsten Einsatz.
  final double cooldown;

  final List<PitEffect> effects;

  /// Was sie tut, in einem Satz — für das Blatt, das sie erklärt.
  final String description;

  /// Wie sie gezielt wird.
  final PitAim aim;

  /// Wie weit vom Helden ein [PitAim.bereich] abgesetzt werden darf. Bei
  /// allen anderen Arten 0 — ihre Reichweite steht an der Wirkung.
  final double castRange;

  /// Die Farbe ihrer Fläche.
  final PitTint tint;

  /// Wie weit sie reicht: die Wurfweite eines Bereichs, sonst die
  /// grösste Reichweite ihrer Geschosse und Schläge.
  double get reach {
    if (aim == PitAim.bereich) return castRange;
    var weiteste = 0.0;
    for (final effect in effects) {
      final weite = switch (effect) {
        BoltAtNearest(:final range) => range,
        StrikeNearest(:final range) => range,
        _ => 0.0,
      };
      if (weite > weiteste) weiteste = weite;
    }
    return weiteste;
  }

  /// Der grösste Umkreis ihrer Flächen-Wirkungen, 0 wenn sie keine hat.
  double get areaRadius {
    var groesste = 0.0;
    for (final effect in effects) {
      final r = switch (effect) {
        StrikeAround(:final radius) => radius,
        SlowAround(:final radius) => radius,
        DamageOverTime(:final radius) => radius,
        _ => 0.0,
      };
      if (r > groesste) groesste = r;
    }
    return groesste;
  }
}

/// Die Fähigkeiten, die in der Grube wirken.
///
/// Hier wird geschrieben wie in `room_catalog.dart`: Alle Zahlen einer
/// Fähigkeit stehen an ihrem Eintrag. Wer eine ändert, lässt
/// `dart run tool/pit_sim.dart` laufen.
///
/// **Mana wächst mit der Seltenheit**, und keine kostet mehr als ein
/// frischer Charakter hat (40): Eine Fähigkeit, die man auf Tag 0 nicht
/// einmal wirken kann, wäre ein toter Knopf. Ein Test hält das fest.
abstract final class PitAbilities {
  // --- Gewöhnlich ---

  /// **Schaden auf Entfernung.** Die erste Fähigkeit, die man bekommt
  /// (Knoten „Bewegung" unter Körper) — und die erste, die nicht voraus-
  /// setzt, dass man mitten in der Traube steht.
  static const PitAbility funkenstoss = PitAbility(
    id: 'funkenstoss',
    name: 'Funkenstoß',
    kind: PitKind.angriff,
    manaCost: 12,
    cooldown: 1.5,
    effects: <PitEffect>[BoltAtNearest(power: 1.2, range: 260)],
    description: 'Ein Funke fliegt geradeaus.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.funke,
  );

  /// **Ein Wert ändert sich.** Die Antwort auf die Traube, wenn man sich
  /// nicht mehr herauslaufen kann.
  static const PitAbility steinhaut = PitAbility(
    id: 'steinhaut',
    name: 'Steinhaut',
    kind: PitKind.schutz,
    manaCost: 20,
    cooldown: 12,
    effects: <PitEffect>[ReduceIncoming(factor: 0.6, seconds: 5)],
    description: 'Fünf Sekunden lang 40 % weniger Schaden.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.schutz,
  );

  /// Hält die Traube fest, statt sie zu töten.
  static const PitAbility wurzelgriff = PitAbility(
    id: 'wurzelgriff',
    name: 'Wurzelgriff',
    kind: PitKind.angriff,
    manaCost: 15,
    cooldown: 8,
    effects: <PitEffect>[
      StrikeAround(power: 0.6, radius: 90),
      SlowAround(radius: 90, factor: 0.35, seconds: 4),
    ],
    description: 'Wurzeln brechen, wo man sie hinsetzt, aus dem Boden und '
        'halten vier Sekunden lang fest.',
    aim: PitAim.bereich,
    castRange: 220,
    tint: PitTint.natur,
  );

  /// Kostet nichts, bringt Mana — der Zug, der die anderen bezahlt.
  static const PitAbility aurastrom = PitAbility(
    id: 'aurastrom',
    name: 'Aurastrom',
    kind: PitKind.schutz,
    manaCost: 0,
    cooldown: 15,
    effects: <PitEffect>[GainMana(amount: 30)],
    description: 'Bringt 30 Mana zurück.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.schutz,
  );

  // --- Ungewöhnlich ---

  /// **Heilung.** Macht aus den Heilkugeln eine Entscheidung statt der
  /// einzigen Quelle.
  static const PitAbility bluetentau = PitAbility(
    id: 'bluetentau',
    name: 'Blütentau',
    kind: PitKind.schutz,
    manaCost: 30,
    cooldown: 14,
    effects: <PitEffect>[HealSelf(share: 0.25)],
    description: 'Heilt ein Viertel der vollen Gesundheit.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.schutz,
  );

  /// Ein Schlag rundum — häufiger zu haben als Sternenfall, und
  /// der Grund, in die Traube hineinzulaufen.
  static const PitAbility klingenwirbel = PitAbility(
    id: 'klingenwirbel',
    name: 'Klingenwirbel',
    kind: PitKind.angriff,
    manaCost: 18,
    cooldown: 4,
    effects: <PitEffect>[StrikeAround(power: 2.0, radius: 70)],
    description: 'Klingen treffen alles im Umkreis doppelt hart.',
    aim: PitAim.umDenHelden,
    castRange: 0,
    tint: PitTint.klinge,
  );

  /// Das Eisfeld: langsamer und blutend.
  static const PitAbility frostnebel = PitAbility(
    id: 'frostnebel',
    name: 'Frostnebel',
    kind: PitKind.umgebung,
    manaCost: 25,
    cooldown: 14,
    effects: <PitEffect>[
      SlowAround(radius: 160, factor: 0.5, seconds: 5),
      DamageOverTime(radius: 160, perSecond: 0.15, seconds: 5),
    ],
    description: 'Ein Eisfeld: Wer hineinläuft, wird langsam und friert.',
    aim: PitAim.bereich,
    castRange: 260,
    tint: PitTint.eis,
  );

  /// Wer zuschlägt, trifft sich selbst.
  static const PitAbility prismaBarriere = PitAbility(
    id: 'prisma_barriere',
    name: 'Prisma-Barriere',
    kind: PitKind.schutz,
    manaCost: 20,
    cooldown: 14,
    effects: <PitEffect>[ReflectIncoming(share: 0.5, seconds: 6)],
    description: 'Sechs Sekunden lang trifft jeder Nahkampfschlag zur Hälfte '
        'seinen Schläger.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.schutz,
  );

  // --- Selten ---

  /// Der härteste Einzeltreffer auf Entfernung.
  static const PitAbility donnerkeil = PitAbility(
    id: 'donnerkeil',
    name: 'Donnerkeil',
    kind: PitKind.angriff,
    manaCost: 25,
    cooldown: 6,
    effects: <PitEffect>[BoltAtNearest(power: 3.0, range: 300)],
    description: 'Ein Blitz geradeaus, dreifache Wucht.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.blitz,
  );

  /// Der Sturm: weiter und länger als der Frost, aber schwächer im Biss.
  static const PitAbility sandsturm = PitAbility(
    id: 'sandsturm',
    name: 'Sandsturm',
    kind: PitKind.umgebung,
    manaCost: 30,
    cooldown: 16,
    effects: <PitEffect>[
      SlowAround(radius: 220, factor: 0.6, seconds: 7),
      DamageOverTime(radius: 220, perSecond: 0.2, seconds: 7),
    ],
    description: 'Ein Sturmfeld, sieben Sekunden lang: Wer darin steht, wird '
        'gebremst und geschliffen.',
    aim: PitAim.bereich,
    castRange: 260,
    tint: PitTint.sand,
  );

  /// Schaden, der heilt — in voller Höhe, wie im Rundenkampf.
  static const PitAbility seelenraub = PitAbility(
    id: 'seelenraub',
    name: 'Seelenraub',
    kind: PitKind.angriff,
    manaCost: 22,
    cooldown: 6,
    effects: <PitEffect>[
      BoltAtNearest(power: 1.8, range: 240, leech: 1),
    ],
    description: 'Ein Geschoss, das so viel heilt, wie es anrichtet.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.seele,
  );

  /// Der Giftboden: kein Treffer, aber der stärkste Dauerschaden.
  static const PitAbility giftmoor = PitAbility(
    id: 'giftmoor',
    name: 'Giftmoor',
    kind: PitKind.umgebung,
    manaCost: 28,
    cooldown: 14,
    effects: <PitEffect>[
      DamageOverTime(radius: 180, perSecond: 0.5, seconds: 6),
    ],
    description: 'Ein Giftboden, sechs Sekunden lang: Er frisst an allem, '
        'was darin steht.',
    aim: PitAim.bereich,
    castRange: 240,
    tint: PitTint.gift,
  );

  /// Die Zeit dehnt sich, wo man sie hinsetzt. Bis zum 22.09. traf sie
  /// alles in 600 Punkten Umkreis — als abgesetzte Fläche wäre das der
  /// ganze Bildschirm und nichts mehr zu zielen.
  static const PitAbility zeitdehnung = PitAbility(
    id: 'zeitdehnung',
    name: 'Zeitdehnung',
    kind: PitKind.schutz,
    manaCost: 35,
    cooldown: 20,
    effects: <PitEffect>[SlowAround(radius: 170, factor: 0.4, seconds: 5)],
    description: 'Fünf Sekunden lang bewegt sich jeder Gegner im Feld mit '
        'weniger als halber Geschwindigkeit.',
    aim: PitAim.bereich,
    castRange: 260,
    tint: PitTint.zeit,
  );

  /// Ein Ausbruch mit Nachglühen.
  static const PitAbility vulkanbruch = PitAbility(
    id: 'vulkanbruch',
    name: 'Vulkanbruch',
    kind: PitKind.umgebung,
    manaCost: 38,
    cooldown: 14,
    effects: <PitEffect>[
      StrikeAround(power: 2.5, radius: 110),
      DamageOverTime(radius: 110, perSecond: 0.4, seconds: 4),
    ],
    description: 'Lava bricht aus, wo man sie hinsetzt, und brennt nach.',
    aim: PitAim.bereich,
    castRange: 220,
    tint: PitTint.lava,
  );

  // --- Legendär ---

  /// Die einzige legendäre, nur über sechzig Tage Kette.
  static const PitAbility sternenfall = PitAbility(
    id: 'sternenfall',
    name: 'Sternenfall',
    kind: PitKind.angriff,
    manaCost: 40,
    cooldown: 20,
    effects: <PitEffect>[StrikeAround(power: 4.0, radius: 220)],
    description: 'Sterne fallen, wo man sie hinsetzt — vierfache Wucht.',
    aim: PitAim.bereich,
    castRange: 260,
    tint: PitTint.stern,
  );

  // --- Aus Errungenschaften (ADR-0033) ---

  static const PitAbility kraftschlag = PitAbility(
    id: 'heavy_attack',
    name: 'Kraftschlag',
    kind: PitKind.angriff,
    manaCost: 18,
    cooldown: 4,
    effects: <PitEffect>[StrikeNearest(power: 3.2, range: 50)],
    description: 'Ein einzelner Schlag mit dreifacher Wucht.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.klinge,
  );

  static const PitAbility zehrung = PitAbility(
    id: 'poison_strike',
    name: 'Zehrung',
    kind: PitKind.angriff,
    manaCost: 12,
    cooldown: 5,
    effects: <PitEffect>[
      StrikeNearest(power: 0.8, range: 50),
      DamageOverTime(radius: 60, perSecond: 0.4, seconds: 5),
    ],
    description: 'Ein vergifteter Schlag, das Gift frisst fünf Sekunden '
        'lang weiter.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.gift,
  );

  static const PitAbility sammeln = PitAbility(
    id: 'mend',
    name: 'Sammeln',
    kind: PitKind.schutz,
    manaCost: 25,
    cooldown: 14,
    effects: <PitEffect>[
      HealSelf(share: 0.15),
      ReduceIncoming(factor: 0.7, seconds: 4),
    ],
    description: 'Heilt ein wenig und schützt vier Sekunden lang.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.schutz,
  );

  static const PitAbility atemzug = PitAbility(
    id: 'breath',
    name: 'Atemzug',
    kind: PitKind.schutz,
    manaCost: 0,
    cooldown: 12,
    effects: <PitEffect>[GainMana(amount: 20), HealSelf(share: 0.08)],
    description: 'Bringt 20 Mana zurück und heilt ein wenig.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.schutz,
  );

  static const List<PitAbility> all = <PitAbility>[
    funkenstoss,
    steinhaut,
    wurzelgriff,
    aurastrom,
    bluetentau,
    klingenwirbel,
    frostnebel,
    prismaBarriere,
    donnerkeil,
    sandsturm,
    seelenraub,
    giftmoor,
    zeitdehnung,
    vulkanbruch,
    sternenfall,
    kraftschlag,
    zehrung,
    sammeln,
    atemzug,
  ];

  /// `null` für eine Id, die in der Grube nichts tut.
  static PitAbility? byId(String id) {
    for (final ability in all) {
      if (ability.id == id) return ability;
    }
    return null;
  }
}

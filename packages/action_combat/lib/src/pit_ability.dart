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

/// Was eine Fähigkeit bewirkt. Neue Arten kommen hier dazu, und der
/// Analyzer zeigt danach auf die eine Stelle in der Welt, die sie
/// ausführen muss — dafür ist die Klasse `sealed`.
sealed class PitEffect {
  const PitEffect();
}

/// Ein Geschoss auf den nächsten **sichtbaren** Gegner in [range].
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

/// Ein Schlag auf den nächsten Gegner in Nahkampfreichweite [range].
final class StrikeNearest extends PitEffect {
  const StrikeNearest({required this.power, required this.range});

  final double power;
  final double range;
}

/// Trifft alles im Umkreis [radius] um den Helden.
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

/// Eine Fähigkeit, wie die Grube sie kennt.
class PitAbility {
  const PitAbility({
    required this.id,
    required this.name,
    required this.manaCost,
    required this.cooldown,
    required this.effects,
    required this.description,
  });

  /// Dieselbe Id wie in `package:combat` und `package:abilities`.
  final String id;
  final String name;

  /// 0 bei den Fähigkeiten, die Mana **bringen** statt es zu kosten.
  final int manaCost;

  /// Sekunden bis zum nächsten Einsatz.
  final double cooldown;

  final List<PitEffect> effects;

  /// Was sie tut, in einem Satz — für das Blatt, das sie erklärt.
  final String description;
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
    manaCost: 12,
    cooldown: 1.5,
    effects: <PitEffect>[BoltAtNearest(power: 1.2, range: 260)],
    description: 'Ein Funke fliegt auf den nächsten Gegner.',
  );

  /// **Ein Wert ändert sich.** Die Antwort auf die Traube, wenn der
  /// Sturmschritt gerade abklingt.
  static const PitAbility steinhaut = PitAbility(
    id: 'steinhaut',
    name: 'Steinhaut',
    manaCost: 20,
    cooldown: 12,
    effects: <PitEffect>[ReduceIncoming(factor: 0.6, seconds: 5)],
    description: 'Fünf Sekunden lang 40 % weniger Schaden.',
  );

  /// Hält die Traube fest, statt sie zu töten.
  static const PitAbility wurzelgriff = PitAbility(
    id: 'wurzelgriff',
    name: 'Wurzelgriff',
    manaCost: 15,
    cooldown: 8,
    effects: <PitEffect>[
      StrikeAround(power: 0.6, radius: 90),
      SlowAround(radius: 90, factor: 0.35, seconds: 4),
    ],
    description: 'Wurzeln treffen alles in der Nähe und halten es vier '
        'Sekunden lang fest.',
  );

  /// Kostet nichts, bringt Mana — der Zug, der die anderen bezahlt.
  static const PitAbility aurastrom = PitAbility(
    id: 'aurastrom',
    name: 'Aurastrom',
    manaCost: 0,
    cooldown: 15,
    effects: <PitEffect>[GainMana(amount: 30)],
    description: 'Bringt 30 Mana zurück.',
  );

  // --- Ungewöhnlich ---

  /// **Heilung.** Macht aus den Heilkugeln eine Entscheidung statt der
  /// einzigen Quelle.
  static const PitAbility bluetentau = PitAbility(
    id: 'bluetentau',
    name: 'Blütentau',
    manaCost: 30,
    cooldown: 14,
    effects: <PitEffect>[HealSelf(share: 0.25)],
    description: 'Heilt ein Viertel der vollen Gesundheit.',
  );

  /// Der Rundumschlag in gross — häufiger zu haben als Sternenfall, und
  /// der Grund, in die Traube hineinzulaufen.
  static const PitAbility klingenwirbel = PitAbility(
    id: 'klingenwirbel',
    name: 'Klingenwirbel',
    manaCost: 18,
    cooldown: 4,
    effects: <PitEffect>[StrikeAround(power: 2.0, radius: 70)],
    description: 'Klingen treffen alles im Umkreis doppelt hart.',
  );

  /// Das Eisfeld: langsamer und blutend.
  static const PitAbility frostnebel = PitAbility(
    id: 'frostnebel',
    name: 'Frostnebel',
    manaCost: 25,
    cooldown: 14,
    effects: <PitEffect>[
      SlowAround(radius: 160, factor: 0.5, seconds: 5),
      DamageOverTime(radius: 160, perSecond: 0.15, seconds: 5),
    ],
    description: 'Nebel verlangsamt alles in weitem Umkreis und lässt es '
        'frieren.',
  );

  /// Wer zuschlägt, trifft sich selbst.
  static const PitAbility prismaBarriere = PitAbility(
    id: 'prisma_barriere',
    name: 'Prisma-Barriere',
    manaCost: 20,
    cooldown: 14,
    effects: <PitEffect>[ReflectIncoming(share: 0.5, seconds: 6)],
    description: 'Sechs Sekunden lang trifft jeder Nahkampfschlag zur Hälfte '
        'seinen Schläger.',
  );

  // --- Selten ---

  /// Der härteste Einzeltreffer auf Entfernung.
  static const PitAbility donnerkeil = PitAbility(
    id: 'donnerkeil',
    name: 'Donnerkeil',
    manaCost: 25,
    cooldown: 6,
    effects: <PitEffect>[BoltAtNearest(power: 3.0, range: 300)],
    description: 'Ein Blitz auf den nächsten Gegner, dreifache Wucht.',
  );

  /// Der Sturm: weiter und länger als der Frost, aber schwächer im Biss.
  static const PitAbility sandsturm = PitAbility(
    id: 'sandsturm',
    name: 'Sandsturm',
    manaCost: 30,
    cooldown: 16,
    effects: <PitEffect>[
      SlowAround(radius: 220, factor: 0.6, seconds: 7),
      DamageOverTime(radius: 220, perSecond: 0.2, seconds: 7),
    ],
    description: 'Sand bremst und schleift alles in weitem Umkreis, sieben '
        'Sekunden lang.',
  );

  /// Schaden, der heilt — in voller Höhe, wie im Rundenkampf.
  static const PitAbility seelenraub = PitAbility(
    id: 'seelenraub',
    name: 'Seelenraub',
    manaCost: 22,
    cooldown: 6,
    effects: <PitEffect>[
      BoltAtNearest(power: 1.8, range: 240, leech: 1),
    ],
    description: 'Ein Geschoss, das so viel heilt, wie es anrichtet.',
  );

  /// Der Giftboden: kein Treffer, aber der stärkste Dauerschaden.
  static const PitAbility giftmoor = PitAbility(
    id: 'giftmoor',
    name: 'Giftmoor',
    manaCost: 28,
    cooldown: 14,
    effects: <PitEffect>[
      DamageOverTime(radius: 180, perSecond: 0.5, seconds: 6),
    ],
    description: 'Gift frisst sechs Sekunden lang an allem in der Nähe.',
  );

  /// Alles in der Halle wird langsam.
  static const PitAbility zeitdehnung = PitAbility(
    id: 'zeitdehnung',
    name: 'Zeitdehnung',
    manaCost: 35,
    cooldown: 20,
    effects: <PitEffect>[SlowAround(radius: 600, factor: 0.4, seconds: 5)],
    description: 'Fünf Sekunden lang bewegt sich jeder Gegner in Sichtweite '
        'mit weniger als halber Geschwindigkeit.',
  );

  /// Ein Ausbruch mit Nachglühen.
  static const PitAbility vulkanbruch = PitAbility(
    id: 'vulkanbruch',
    name: 'Vulkanbruch',
    manaCost: 38,
    cooldown: 14,
    effects: <PitEffect>[
      StrikeAround(power: 2.5, radius: 110),
      DamageOverTime(radius: 110, perSecond: 0.4, seconds: 4),
    ],
    description: 'Lava bricht um den Helden aus und brennt nach.',
  );

  // --- Legendär ---

  /// Die einzige legendäre, nur über sechzig Tage Kette.
  static const PitAbility sternenfall = PitAbility(
    id: 'sternenfall',
    name: 'Sternenfall',
    manaCost: 40,
    cooldown: 20,
    effects: <PitEffect>[StrikeAround(power: 4.0, radius: 220)],
    description: 'Sterne fallen auf alles in weitem Umkreis, vierfache Wucht.',
  );

  // --- Aus Errungenschaften (ADR-0033) ---

  static const PitAbility kraftschlag = PitAbility(
    id: 'heavy_attack',
    name: 'Kraftschlag',
    manaCost: 18,
    cooldown: 4,
    effects: <PitEffect>[StrikeNearest(power: 3.2, range: 50)],
    description: 'Ein einzelner Schlag mit dreifacher Wucht.',
  );

  static const PitAbility zehrung = PitAbility(
    id: 'poison_strike',
    name: 'Zehrung',
    manaCost: 12,
    cooldown: 5,
    effects: <PitEffect>[
      StrikeNearest(power: 0.8, range: 50),
      DamageOverTime(radius: 60, perSecond: 0.4, seconds: 5),
    ],
    description: 'Ein vergifteter Schlag, das Gift frisst fünf Sekunden '
        'lang weiter.',
  );

  static const PitAbility sammeln = PitAbility(
    id: 'mend',
    name: 'Sammeln',
    manaCost: 25,
    cooldown: 14,
    effects: <PitEffect>[
      HealSelf(share: 0.15),
      ReduceIncoming(factor: 0.7, seconds: 4),
    ],
    description: 'Heilt ein wenig und schützt vier Sekunden lang.',
  );

  static const PitAbility atemzug = PitAbility(
    id: 'breath',
    name: 'Atemzug',
    manaCost: 0,
    cooldown: 12,
    effects: <PitEffect>[GainMana(amount: 20), HealSelf(share: 0.08)],
    description: 'Bringt 20 Mana zurück und heilt ein wenig.',
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

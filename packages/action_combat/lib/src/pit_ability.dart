/// Die Fähigkeiten der Grube — Mana, Abklingzeit, Wirkung (ADR-0039).
///
/// **Die Ids sind dieselben wie im Rundenkampf.** Freigeschaltet wird
/// weiterhin über `package:abilities` (Baum, Streak-Marken,
/// Errungenschaften); hier steht nur, was eine Fähigkeit in Echtzeit
/// **tut**. Eine Id ohne Eintrag hier liegt auf ihrem Platz und tut in der
/// Grube noch nichts — so werden die fünfzehn nach und nach umgebaut, wie
/// Issue #65 es verlangt.
///
/// **Eine Wirkung ist ein Datum, kein Code.** Eine Fähigkeit ist eine
/// Liste von [PitEffect]s, und die Welt kennt jede Art genau einmal. Das
/// ist die Naht für Sets und Legendäre: Sie verändern eine Liste (mehr
/// Schaden, zweites Geschoss, zusätzlich heilen), statt Sonderfälle in
/// die Welt zu schreiben.
library;

/// Was eine Fähigkeit bewirkt. Neue Arten kommen hier dazu, und der
/// Analyzer zeigt danach auf die eine Stelle in der Welt, die sie
/// ausführen muss — dafür ist die Klasse `sealed`.
sealed class PitEffect {
  const PitEffect();
}

/// Ein Geschoss auf den nächsten Gegner in [range].
///
/// Der Schaden fällt beim Einschlag und rechnet wie ein Schlag des
/// Helden: `Angriff × power`, minus Verteidigung, mit Streuung und
/// kritischen Treffern. Damit hängt die Fähigkeit am Angriffswert und
/// über ihn an den Gewohnheiten — dieselbe Regel wie im Rundenkampf
/// (ADR-0022).
final class BoltAtNearest extends PitEffect {
  const BoltAtNearest({required this.power, required this.range});

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
  final int manaCost;

  /// Sekunden bis zum nächsten Einsatz.
  final double cooldown;

  final List<PitEffect> effects;

  /// Was sie tut, in einem Satz — für das Blatt, das sie erklärt.
  final String description;
}

/// Die Fähigkeiten, die in der Grube schon wirken.
///
/// Hier wird geschrieben wie in `room_catalog.dart`: Alle Zahlen einer
/// Fähigkeit stehen an ihrem Eintrag. Wer eine ändert, lässt
/// `dart run tool/pit_sim.dart` laufen.
abstract final class PitAbilities {
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

  static const List<PitAbility> all = <PitAbility>[
    funkenstoss,
    steinhaut,
    bluetentau,
  ];

  /// `null` für eine Id, die in der Grube noch nichts tut.
  static PitAbility? byId(String id) {
    for (final ability in all) {
      if (ability.id == id) return ability;
    }
    return null;
  }
}

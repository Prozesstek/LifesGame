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

import 'balance.dart';
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

// --- Seit ADR-0073: die neuen Arten ---
//
// Jede steht hier als Datum und in `effects.dart` als die eine Stelle,
// die sie ausführt. Was „ein Feld“ ist, steht in
// `ActionBalance.tileSize` (32); die Zahlen unten sind Punkte.

/// Der Held stürmt [distance] weit in die gezielte Richtung — in
/// [ActionBalance.dashSeconds], durch Gegner hindurch, nicht durch
/// Wände. **Der Aufprall schadet nicht**, und Schutz gibt es dabei keinen.
///
/// Mit [trailPerSecond] über null zieht er eine Spur hinter sich her: eine
/// Kette kleiner Flächen mit Umkreis [trailRadius], die [trailSeconds]
/// liegen und brennen — `Angriff × trailPerSecond` je Sekunde, wie jeder
/// Dauerschaden.
///
/// Mit [impactPower] über null **rammt** er (Rammbock): Wen er auf dem Weg
/// streift, der nimmt `Angriff × impactPower`, fliegt [impactFling] weit
/// zur Seite und steht [impactStun] still — jeder höchstens einmal je
/// Sturm. Der Wächter wird nicht geschleudert; sein Stillstand geht über
/// die Leiste.
final class Dash extends PitEffect {
  const Dash({
    required this.distance,
    this.trailPerSecond = 0,
    this.trailSeconds = 0,
    this.trailRadius = 0,
    this.impactPower = 0,
    this.impactFling = 0,
    this.impactStun = 0,
  });

  final double distance;
  final double trailPerSecond;
  final double trailSeconds;
  final double trailRadius;
  final double impactPower;
  final double impactFling;
  final double impactStun;
}

/// Ein Haken: zieht **einen** Gegner bis [range] heran, vor die Füsse des
/// Helden — den in der gezielten Richtung, beim kurzen Tippen den
/// nächsten, den er sieht.
///
/// Dazu ein Schlag mit `Angriff × power` und [stunSeconds] Stillstand.
/// **Der Wächter wird nie gezogen**; trifft der Haken ihn, nimmt er den
/// Schlag, und der Stillstand füllt eine Kerbe seiner Stun-Leiste.
/// Durch Wände zieht er nichts: ohne freie Sicht kein Wurf und kein Mana.
final class HookNearest extends PitEffect {
  const HookNearest({
    required this.range,
    required this.power,
    required this.stunSeconds,
  });

  final double range;
  final double power;
  final double stunSeconds;
}

/// Zieht alle Gegner im Umkreis [radius] zur Mitte, die sie sehen — der
/// Strudel. Mit [stunSeconds] stehen sie danach still. Der Wächter wird
/// nicht gezogen; sein Stillstand geht über die Leiste.
final class PullToCenter extends PitEffect {
  const PullToCenter({required this.radius, required this.stunSeconds});

  final double radius;
  final double stunSeconds;
}

/// Ein Wert des Helden steigt um einen Faktor, [seconds] lang.
///
/// [attack] wirkt auf **allen** Schaden, auch den Grundangriff
/// (ADR-0073: dort nur leicht — 1,25 ist die Obergrenze, die ein Test
/// hält). [haste] verkürzt die Zeit zwischen zwei Schlägen, [moveSpeed]
/// beschleunigt das Laufen. 1 heisst: unverändert.
///
/// Bei zweien desselben Werts gilt der stärkere, die Dauer beginnt neu —
/// dieselbe Regel wie bei der Schadensminderung.
final class SelfBuff extends PitEffect {
  const SelfBuff({
    required this.seconds,
    this.attack = 1,
    this.haste = 1,
    this.moveSpeed = 1,
  });

  final double seconds;
  final double attack;
  final double haste;
  final double moveSpeed;
}

/// Ein Ausgang eines Zufalls: [weight] von der Summe aller Gewichte,
/// und was dann geschieht.
final class PitOutcome {
  const PitOutcome({required this.weight, required this.effects});

  final int weight;
  final List<PitEffect> effects;
}

/// **Zufall**: Einer der [outcomes] wird gewürfelt — mit dem Würfel des
/// Laufs, damit die Tagesgrube für alle gleich bleibt (ADR-0073).
final class RandomOf extends PitEffect {
  const RandomOf({required this.outcomes});

  final List<PitOutcome> outcomes;
}

/// Ein **Bumerang**: fliegt [range] weit, durch Gegner hindurch, und
/// kehrt zum Helden zurück. Hin und zurück trifft er jeden höchstens
/// einmal, je `Angriff × power`. An einer Wand kehrt er um; steht auf dem
/// Rückweg eine Wand zwischen ihm und dem Helden, erlischt er.
final class Boomerang extends PitEffect {
  const Boomerang({required this.power, required this.range});

  final double power;
  final double range;
}

/// Eine **Falle** am abgesetzten Punkt: Der erste Gegner, der hineintritt,
/// nimmt `Angriff × power` und steht [stunSeconds] still. Sie liegt
/// [seconds] lang; höchstens [ActionBalance.maxTraps] zugleich, eine
/// weitere lässt die älteste verschwinden. Gegner sehen sie nicht.
final class Trap extends PitEffect {
  const Trap({
    required this.power,
    required this.stunSeconds,
    required this.seconds,
  });

  final double power;
  final double stunSeconds;
  final double seconds;
}

/// Ein **Begleiter**: kämpft [seconds] lang für den Helden und greift alle
/// [interval] Sekunden an, was der Held sieht, mit `Angriff × power`.
///
/// **Höchstens einer zugleich** — ein neuer verdrängt den alten. Er wird
/// nicht angegriffen. Seine Kills zahlen Beute, laden die Ultimate aber
/// nicht (ADR-0073).
///
/// Mit [stationary] bleibt er, wo er abgesetzt wurde, und greift nur in
/// [reach] an; sonst fliegt er mit dem Helden. [devourBelow] über null
/// heisst: Ein Gegner unter diesem Anteil seines Lebens wird **gefressen**
/// — nie der Wächter.
///
/// Mit [mirror] ist er ein **Abbild des Helden** (Spiegelbild): Es
/// erscheint neben ihm, **bleibt stehen, wo es gerufen wurde**, und
/// schlägt von dort mit dessen Grundangriff — Reichweite und Takt der
/// Waffe, Wucht `Waffe × power`. [interval] und [reach] gelten dann
/// nicht.
final class Companion extends PitEffect {
  const Companion({
    required this.power,
    required this.interval,
    required this.seconds,
    required this.reach,
    this.stationary = false,
    this.devourBelow = 0,
    this.mirror = false,
  });

  final double power;
  final double interval;
  final double seconds;
  final double reach;
  final bool stationary;
  final double devourBelow;
  final bool mirror;
}

/// **Terrain**: Ein Fels von einem Feld fällt auf den abgesetzten Punkt
/// und liegt [seconds] lang. Er ist Wand — auch für Pfeile.
///
/// Nie ins Tor oder daneben, nie auf den einzigen Weg; wer darunter steht,
/// wird an den Rand geschoben. Geht das nicht, fällt kein Fels — der Rest
/// der Fähigkeit wirkt trotzdem.
final class Rock extends PitEffect {
  const Rock({required this.seconds});

  final double seconds;
}

/// Ein Schlag gegen **alle** im Kegel vor dem Helden bis [range], je
/// `Angriff × power`, und sie fliegen [fling] weit zur Seite — quer zur
/// Schlagrichtung, nach rechts. Eine Wand hält auf; der Wächter und, was
/// festgewachsen ist, bleiben stehen.
final class SweepCone extends PitEffect {
  const SweepCone({
    required this.power,
    required this.range,
    required this.fling,
  });

  final double power;
  final double range;
  final double fling;
}

/// Ein Geschoss, das **einfriert**: Es trifft wie [BoltAtNearest] und
/// lässt den Getroffenen [stunSeconds] erstarren. **Zerspringen**: Der
/// nächste Treffer des Helden auf einen Gefrorenen — gleich woher, auch
/// vom Grundangriff — ist sicher kritisch und taut ihn auf.
final class FreezeBolt extends PitEffect {
  const FreezeBolt({
    required this.power,
    required this.range,
    required this.stunSeconds,
  });

  final double power;
  final double range;
  final double stunSeconds;
}

// --- AktivesBretts zehn (ADR-0074) ---

/// **Blink**: Der Held ist sofort bis [distance] weiter — in die gezielte
/// Richtung, beim kurzen Tippen auf den nächsten Gegner zu, den er sieht.
///
/// **Nie durch eine Wand oder das Tor** (ADR-0073): Er landet vor dem
/// ersten Hindernis. Sonst überspränge er Räume und den Auftritt des
/// Wächters.
final class Blink extends PitEffect {
  const Blink({required this.distance});

  final double distance;
}

/// **Unsichtbarkeit**: [seconds] lang sehen die Gegner den Helden nicht —
/// sie bemerken ihn nicht und greifen nicht an. Der Wächter sieht ihn
/// trotzdem: Er ist allein in seinem Raum, da gibt es nichts zu
/// umgehen.
///
/// **Sie endet mit dem ersten eigenen Treffer**, und der trifft
/// [ambush]-mal so hart — auch der Grundangriff, der von selbst fällt.
final class Vanish extends PitEffect {
  const Vanish({required this.seconds, this.ambush = 1});

  final double seconds;
  final double ambush;
}

/// **Stun im Umkreis** [radius] um den Helden: Alle stehen [seconds]
/// still. Beim Wächter über die Stun-Leiste (ADR-0073).
final class StunAround extends PitEffect {
  const StunAround({required this.radius, required this.seconds});

  final double radius;
  final double seconds;
}

/// **Parade**: [seconds] lang wird der nächste Treffer ganz abgefangen,
/// und wer ihn führte, steht [stunSeconds] still. Danach ist sie
/// verbraucht; kommt in der Zeit nichts, war sie umsonst.
///
/// Auch ein Pfeil wird pariert — dann steht der Schütze still. Gegen eine
/// Fläche hilft sie nicht, die hat niemanden, der zuschlägt.
final class Parry extends PitEffect {
  const Parry({required this.seconds, required this.stunSeconds});

  final double seconds;
  final double stunSeconds;
}

/// **Stacking**: Jedes Wirken dieser Fähigkeit binnen [window] Sekunden
/// nach dem letzten trifft um [step] härter, höchstens [maxStacks]-mal.
/// Gezählt wird das Wirken, nicht der Schaden (ADR-0073).
///
/// Steht als Erstes in der Liste und wirkt auf die Treffer der übrigen
/// Wirkungen desselben Wirkens.
final class Stacking extends PitEffect {
  const Stacking({
    required this.step,
    required this.window,
    required this.maxStacks,
  });

  final double step;
  final double window;
  final int maxStacks;
}

/// **Kettenblitz**: ein Geschoss wie [BoltAtNearest], das nach dem
/// Einschlag auf den nächsten Gegner springt — höchstens [jumps]-mal, je
/// bis [jumpRange] weit, jeder Sprung mit [falloff] der Wucht davor.
/// **Nur auf Gegner, die vom Einschlag aus zu sehen sind**, und keinen
/// zweimal.
final class ChainBolt extends PitEffect {
  const ChainBolt({
    required this.power,
    required this.range,
    required this.jumps,
    required this.jumpRange,
    required this.falloff,
  });

  final double power;
  final double range;
  final int jumps;
  final double jumpRange;
  final double falloff;
}

/// **Bestform** (Ultimate): [seconds] lang treffen Fähigkeiten
/// [abilityPower]-mal so hart, der Grundangriff [attackPower]-mal, die
/// Fähigkeiten kosten kein Mana, und ihre Abklingzeiten laufen
/// [cooldownRate]-mal so schnell.
///
/// **Der Grundangriff bleibt unter der Grenze** (ADR-0009, ADR-0073):
/// höchstens [ActionBalance.weaponBuffCap], auch zusammen mit anderen
/// Stärkungen.
final class Overdrive extends PitEffect {
  const Overdrive({
    required this.seconds,
    required this.abilityPower,
    required this.attackPower,
    required this.cooldownRate,
  });

  final double seconds;
  final double abilityPower;
  final double attackPower;
  final double cooldownRate;
}

/// **Rückspulen** (Ultimate): Der Held steht wieder, wo er vor [seconds]
/// Sekunden stand, mit dem Leben von damals — nie mit weniger als jetzt —,
/// und ist danach [invulnerableSeconds] unverwundbar.
///
/// **Nie über ein Tor zurück**: Ist es seitdem zugefallen, oder steht an
/// der alten Stelle jetzt ein Fels, bleibt er stehen und bekommt nur das
/// Leben zurück.
final class Rewind extends PitEffect {
  const Rewind({required this.seconds, required this.invulnerableSeconds});

  final double seconds;
  final double invulnerableSeconds;
}

/// Eine Wirkung, die **dauernd** wirkt, solange ihre Fähigkeit auf einem
/// Platz liegt — ohne Knopf, ohne Mana, ohne Abklingzeit (ADR-0073:
/// Passiv). Sie kostet den Platz.
///
/// Eine Fähigkeit ist passiv, wenn alle ihre Wirkungen es sind
/// ([PitAbility.isPassive]).
sealed class PitPassive extends PitEffect {
  const PitPassive();
}

/// **Rage**: Jeder Treffer, den der Held einsteckt, macht ihn um [perHit]
/// stärker, höchstens [maxStacks]-mal. [decaySeconds] ohne Treffer, und
/// alles fällt ab. Gezählt, nicht am Schaden gemessen (ADR-0073).
///
/// Auf den Grundangriff wirkt sie nur bis [ActionBalance.weaponBuffCap].
final class RageOnHit extends PitPassive {
  const RageOnHit({
    required this.perHit,
    required this.maxStacks,
    required this.decaySeconds,
  });

  final double perHit;
  final int maxStacks;
  final double decaySeconds;
}

/// **Ruhepuls**: Hat der Held [idleSeconds] lang keinen Schaden
/// ausgeteilt, kommt Mana [factor]-mal so schnell zurück.
final class RestMana extends PitPassive {
  const RestMana({required this.factor, required this.idleSeconds});

  final double factor;
  final double idleSeconds;
}

/// **Zweiter Atem**: einmal je Lauf. Fällt das Leben unter [threshold],
/// heilt der Held [heal] der vollen Gesundheit und nimmt [wardSeconds]
/// lang nur [wardFactor] des Schadens.
final class LastStand extends PitPassive {
  const LastStand({
    required this.threshold,
    required this.heal,
    required this.wardFactor,
    required this.wardSeconds,
  });

  final double threshold;
  final double heal;
  final double wardFactor;
  final double wardSeconds;
}

// --- Kräfte der Ausrüstung (ADR-0077) ---
//
// Dieselbe Bauform wie die Passive auf den Plätzen: Sie gelten den
// ganzen Lauf. Ein Stück bringt sie über `GrantPassive` mit
// (`pit_modifier.dart`), ausgeführt werden sie in `gear_powers.dart`.

/// **Lebensraub**: [share] des Schadens, den der Held mit eigener Hand
/// anrichtet, heilt ihn. Mehrere Stücke zählen zusammen.
final class LifeSteal extends PitPassive {
  const LifeSteal({required this.share});

  final double share;
}

/// **Der Blutpakt** — das volle Vampirset: jede Sekunde [drainShare] des
/// vollen Lebens weg, **immer**, auch ohne Gegner. Der Lebensraub zählt
/// [stealFactor]-mal, und [stealDamageShare] dessen, was er heilen
/// könnte, trifft den Gegner zusätzlich — auch bei vollem Leben.
///
/// **Sonst heilt nichts**: Heilfähigkeiten, Heilkugeln und jede andere
/// Heilung treffen stattdessen den nächsten Gegner in Sicht mit genau
/// dem Betrag.
final class BloodPact extends PitPassive {
  const BloodPact({
    required this.drainShare,
    required this.stealFactor,
    required this.stealDamageShare,
  });

  final double drainShare;
  final double stealFactor;
  final double stealDamageShare;
}

/// Jeder Gegner, den der Held fällt, heilt ihn um [share] seines vollen
/// Lebens.
final class HealOnKill extends PitPassive {
  const HealOnKill({required this.share});

  final double share;
}

/// **Frostreif**: Ein Kreis aus Eis mit [radius] wandert mit dem Helden.
/// Wer darin steht, läuft mit [slowFactor] seines Tempos und nimmt je
/// Sekunde [perSecond] mal den Angriff. Der Wächter wird nur halb so
/// stark gebremst.
final class FrostAura extends PitPassive {
  const FrostAura({
    required this.radius,
    required this.slowFactor,
    required this.perSecond,
  });

  final double radius;
  final double slowFactor;
  final double perSecond;
}

/// **Irrlichter**: Alle [interval] Sekunden entsteht eines, höchstens
/// [maxCount] zugleich. Ohne Gegner kreisen sie um den Helden; sieht er
/// einen im Umkreis [seekRange], fliegt eins hin und zerplatzt bei der
/// Berührung — [power] mal Angriff auf alle im Umkreis [blastRadius].
final class Wisps extends PitPassive {
  const Wisps({
    required this.interval,
    required this.maxCount,
    required this.seekRange,
    required this.power,
    required this.blastRadius,
  });

  final double interval;
  final int maxCount;
  final double seekRange;
  final double power;
  final double blastRadius;
}

/// Nach jedem Kill läuft der Held [seconds] lang [speed]-mal so schnell.
final class KillRush extends PitPassive {
  const KillRush({required this.seconds, required this.speed});

  final double seconds;
  final double speed;
}

/// Jeder Kill bringt [amount] Mana.
final class ManaOnKill extends PitPassive {
  const ManaOnKill({required this.amount});

  final int amount;
}

/// [chance] mehr kritische Treffer, und jeder bringt [manaOnCrit] Mana.
final class CritEdge extends PitPassive {
  const CritEdge({required this.chance, required this.manaOnCrit});

  final double chance;
  final int manaOnCrit;
}

/// Hat der Held [idleSeconds] lang nichts eingesteckt, baut sich ein
/// Schild aus [share] seines vollen Lebens auf. Er fängt Schaden ab, bevor
/// das Leben ihn trägt.
final class IdleShield extends PitPassive {
  const IdleShield({required this.idleSeconds, required this.share});

  final double idleSeconds;
  final double share;
}

/// **Echo**: Jede [every]-te Fähigkeit, die Schaden macht, wirkt ein
/// zweites Mal — nur ihre Treffer, mit [power] der Wucht.
final class Echo extends PitPassive {
  const Echo({required this.every, required this.power});

  final int every;
  final double power;
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
    this.isUltimate = false,
  });

  /// Ob sie eine **Ultimate** ist (ADR-0073): kein Mana, keine
  /// Abklingzeit — sie lädt sich im Kampf auf und liegt nur auf ihrem
  /// eigenen Platz.
  final bool isUltimate;

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

  /// Ob sie **passiv** ist (ADR-0073): Sie liegt auf einem Platz und wirkt
  /// dauernd, hat aber keinen Knopf, kein Mana und keine Abklingzeit.
  bool get isPassive =>
      effects.isNotEmpty && effects.every((e) => e is PitPassive);

  /// Wie weit sie reicht: die Wurfweite eines Bereichs, sonst die
  /// grösste Reichweite ihrer Geschosse und Schläge.
  double get reach {
    if (aim == PitAim.bereich) return castRange;
    var weiteste = 0.0;
    for (final effect in effects) {
      final weite = switch (effect) {
        BoltAtNearest(:final range) => range,
        StrikeNearest(:final range) => range,
        FreezeBolt(:final range) => range,
        Boomerang(:final range) => range,
        HookNearest(:final range) => range,
        SweepCone(:final range) => range,
        Dash(:final distance) => distance,
        Blink(:final distance) => distance,
        ChainBolt(:final range) => range,
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
        PullToCenter(:final radius) => radius,
        Trap() => ActionBalance.trapRadius,
        Rock() => ActionBalance.tileSize / 2,
        Companion(:final reach, :final stationary) => stationary ? reach : 0.0,
        StunAround(:final radius) => radius,
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

  // --- Frederiks zehn (ADR-0073, `docs/vorlagen/faehigkeiten-2.md`) ---
  //
  // Ein Feld sind 32 Punkte; „etwa 4 Felder“ aus der Vorlage steht hier
  // als 128.

  /// Der Held stürmt los und zieht einen Feuerstreifen hinter sich her.
  /// Der Aufprall macht nichts, nur die Spur — wer hineinläuft, brennt.
  static const PitAbility glutspur = PitAbility(
    id: 'glutspur',
    name: 'Glutspur',
    kind: PitKind.umgebung,
    manaCost: 22,
    cooldown: 8,
    effects: <PitEffect>[
      Dash(
        distance: 128,
        trailPerSecond: 0.4,
        trailSeconds: 4,
        trailRadius: 16,
      ),
    ],
    description: 'Ein Sturm nach vorn, dahinter brennt der Boden vier '
        'Sekunden lang.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.lava,
  );

  /// Reisst einen Gegner aus der Gruppe vor die eigenen Füsse.
  ///
  /// In der Vorlage ein Blink zum Gegner und zurück; das Ende ist
  /// dasselbe wie ein Haken, und der Faden zeigt den Weg. Gebaut ist er
  /// deshalb als Haken, ohne eigenen Blink (ADR-0073: gebaut wird, was
  /// eine Fähigkeit braucht).
  static const PitAbility fanghaken = PitAbility(
    id: 'fanghaken',
    name: 'Fanghaken',
    kind: PitKind.angriff,
    manaCost: 18,
    cooldown: 10,
    effects: <PitEffect>[
      HookNearest(range: 160, power: 1.0, stunSeconds: 1),
    ],
    description: 'Ein Faden zieht einen Gegner heran, schlägt zu und hält '
        'ihn eine Sekunde fest.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.seele,
  );

  /// Ein Trank, der jedes Mal etwas anderes kann — aber nie nichts.
  ///
  /// **Kein Fehlwurf** (Vorlage): Einen Platz, der manchmal bestraft,
  /// nähme in einer knappen Grube niemand mit.
  static const PitAbility glueckstrank = PitAbility(
    id: 'glueckstrank',
    name: 'Glückstrank',
    kind: PitKind.schutz,
    manaCost: 15,
    cooldown: 12,
    effects: <PitEffect>[
      RandomOf(
        outcomes: <PitOutcome>[
          PitOutcome(
            weight: 19,
            effects: <PitEffect>[SelfBuff(seconds: 6, attack: 1.25)],
          ),
          PitOutcome(
            weight: 19,
            effects: <PitEffect>[SelfBuff(seconds: 6, haste: 1.25)],
          ),
          PitOutcome(
            weight: 19,
            effects: <PitEffect>[SelfBuff(seconds: 6, moveSpeed: 1.3)],
          ),
          PitOutcome(
            weight: 19,
            effects: <PitEffect>[ReduceIncoming(factor: 0.7, seconds: 6)],
          ),
          PitOutcome(
            weight: 19,
            effects: <PitEffect>[HealSelf(share: 0.15)],
          ),
          PitOutcome(
            weight: 5,
            effects: <PitEffect>[
              SelfBuff(
                seconds: 6,
                attack: 1.25,
                haste: 1.25,
                moveSpeed: 1.3,
              ),
              ReduceIncoming(factor: 0.7, seconds: 6),
              HealSelf(share: 0.15),
            ],
          ),
        ],
      ),
    ],
    description: 'Sechs Sekunden lang eins von fünf: stärker, schneller '
        'schlagen, schneller laufen, weniger Schaden — oder Heilung. '
        'Selten alles zugleich.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.stern,
  );

  /// Eine Kugel, die hinausfliegt und dem Helden zurück folgt.
  static const PitAbility wiederkehr = PitAbility(
    id: 'wiederkehr',
    name: 'Wiederkehr',
    kind: PitKind.angriff,
    manaCost: 16,
    cooldown: 5,
    effects: <PitEffect>[Boomerang(power: 1.0, range: 256)],
    description: 'Fliegt hinaus und kommt zurück — trifft auf beiden Wegen.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.zeit,
  );

  /// Eine eiserne Falle, die zuschnappt.
  static const PitAbility schnappfalle = PitAbility(
    id: 'schnappfalle',
    name: 'Schnappfalle',
    kind: PitKind.umgebung,
    manaCost: 14,
    cooldown: 6,
    effects: <PitEffect>[Trap(power: 1.5, stunSeconds: 2, seconds: 20)],
    description: 'Wer hineintritt, wird getroffen und steht zwei Sekunden '
        'still. Zwei liegen höchstens.',
    aim: PitAim.bereich,
    castRange: 160,
    tint: PitTint.klinge,
  );

  /// Ein Falke kreist über dem Helden und stösst herab.
  static const PitAbility falke = PitAbility(
    id: 'falke',
    name: 'Falke',
    kind: PitKind.angriff,
    manaCost: 25,
    cooldown: 20,
    effects: <PitEffect>[
      Companion(power: 0.5, interval: 0.8, seconds: 12, reach: 224),
    ],
    description: 'Zwölf Sekunden lang pickt ein Falke, was du siehst.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.natur,
  );

  /// Ein Fels stürzt herab und bleibt liegen — Deckung, die man sich
  /// selbst stellt.
  static const PitAbility steinschlag = PitAbility(
    id: 'steinschlag',
    name: 'Steinschlag',
    kind: PitKind.umgebung,
    manaCost: 26,
    cooldown: 10,
    effects: <PitEffect>[
      StrikeAround(power: 2.2, radius: 48),
      Rock(seconds: 8),
    ],
    description: 'Ein Fels trifft hart und bleibt acht Sekunden als Wand '
        'liegen.',
    aim: PitAim.bereich,
    castRange: 224,
    tint: PitTint.sand,
  );

  /// Eine Ranke peitscht von links nach rechts.
  static const PitAbility rankenpeitsche = PitAbility(
    id: 'rankenpeitsche',
    name: 'Rankenpeitsche',
    kind: PitKind.angriff,
    manaCost: 16,
    cooldown: 7,
    effects: <PitEffect>[SweepCone(power: 1.2, range: 80, fling: 64)],
    description: 'Trifft alle davor und schleudert sie zur Seite.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.natur,
  );

  /// Ein Windstoss, der den Helden trägt und die anderen bremst.
  static const PitAbility rueckenwind = PitAbility(
    id: 'rueckenwind',
    name: 'Rückenwind',
    kind: PitKind.schutz,
    manaCost: 20,
    cooldown: 14,
    effects: <PitEffect>[
      SlowAround(radius: 96, factor: 0.5, seconds: 4),
      SelfBuff(seconds: 4, moveSpeed: 1.3),
    ],
    description: 'Vier Sekunden: Die anderen halb so schnell, du schneller.',
    aim: PitAim.umDenHelden,
    castRange: 0,
    tint: PitTint.zeit,
  );

  /// Eine Eiskugel: Der Gegner erstarrt und zerspringt beim nächsten
  /// Schlag.
  static const PitAbility eisball = PitAbility(
    id: 'eisball',
    name: 'Eisball',
    kind: PitKind.angriff,
    manaCost: 20,
    cooldown: 8,
    effects: <PitEffect>[
      FreezeBolt(power: 1.0, range: 256, stunSeconds: 2),
    ],
    description: 'Friert ein, was sie trifft. Der nächste Schlag darauf ist '
        'sicher kritisch.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.eis,
  );

  // --- AktivesBretts zehn (ADR-0074, `docs/vorlagen/faehigkeiten-2.md`) ---

  /// Ein Schlag, der mit jeder Wiederholung wächst — die 1%-Methode als
  /// Klinge. Billig und schnell bereit: Bezahlt wird mit Mana, nicht mit
  /// Warten (ADR-0073, Mana als Bremse).
  static const PitAbility zinseszins = PitAbility(
    id: 'zinseszins',
    name: 'Zinseszins',
    kind: PitKind.angriff,
    manaCost: 10,
    cooldown: 2,
    effects: <PitEffect>[
      Stacking(step: 0.2, window: 4, maxStacks: 5),
      StrikeNearest(power: 0.8, range: 56),
    ],
    description: 'Ein Schlag. Jede Wiederholung binnen vier Sekunden trifft '
        'ein Fünftel härter, bis zu fünfmal.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.klinge,
  );

  /// Ein Schritt ins Dunkle: weg, unsichtbar, und der erste Schlag daraus
  /// sitzt.
  static const PitAbility schattenschritt = PitAbility(
    id: 'schattenschritt',
    name: 'Schattenschritt',
    kind: PitKind.schutz,
    manaCost: 18,
    cooldown: 9,
    effects: <PitEffect>[
      Blink(distance: 128),
      Vanish(seconds: 2, ambush: 1.5),
    ],
    description: 'Ein Sprung bis vier Felder weit, dann zwei Sekunden '
        'unsichtbar. Der erste Treffer daraus macht anderthalbfachen Schaden.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.seele,
  );

  /// Passiv: Wer einsteckt, schlägt härter zurück.
  static const PitAbility kampfrausch = PitAbility(
    id: 'kampfrausch',
    name: 'Kampfrausch',
    kind: PitKind.angriff,
    manaCost: 0,
    cooldown: 0,
    effects: <PitEffect>[
      RageOnHit(perHit: 0.04, maxStacks: 10, decaySeconds: 4),
    ],
    description: 'Passiv: Jeder Treffer, den du einsteckst, macht dich 4 % '
        'stärker, bis zu zehnmal. Vier Sekunden ohne Treffer, und es fällt ab.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.lava,
  );

  /// Ein Schrei, der die Nahen erstarren lässt und Mut macht.
  static const PitAbility kriegsschrei = PitAbility(
    id: 'kriegsschrei',
    name: 'Kriegsschrei',
    kind: PitKind.angriff,
    manaCost: 24,
    cooldown: 15,
    effects: <PitEffect>[
      StunAround(radius: 64, seconds: 0.8),
      SelfBuff(seconds: 6, attack: 1.2),
    ],
    description: 'Alles um dich steht kurz still, und sechs Sekunden lang '
        'triffst du ein Fünftel härter.',
    aim: PitAim.umDenHelden,
    castRange: 0,
    tint: PitTint.blitz,
  );

  /// Ein Abbild, das mit der eigenen Waffe zuschlägt.
  static const PitAbility spiegelbild = PitAbility(
    id: 'spiegelbild',
    name: 'Spiegelbild',
    kind: PitKind.angriff,
    manaCost: 28,
    cooldown: 22,
    effects: <PitEffect>[
      Companion(
        power: 0.5,
        interval: 0,
        seconds: 10,
        reach: 0,
        stationary: true,
        mirror: true,
      ),
    ],
    description: 'Ein Abbild bleibt zehn Sekunden stehen, wo du es rufst, '
        'und kämpft von dort mit deinem Grundangriff, zu halbem Schaden.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.seele,
  );

  /// Den Schlag kommen sehen und abfangen.
  static const PitAbility parade = PitAbility(
    id: 'parade',
    name: 'Parade',
    kind: PitKind.schutz,
    manaCost: 12,
    cooldown: 6,
    effects: <PitEffect>[Parry(seconds: 0.6, stunSeconds: 1.5)],
    description: 'Kommt in den nächsten 0,6 Sekunden ein Treffer, fängst du '
        'ihn ganz ab, und wer ihn führte, steht still. Zu früh ist umsonst.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.schutz,
  );

  /// Passiv: Wer durchatmet, lädt nach.
  static const PitAbility ruhepuls = PitAbility(
    id: 'ruhepuls',
    name: 'Ruhepuls',
    kind: PitKind.schutz,
    manaCost: 0,
    cooldown: 0,
    effects: <PitEffect>[RestMana(factor: 1.4, idleSeconds: 1)],
    description: 'Passiv: Eine Sekunde ohne eigenen Treffer, und Mana kommt '
        '40 % schneller zurück.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.zeit,
  );

  /// Ein Blitz, der weitererzählt wird.
  static const PitAbility kettenblitz = PitAbility(
    id: 'kettenblitz',
    name: 'Kettenblitz',
    kind: PitKind.angriff,
    manaCost: 22,
    cooldown: 6,
    effects: <PitEffect>[
      ChainBolt(
        power: 1.0,
        range: 256,
        jumps: 3,
        jumpRange: 128,
        falloff: 0.75,
      ),
    ],
    description: 'Ein Blitz springt vom Getroffenen auf bis zu drei weitere, '
        'jeder Sprung ein Viertel schwächer.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.blitz,
  );

  /// Der Held stürmt los und räumt den Weg frei.
  static const PitAbility rammbock = PitAbility(
    id: 'rammbock',
    name: 'Rammbock',
    kind: PitKind.angriff,
    manaCost: 20,
    cooldown: 9,
    effects: <PitEffect>[
      Dash(
        distance: 96,
        impactPower: 1.2,
        impactFling: 48,
        impactStun: 0.5,
      ),
    ],
    description: 'Ein Sturm nach vorn. Wer im Weg steht, wird getroffen, zur '
        'Seite geworfen und steht kurz still.',
    aim: PitAim.richtung,
    castRange: 0,
    tint: PitTint.sand,
  );

  /// Passiv: einmal je Lauf, wenn es eng wird.
  static const PitAbility zweiterAtem = PitAbility(
    id: 'zweiter_atem',
    name: 'Zweiter Atem',
    kind: PitKind.schutz,
    manaCost: 0,
    cooldown: 0,
    effects: <PitEffect>[
      LastStand(threshold: 0.2, heal: 0.25, wardFactor: 0.5, wardSeconds: 2),
    ],
    description: 'Passiv, einmal je Lauf: Fällt dein Leben unter ein Fünftel, '
        'heilst du ein Viertel und nimmst zwei Sekunden lang halben Schaden.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.natur,
  );

  // --- Frederiks Ultimates (ADR-0073) ---

  /// Der Boden bricht ein, Wasser strudelt, alles rutscht hinein. Die
  /// Ultimate, die auf Level 15 über den Baum erreichbar ist.
  static const PitAbility wassergrube = PitAbility(
    id: 'wassergrube',
    name: 'Wassergrube',
    kind: PitKind.umgebung,
    manaCost: 0,
    cooldown: 0,
    effects: <PitEffect>[
      PullToCenter(radius: 96, stunSeconds: 3),
      DamageOverTime(radius: 96, perSecond: 0.3, seconds: 3),
    ],
    description: 'Alles im Umkreis rutscht in die Mitte und steht drei '
        'Sekunden still im Wasser.',
    aim: PitAim.bereich,
    castRange: 224,
    tint: PitTint.eis,
    isUltimate: true,
  );

  /// Eine Pflanze bricht aus dem Boden und schnappt zu.
  static const PitAbility fleischfressendePflanze = PitAbility(
    id: 'fleischfressende_pflanze',
    name: 'Fleischfressende Pflanze',
    kind: PitKind.angriff,
    manaCost: 0,
    cooldown: 0,
    effects: <PitEffect>[
      Companion(
        power: 1.5,
        interval: 1.5,
        seconds: 10,
        reach: 64,
        stationary: true,
        devourBelow: 0.3,
      ),
    ],
    description: 'Zehn Sekunden lang beisst sie, wer ihr nahe kommt — und '
        'frisst, wer fast am Ende ist.',
    aim: PitAim.bereich,
    castRange: 160,
    tint: PitTint.natur,
    isUltimate: true,
  );

  // --- AktivesBretts Ultimates (ADR-0074) ---

  /// Die Tagesform als Moment im Kampf: Wer in Form ist, ist es acht
  /// Sekunden lang ganz.
  static const PitAbility bestform = PitAbility(
    id: 'bestform',
    name: 'Bestform',
    kind: PitKind.schutz,
    manaCost: 0,
    cooldown: 0,
    effects: <PitEffect>[
      Overdrive(
        seconds: 8,
        abilityPower: 1.4,
        attackPower: 1.25,
        cooldownRate: 2,
      ),
      ReduceIncoming(factor: 0.6, seconds: 8),
    ],
    description: 'Acht Sekunden lang: Fähigkeiten treffen 40 % härter und '
        'kosten kein Mana, Abklingzeiten laufen doppelt so schnell, der '
        'Grundangriff trifft ein Viertel härter, und du nimmst 40 % '
        'weniger Schaden.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.stern,
    isUltimate: true,
  );

  /// Die letzten Sekunden noch einmal — nur besser.
  static const PitAbility rueckspulen = PitAbility(
    id: 'rueckspulen',
    name: 'Rückspulen',
    kind: PitKind.schutz,
    manaCost: 0,
    cooldown: 0,
    effects: <PitEffect>[Rewind(seconds: 4, invulnerableSeconds: 1.5)],
    description: 'Du stehst wieder, wo du vor vier Sekunden standest, mit '
        'dem Leben von damals, und bist anderthalb Sekunden unverwundbar.',
    aim: PitAim.selbst,
    castRange: 0,
    tint: PitTint.zeit,
    isUltimate: true,
  );

  /// Die Ultimates — sie liegen nur auf ihrem eigenen Platz.
  static const List<PitAbility> ultimates = <PitAbility>[
    wassergrube,
    fleischfressendePflanze,
    bestform,
    rueckspulen,
  ];

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
    glutspur,
    fanghaken,
    glueckstrank,
    wiederkehr,
    schnappfalle,
    falke,
    steinschlag,
    rankenpeitsche,
    rueckenwind,
    eisball,
    zinseszins,
    schattenschritt,
    kampfrausch,
    kriegsschrei,
    spiegelbild,
    parade,
    ruhepuls,
    kettenblitz,
    rammbock,
    zweiterAtem,
  ];

  /// `null` für eine Id, die in der Grube nichts tut — und für eine
  /// Ultimate: Sie liegt nie auf einem der drei Plätze.
  static PitAbility? byId(String id) {
    for (final ability in all) {
      if (ability.id == id) return ability;
    }
    return null;
  }

  /// Die Ultimate mit [id], oder `null`.
  static PitAbility? ultimateById(String id) {
    for (final ability in ultimates) {
      if (ability.id == id) return ability;
    }
    return null;
  }
}

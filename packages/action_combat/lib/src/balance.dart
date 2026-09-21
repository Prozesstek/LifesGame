import 'ability.dart';

/// Sämtliche Stellschrauben des Echtzeit-Kampfs an einem Ort.
///
/// Gleiche Regel wie bei `combat/balance.dart` und `habits/rewards.dart`:
/// Steht eine dieser Zahlen irgendwo anders im Code, ist das ein Bug.
///
/// Alle Längen sind **Weltpunkte**, und ein Feld der Halle ist
/// [tileSize] gross. Der Renderer skaliert das auf Bildpunkte; die
/// Simulation weiss von Bildschirmen nichts.
abstract final class ActionBalance {
  // --- Zeit ---

  /// Der feste Zeitschritt, mit dem die Welt rechnet.
  ///
  /// **Fest, nicht aus dem Renderer.** Nur so läuft derselbe Lauf mit
  /// demselben Startwert zweimal gleich ab — und nur so lässt sich ein
  /// Dungeon ohne Bildschirm durchsimulieren, wie es
  /// `tool/balance_sim.dart` für den rundenbasierten Kampf tut. Wer hier
  /// das `dt` des Bildschirms einsetzt, verliert beides.
  static const double stepSeconds = 1 / 60;

  /// Wie viele Schritte höchstens nachgeholt werden, wenn ein Bild lange
  /// gedauert hat. Ohne Deckel holt eine hängende Anwendung Minuten auf
  /// einmal nach ("spiral of death").
  ///
  /// Fünfzehn sind eine Viertelsekunde. **Zu niedrig ist auch falsch:**
  /// Bei fünf verlor ein Bild von 100 ms jedes Mal einen Schritt, und die
  /// Welt lief dauerhaft langsamer als die Uhr — der erste Test dieses
  /// Packages hat genau das gemeldet.
  static const int maxCatchUpSteps = 15;

  // --- Die Halle ---

  /// Kantenlänge eines Feldes.
  static const double tileSize = 32;

  // --- Der Held ---

  static const double heroRadius = 11;
  static const double heroSpeed = 120;

  /// Reichweite des Nahkampfs, ab Mittelpunkt gerechnet.
  static const double heroAttackRange = 34;

  /// Sekunden zwischen zwei Schlägen bei einem Wert von [energyReference]
  /// in Energie. Mehr Energie schlägt schneller — das ist der einzige
  /// Ort, an dem Klarheit im Echtzeit-Kampf etwas tut.
  static const double heroAttackCooldown = 0.55;
  static const int energyReference = 8;

  /// Wie stark Energie die Schlagfolge beschleunigt, je Punkt über
  /// [energyReference]. Bei 12 Energie sind das 16 % schneller.
  static const double cooldownPerEnergy = 0.04;

  /// Der Deckel dafür. Ohne ihn wird aus einem Wert ein Exploit.
  static const double minAttackCooldown = 0.3;

  // --- Fähigkeiten ---

  /// Was jede Fähigkeit kostet und kann.
  ///
  /// **Der Sturmschritt richtet keinen Schaden an.** Er ist der Ausweg,
  /// nicht der zweite Angriff — sonst gäbe es keinen Grund, je den
  /// Rundumschlag zu drücken.
  ///
  /// Der Rundumschlag trifft weiter als ein normaler Schlag (58 gegen 34)
  /// und härter (1,5×), kostet dafür fünf Sekunden. Fünf, weil drei ihn
  /// zur Dauerlösung machten: Wer jede dritte Sekunde alles um sich
  /// herum trifft, braucht keine Bewegung mehr.
  static const Map<ActionAbility, AbilitySpec> abilities =
      <ActionAbility, AbilitySpec>{
    ActionAbility.sturmschritt: AbilitySpec(
      cooldown: 3,
      radius: 0,
      power: 0,
      duration: 0.18,
      speedFactor: 4.2,
    ),
    ActionAbility.rundumschlag: AbilitySpec(
      cooldown: 5,
      radius: 58,
      power: 1.5,
      duration: 0,
      speedFactor: 1,
    ),
  };

  // --- Die Gegner ---

  static const double trashRadius = 10;
  static const double trashSpeed = 68;
  static const double trashAttackRange = 30;
  static const double trashAttackCooldown = 1.3;

  /// Der Fernkämpfer: bleibt auf Abstand und schiesst.
  ///
  /// **Er ist der Grund, sich zu bewegen.** Gegen Nahkämpfer allein ist
  /// Stehenbleiben und Draufhalten die beste Antwort — genau das, was
  /// einen Kampf nach zwei Räumen gleichförmig macht.
  static const double archerRadius = 10;
  static const double archerSpeed = 58;

  /// Näher will er nicht heran. Kommt der Held trotzdem, weicht er zurück.
  static const double archerPreferredRange = 175;

  /// Ab wo er schiesst.
  static const double archerShootRange = 230;
  static const double archerCooldown = 1.9;

  static const int archerHp = 26;
  static const int archerAttack = 11;
  static const int archerDefense = 0;

  // --- Geschosse ---

  static const double projectileSpeed = 215;
  static const double projectileRadius = 5;

  /// Nach so vielen Sekunden verfällt ein Geschoss, falls es nie
  /// ankommt. Ohne das sammelt eine lange Partie Geschosse an, die
  /// niemand mehr sieht.
  static const double projectileLifetime = 4;

  // --- Heilkugeln ---

  /// Wie oft ein gefallener Gegner eine Heilkugel hinterlässt.
  ///
  /// **Sie macht aus 27 Einzelkämpfen einen Lauf.** Ohne sie ist die
  /// verbliebene Gesundheit eine Zahl, die nur fällt; mit ihr wird sie
  /// zur Ressource, über die man unterwegs entscheidet.
  static const double orbDropChance = 0.28;

  /// Wie viel eine Kugel heilt, als Anteil der vollen Gesundheit. Ein
  /// Anteil statt einer festen Zahl, damit sie über alle Machtstufen
  /// gleich viel wert ist.
  static const double orbHealShare = 0.08;

  static const double orbRadius = 7;

  /// Ab wo sie von selbst zum Helden fliegt. Ein Prototyp soll nicht am
  /// Pixelgenauen scheitern.
  static const double orbMagnetRange = 64;
  static const double orbMagnetSpeed = 260;

  /// Nach so vielen Sekunden verschwindet eine liegengebliebene Kugel.
  static const double orbLifetime = 12;

  static const double bossRadius = 22;
  static const double bossSpeed = 52;
  static const double bossAttackRange = 46;
  static const double bossAttackCooldown = 1.6;

  /// Ab welcher Entfernung ein Gegner den Helden bemerkt.
  ///
  /// Kein ganzer Raum: Die Halle soll sich in Wellen anfühlen, nicht als
  /// eine einzige Traube, die ab Sekunde eins hinterherläuft.
  static const double aggroRadius = 210;

  /// Hat ein Gegner einmal angefangen, gibt er nicht mehr auf. Ein Gegner,
  /// der abdreht, weil man zwei Schritte zurückgeht, macht jeden Kampf
  /// beliebig.
  static const bool aggroIsPermanent = true;

  /// Wie viele Schritte zwischen zwei Neuberechnungen des Wegfelds
  /// liegen. Bei 12 ist das fuenfmal je Sekunde -- genug, damit niemand
  /// einem Geist hinterherlaeuft, und wenig genug, dass die Flutfuellung
  /// nicht ins Gewicht faellt.
  static const int pathRefreshSteps = 12;

  /// Naeher als das wird nicht ueber das Wegfeld gelaufen, sondern
  /// geradeaus. Auf kurze Sicht ist das Feld zu grob: Es zeigt auf
  /// Feldmitten, und ein Gegner wuerde vor dem Helden stehenbleiben und
  /// zucken.
  static const double directChaseRange = 46;

  // --- Schaden ---

  /// Schaden ist `Angriff * power - Verteidigung / 2`, wie im
  /// rundenbasierten Kampf. Der Nenner hält die Verteidigung spürbar,
  /// ohne dass sie einen Schlag ganz verschluckt.
  static const double defenseDivisor = 2;

  /// Streuung je Schlag, als Anteil. 0,15 heisst 85 % bis 115 %.
  static const double damageSpread = 0.15;

  /// Wie weit ein Treffer den Getroffenen zurückstösst.
  ///
  /// Klein, aber nicht null: Ohne Rückstoss fühlt sich ein Schlag an wie
  /// eine Zahlenänderung. Der Endgegner wird **nicht** geschoben — ein
  /// Koloss, den man durch den Raum schiebt, ist kein Koloss.
  static const double knockback = 9;

  /// Was ein Schlag mindestens anrichtet. Sonst gibt es Gegner, gegen die
  /// ein Lauf nicht endet — derselbe Fall wie der Heal-Lock aus
  /// `gotchas.md`.
  static const int minDamage = 1;

  // --- Lebenspunkte der Gegner ---
  //
  // **Bewusst niedrig.** Der Befund aus der Messung war, dass der
  // schwächste Gegner der Reihe auch nach zwei Monaten sieben Runden
  // braucht. Wenn Fussvolk nicht in ein bis drei Schlägen fällt, trägt
  // eine Halle aus dreissig Gegnern kein Gefühl von Stärke, sondern
  // zwanzig Minuten.

  static const int trashHp = 34;
  static const int trashAttack = 9;
  static const int trashDefense = 1;

  static const int bossHp = 520;
  static const int bossAttack = 22;
  static const int bossDefense = 6;

  // --- Trennung ---

  /// Wie hart sich zwei Figuren auseinanderschieben, die sich
  /// überschneiden. 1 heisst sofort, kleiner heisst weicher.
  static const double separationStrength = 0.5;
}

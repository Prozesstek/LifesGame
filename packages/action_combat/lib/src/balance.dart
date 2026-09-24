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

  // --- Mana (ADR-0039) ---
  //
  // Der Energiewert des Charakters wird in der Grube zu Mana. Er bleibt
  // damit, was er im Rundenkampf war: der Wert, der Fähigkeiten bezahlt.

  /// Mana je Punkt Energie. Tag 0 hat 8 Energie, also 40 Mana.
  static const int manaPerEnergy = 5;

  /// Mana je Sekunde, unabhängig von der Energie.
  static const double manaRegenBase = 4;

  /// Mana je Sekunde zusätzlich, je Punkt Energie. Bei 8 Energie sind das
  /// 2 — zusammen 6 je Sekunde.
  static const double manaRegenPerEnergy = 0.25;

  /// Wie viele Fähigkeitsplätze ein Lauf höchstens mitnimmt — die drei
  /// freien des Charakters (ADR-0016). Der Waffenplatz ist der
  /// Grundangriff, nicht ein Knopf.
  static const int maxAbilitySlots = 3;

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

  /// Wie schnell ein Geschoss des Helden fliegt — schneller als ein
  /// Pfeil, damit ein Funke auf einen fliehenden Schützen ankommt.
  static const double heroBoltSpeed = 330;
  static const double heroBoltRadius = 6;

  /// Wie lange der Brand einer Waffe nachglüht (Sonnenhieb).
  static const double weaponBurnSeconds = 2;

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

  /// Der Kobold: **schneller als der Held** (120), dafür nach zwei, drei
  /// Schlägen erledigt. Die Zahl, auf die es ankommt, ist das Tempo —
  /// wer an ihr dreht, prüft, dass er den Helden noch einholt.
  ///
  /// **Knapp schneller reicht nicht.** Bei 135 holte er einen
  /// weglaufenden Helden nie ein: Der schlägt im Laufen von selbst, und
  /// jeder Schlag stösst 9 Punkte zurück — mehr, als 15 Punkte Vorsprung
  /// je Sekunde bis zum nächsten Schlag gutmachen. `enemy_kinds_test.dart`
  /// hat es gemeldet.
  static const double flinkRadius = 8;
  static const double flinkSpeed = 155;
  static const double flinkAttackRange = 26;
  static const double flinkAttackCooldown = 0.8;
  static const int flinkHp = 16;
  static const int flinkAttack = 6;
  static const int flinkDefense = 0;

  /// Die Fledermaus: noch schneller als der Kobold, noch zerbrechlicher —
  /// und nach jedem Biss [flattererRetreatSeconds] lang auf dem Rückzug.
  /// Wer nur mit dem Grundangriff kämpft, trifft sie selten; das ist der
  /// Sinn.
  static const double flattererRadius = 7;
  static const double flattererSpeed = 165;
  static const double flattererAttackRange = 22;
  static const double flattererAttackCooldown = 1.2;
  static const int flattererHp = 12;
  static const int flattererAttack = 7;
  static const int flattererDefense = 0;

  /// Wie lange sie nach einem Biss davonflattert, bevor sie wiederkommt.
  static const double flattererRetreatSeconds = 0.7;

  /// Wie weit ihr Zickzack seitlich ausschlägt, als Anteil der
  /// Vorwärtsrichtung, und wie schnell es hin und her geht (je Sekunde,
  /// im Bogenmass).
  static const double flattererWobble = 0.7;
  static const double flattererWobbleSpeed = 7;

  /// Der Troll: fünfmal so viel Leben wie Fussvolk, doppelter Schlag,
  /// halbes Tempo. Ein Brocken, kein Endgegner — ein Drittel des Wächters.
  static const double brockenRadius = 18;
  static const double brockenSpeed = 44;
  static const double brockenAttackRange = 42;
  static const double brockenAttackCooldown = 2.0;
  static const int brockenHp = 180;
  static const int brockenAttack = 18;
  static const int brockenDefense = 4;

  /// Wie wahrscheinlich ein gewöhnlicher Raum einen Troll bekommt — auf
  /// Stufe 1 und auf Stufe 30. Er ersetzt dort einen Fussvolk-Platz, die
  /// Zahl der Gegner bleibt also gleich.
  static const double brockenChanceFirst = 0.15;
  static const double brockenChanceLast = 0.6;

  static const double bossRadius = 22;
  static const double bossSpeed = 52;

  /// **Der Auftritt**, sobald das Tor hinter dem Helden zufällt: So lange
  /// fällt der Wächter herab und brüllt, unverwundbar und untätig.
  static const double bossEntranceSeconds = 2.4;

  /// Nach diesem Anteil des Auftritts landet er — erst dann erscheinen
  /// Name und Balken, und der Balken füllt sich im Rest.
  static const double bossLandsShare = 0.35;

  /// Aus dieser Höhe fällt er, in Punkten über seinem Platz. Mehr als
  /// ein halber Bildschirm: Er soll von oben ins Bild kommen.
  static const double bossDropHeight = 420;
  static const double bossAttackRange = 46;
  static const double bossAttackCooldown = 1.6;

  // --- Die Angriffe des Wächters (ADR-0039, Schritt 4) ---
  //
  // **Jeder ist angekündigt.** Seit es keinen Sturmschritt mehr gibt, muss
  // man jedem durch Laufen entkommen können: Die Ankündigung dauert länger,
  // als der Held braucht, um aus dem Ring zu laufen (95 Punkte bei 120 je
  // Sekunde sind 0,8 s — der Ring füllt sich in 1,0 s).

  /// Bodenstoss: ein Ring um den Wächter, der sich füllt, dann trifft.
  static const double bossSlamRadius = 95;
  static const double bossSlamWindup = 1.0;
  static const double bossSlamPower = 1.8;
  static const double bossSlamCooldown = 5.5;

  /// Felswurf: ein grosser, langsamer Brocken — seitlich ausweichen.
  static const double bossThrowCooldown = 5.0;
  static const double bossThrowPower = 1.2;
  static const double bossBoulderSpeed = 150;
  static const double bossBoulderRadius = 12;

  /// Wann nach dem Bemerken der erste Wurf kommt.
  static const double bossFirstThrow = 0.5;

  /// Ab welchem Abstand er wirft statt zu laufen — näher dran stampft er.
  static const double bossThrowMinRange = 110;

  /// Ansturm: erst ab halbem Leben. Eine Linie zeigt die Richtung, dann
  /// rennt er los, bis zur Wand oder bis die Zeit um ist.
  static const double bossChargeWindup = 0.8;
  static const double bossChargeSpeed = 330;
  static const double bossChargeDuration = 0.6;
  static const double bossChargePower = 1.8;
  static const double bossChargeCooldown = 7;

  /// **Er lernt mit der Tiefe dazu.** Auf Stufe 1 stampft er nur; ab
  /// diesen Stufen kommen Felswurf und Ansturm hinzu. Mit allen dreien
  /// schaffte ein frischer Charakter Stufe 1 nur noch zu 40 % statt 90 %
  /// — und das wäre sein allererster Kampf. So wird der Wächter auf dem
  /// Weg nach unten sichtbar gefährlicher, statt es von Anfang an zu sein.
  static const int bossThrowFromStage = 4;
  static const int bossChargeFromStage = 8;

  /// Unter diesem Anteil seines Lebens wird er wütend: Ansturm kommt dazu,
  /// und alle Abklingzeiten laufen so viel schneller ab.
  static const double bossEnrageAt = 0.5;
  static const double bossEnrageTempo = 1.5;

  /// Ab welcher Entfernung ein Gegner den Helden bemerkt — **und nur mit
  /// Blickkontakt**. Durch eine Wand bemerkt ihn niemand, es sei denn, er
  /// wurde getroffen (`ActionWorld._enemiesAct`).
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

  /// So viele Felder am Wegfeld entlang schaut ein Gegner voraus, um den
  /// weitesten frei erreichbaren Punkt anzusteuern. Mehr macht Wege um
  /// lange Ecken glatter und kostet je Gegner und Schritt mehr Prüfungen.
  static const int chaseLookaheadTiles = 8;

  /// So lange darf ein Verfolger auf der Stelle treten, bevor er für
  /// [ghostSeconds] durch Verbündete hindurchgeht. Ohne das verkeilten
  /// sich ein Troll und zwei Fussvolk in einem Durchgang für immer: Jeder
  /// wollte zum selben Wegpunkt, und das Wegschieben hielt alle fest.
  static const double stuckSeconds = 0.6;

  /// Wie weit ein gezielter Schlag neben seine Richtung reicht, zu jeder
  /// Seite, im Bogenmass (etwa 52°). Breit genug, dass ein Daumen trifft,
  /// schmal genug, dass hinter dem Helden niemand getroffen wird.
  static const double strikeHalfAngle = 0.9;

  /// So lange wirkt eine liegende Fläche nach, wenn man sie verlässt —
  /// knapp über dem Takt, damit Bremsen und Brennen nicht flackern.
  static const double zoneLinger = 0.35;
  static const double ghostSeconds = 0.8;

  /// Weniger Bewegung als das gilt als „auf der Stelle".
  static const double stuckDistance = 4;

  // --- Schaden ---

  /// Schaden ist `Angriff * power - Verteidigung / 2`, wie im
  /// rundenbasierten Kampf. Der Nenner hält die Verteidigung spürbar,
  /// ohne dass sie einen Schlag ganz verschluckt.
  static const double defenseDivisor = 2;

  /// Streuung je Schlag der **Gegner**, als Anteil. 0,15 heisst 85 % bis
  /// 115 %. Schmal, damit Sterben nicht zur Lotterie wird.
  static const double damageSpread = 0.15;

  /// Streuung je Schlag des **Helden**: 60 % bis 140 %. Breit wie in
  /// Diablo — ein Treffer soll sich vom nächsten unterscheiden, und ein
  /// hoher soll auffallen. Im Mittel bleibt der Schaden derselbe.
  static const double heroDamageSpread = 0.4;

  /// Wie oft ein Schlag des Helden kritisch trifft, ohne jede Ausrüstung —
  /// und mit welchem Faktor ([ActionStats.critFactor], 2). Dazu kommt, was
  /// die Werte mitbringen.
  static const double heroBaseCritChance = 0.08;

  /// Welcher Anteil des Topfs einer Stufe beim **Wächter** liegt. Der Rest
  /// verteilt sich gleich auf alle anderen Gegner der Grube — jeder Kill
  /// zahlt sofort seinen Teil (ADR-0041).
  static const double bossLootShare = 0.3;

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

  // --- Die Stufen (ADR-0039) ---
  //
  // Die Werte oben sind die **Grundwerte**; jede Stufe setzt einen Faktor
  // darauf (`PitStage`). Gemessen mit `dart run tool/pit_sim.dart`, nicht
  // geschätzt — wer hier dreht, lässt die Simulation laufen.

  /// Faktor auf die Lebenspunkte auf Stufe 1 und Stufe 30.
  /// **Alle Kampfzahlen mal zehn** (ADR-0042) — für Held und Gegner
  /// gleich, das Verhältnis bleibt. Ein Schlag trifft mit 180 statt 18,
  /// ein Level mehr ist dann +7 statt +1, und die Streuung von 60 bis
  /// 140 % ist als Zahl zu sehen statt als 11 oder 12.
  static const int powerScale = 10;

  /// Um wie viel die Gegner auf Stufe 30 **zusätzlich** vervielfacht
  /// sind — Leben, Angriff und Verteidigung (ADR-0042). Geometrisch, von
  /// ×1 auf Stufe 1 bis hierher. Das Gegenstück zu Level und Seltenheit
  /// des Helden: Ohne es wäre ab der Mitte alles geschenkt.
  static const double stagePowerLast = 5.0;

  static const double stageHpFactorFirst = 0.5;
  static const double stageHpFactorLast = 3.4;

  /// Faktor auf den Angriff auf Stufe 1 und Stufe 30.
  static const double stageAttackFactorFirst = 0.6;
  static const double stageAttackFactorLast = 2.5;

  /// Was auf Stufe 30 zur Verteidigung jedes Gegners dazukommt.
  static const int stageDefenseBonusLast = 8;

  /// Räume vor dem Wächter: drei auf Stufe 1, zwei mehr auf Stufe 30.
  static const int stageBaseRooms = 3;
  static const int stageExtraRooms = 2;

  // --- Trennung ---

  /// Wie hart sich zwei Figuren auseinanderschieben, die sich
  /// überschneiden. 1 heisst sofort, kleiner heisst weicher.
  static const double separationStrength = 0.5;
}

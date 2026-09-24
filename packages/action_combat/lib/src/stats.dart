import 'balance.dart';

/// Die Werte, mit denen jemand in die Halle geht.
///
/// Sie kommen von aussen herein, genau wie `CharacterStats` in den
/// rundenbasierten Kampf: Dieses Package kennt weder Gewohnheiten noch
/// Ausrüstung, es rechnet nur mit Zahlen.
class ActionStats {
  const ActionStats({
    required this.attack,
    required this.maxHp,
    required this.defense,
    required this.energy,
    this.damageMultiplier = 1,
    this.hpMultiplier = 1,
    this.defenseMultiplier = 1,
    this.manaMultiplier = 1,
    this.critChance = 0,
    this.critFactor = 2,
    this.gearAttack = 0,
    this.gearMaxHp = 0,
    this.gearDefense = 0,
    this.gearEnergy = 0,
  });

  final int attack;
  final int maxHp;
  final int defense;

  /// Energie beschleunigt die Schlagfolge — der einzige Ort, an dem
  /// Klarheit im Echtzeit-Kampf etwas tut.
  final int energy;

  /// Was die Ausrüstung dazugibt — **schon im Kampfmassstab** (ADR-0048).
  /// Gewürfelte Werte wie 11 statt 10 gingen im kleinen Massstab in der
  /// Rundung verloren; deshalb kommen sie hier getrennt an und werden
  /// **nach** [ActionBalance.powerScale] addiert, aber vor den Faktoren.
  final int gearAttack;
  final int gearMaxHp;
  final int gearDefense;

  /// Energie aus der Ausrüstung, in Zehnteln eines Punkts (ebenfalls
  /// ×[ActionBalance.powerScale]).
  final int gearEnergy;

  /// Die Energie samt Ausrüstung, für Mana und Schlagtempo.
  double get _energie => energy + gearEnergy / ActionBalance.powerScale;

  /// Ein **vervielfachender** Faktor auf den Schaden — seit ADR-0042 das
  /// Level mal die Seltenheit der Waffe ([PitPower.hero]).
  ///
  /// Bis dahin gab es ihn im Spiel nicht: Werte wuchsen additiv und
  /// gedeckelt (ADR-0008), der Angriff also von 13 auf 20. Er war ein
  /// Regler für einen Prototyp; jetzt ist er die Antwort auf die Frage,
  /// die der Prototyp gestellt hat.
  final double damageMultiplier;

  /// Dasselbe für das Leben: Level mal Seltenheit der Rüstung.
  final double hpMultiplier;

  /// Dasselbe für die Verteidigung: das Level.
  final double defenseMultiplier;

  /// Ein Faktor auf Vorrat und Nachfluss des Manas — die Tagesform der
  /// Klarheit. Das Schlagtempo bleibt davon unberührt.
  final double manaMultiplier;

  /// **Die Zahlen, wie die Grube sie führt** — mal [ActionBalance.powerScale]
  /// und mal den Faktoren. Die Welt und jede Anzeige nehmen diese, damit
  /// der Charakterbildschirm nie etwas anderes sagt als der Kampf.
  int get combatAttack =>
      ((attack * ActionBalance.powerScale + gearAttack) * damageMultiplier)
          .round();

  int get combatMaxHp =>
      ((maxHp * ActionBalance.powerScale + gearMaxHp) * hpMultiplier).round();

  int get combatDefense =>
      ((defense * ActionBalance.powerScale + gearDefense) * defenseMultiplier)
          .round();

  /// Wahrscheinlichkeit eines kritischen Treffers, 0 bis 1. Ebenfalls
  /// hypothetisch, aus demselben Grund.
  final double critChance;

  final double critFactor;

  /// Wie viel Mana in den Lauf mitgeht (ADR-0039).
  int get maxMana =>
      (_energie * ActionBalance.manaPerEnergy * manaMultiplier).round();

  /// Mana je Sekunde.
  double get manaRegen =>
      (ActionBalance.manaRegenBase +
          _energie * ActionBalance.manaRegenPerEnergy) *
      manaMultiplier;

  /// Sekunden zwischen zwei Schlägen.
  double get attackCooldown {
    final gespart = (_energie - ActionBalance.energyReference) *
        ActionBalance.cooldownPerEnergy;
    final wert = ActionBalance.heroAttackCooldown - gespart;
    return wert < ActionBalance.minAttackCooldown
        ? ActionBalance.minAttackCooldown
        : wert;
  }

  /// **Tag 0.** Ein frischer Charakter, kein Häkchen gesetzt — die
  /// Grundwerte aus `StatCurve` in `package:habits`.
  static const ActionStats frisch = ActionStats(
    attack: 13,
    maxHp: 160,
    defense: 8,
    energy: 8,
  );

  /// **Die Decke des heutigen Spiels.** Alle vier Werte am Maximum, also
  /// etwa ab Tag 40 bei täglichem Abhaken (gemessen in
  /// `packages/habits/example/curve_sim.dart`), dazu grob ein voller
  /// Satz Ausrüstung.
  ///
  /// Der Abstand zu [frisch] ist der ganze Machtzuwachs, den das Spiel
  /// heute kennt: **plus 130 % Angriff.** Genau diese Zahl steht zur
  /// Debatte.
  static const ActionStats gereift = ActionStats(
    attack: 30,
    maxHp: 314,
    defense: 26,
    energy: 16,
  );

  /// **Was wäre, wenn Macht vervielfachte.** Dieselben Grundwerte wie
  /// [gereift], aber mit einem Faktor und kritischen Treffern, wie sie
  /// ein Beute-getriebenes Spiel hätte.
  ///
  /// Nicht Teil des Spiels. Der Knopf existiert, damit der Unterschied
  /// **spürbar** wird statt nur ausgerechnet.
  static const ActionStats mitPotenz = ActionStats(
    attack: 30,
    maxHp: 314,
    defense: 26,
    energy: 16,
    damageMultiplier: 3,
    critChance: 0.25,
    critFactor: 2.5,
  );
}

/// Wie aus Werten, Level und Ausrüstung die Stärke in der Grube wird
/// (ADR-0042) — die eine Stelle, an der das zusammenkommt.
///
/// **Addiert wird, was aus den Gewohnheiten und den Boni der Ausrüstung
/// kommt; vervielfacht, was aus dem Level und der Seltenheit kommt.** Ein
/// Häkchen bleibt so ein fester Beitrag, und trotzdem schlägt ein
/// Charakter nach zwei Monaten nicht doppelt, sondern vielfach so hart.
///
/// Die Faktoren kommen von aussen, wie alle Zahlen hier: das Level aus
/// `package:progression` (`PowerCurve`), die Seltenheit aus
/// `package:gear` (`GearRarity.powerFactor`), die **Tagesform** aus
/// `package:habits` (`DailyForm`) — je ein Faktor für Angriff, Leben,
/// Abwehr und Mana, 1 an einem Tag ohne Häkchen.
abstract final class PitPower {
  static ActionStats hero({
    required int attack,
    required int maxHp,
    required int defense,
    required int energy,
    required double levelFactor,
    required double weaponFactor,
    required double armorFactor,
    double formAttack = 1,
    double formHp = 1,
    double formDefense = 1,
    double formMana = 1,
    int gearAttack = 0,
    int gearMaxHp = 0,
    int gearDefense = 0,
    int gearEnergy = 0,
  }) {
    return ActionStats(
      attack: attack,
      maxHp: maxHp,
      defense: defense,
      energy: energy,
      gearAttack: gearAttack,
      gearMaxHp: gearMaxHp,
      gearDefense: gearDefense,
      gearEnergy: gearEnergy,
      damageMultiplier: levelFactor * weaponFactor * formAttack,
      hpMultiplier: levelFactor * armorFactor * formHp,
      defenseMultiplier: levelFactor * formDefense,
      manaMultiplier: formMana,
    );
  }
}

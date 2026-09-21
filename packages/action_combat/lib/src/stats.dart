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
    this.critChance = 0,
    this.critFactor = 2,
  });

  final int attack;
  final int maxHp;
  final int defense;

  /// Energie beschleunigt die Schlagfolge — der einzige Ort, an dem
  /// Klarheit im Echtzeit-Kampf etwas tut.
  final int energy;

  /// Ein **vervielfachender** Faktor auf den Schaden.
  ///
  /// Im heutigen Spiel gibt es ihn nicht: Werte wachsen additiv und
  /// gedeckelt (ADR-0008), der Angriff also von 13 auf 20. Das Feld
  /// existiert, damit sich die offene Frage ausprobieren lässt — ob sich
  /// eine Halle erst dann belohnend anfühlt, wenn Macht vervielfacht
  /// statt addiert. Es ist ein Regler für einen Prototyp, keine
  /// Spielregel.
  final double damageMultiplier;

  /// Wahrscheinlichkeit eines kritischen Treffers, 0 bis 1. Ebenfalls
  /// hypothetisch, aus demselben Grund.
  final double critChance;

  final double critFactor;

  /// Sekunden zwischen zwei Schlägen.
  double get attackCooldown {
    final gespart = (energy - ActionBalance.energyReference) *
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

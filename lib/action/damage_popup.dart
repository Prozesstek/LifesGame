import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Eine Zahl, die über einem Treffer aufsteigt und verblasst.
///
/// **Eine reine Rechnung, kein Flame-Gebilde.** Dieselbe Trennung wie bei
/// `damageReadoutFor` im rundenbasierten Kampf, und aus demselben
/// praktischen Grund: Im Spielcode erreicht kein Test die Entscheidung,
/// ohne ein Spiel zu starten — als Klasse mit `update` sind es zehn Zeilen
/// Test.
class DamagePopup {
  DamagePopup({
    required this.text,
    required this.color,
    required this.origin,
    required this.scale,
  });

  /// Aus einem Treffer wird eine Zahl — oder nichts.
  ///
  /// Ein Schlag, der nichts anrichtet, bekommt keine Null über den Kopf:
  /// Eine Null liest sich wie ein Fehler, nicht wie ein Ergebnis.
  static DamagePopup? forHit(HitLanded hit) {
    if (hit.amount <= 0) return null;

    final amSpieler = hit.targetFaction == Faction.held;
    return DamagePopup(
      text: '${hit.amount}',
      color: amSpieler
          ? Palette.enemyOnDark
          : (hit.isCrit ? Palette.goldOnDark : Palette.textOnDark),
      origin: hit.at,
      // Ein kritischer Treffer ist grösser. Er ist der seltene Fall, und
      // Seltenes darf auffallen.
      scale: hit.isCrit ? 1.6 : 1,
    );
  }

  /// Was eine Heilung über dem Kopf zeigt — von einer Kugel oder von
  /// einer Fähigkeit.
  ///
  /// Grün und mit Pluszeichen — dieselbe Regel wie im rundenbasierten
  /// Kampf: Heilung sieht nie aus wie Schaden.
  static DamagePopup forHeal(int amount, Vec2 at) {
    return DamagePopup(
      text: '+$amount',
      color: Palette.successOnDark,
      origin: at,
      scale: 1.1,
    );
  }

  final String text;
  final Color color;
  final Vec2 origin;
  final double scale;

  /// Wie lange eine Zahl steht.
  static const double lifetime = 0.8;

  /// Wie weit sie dabei steigt, in Weltpunkten.
  static const double rise = 26;

  double age = 0;

  bool get isAlive => age < lifetime;

  double get progress => (age / lifetime).clamp(0.0, 1.0);

  /// Wo die Zahl gerade steht.
  Vec2 get position => Vec2(origin.x, origin.y - rise * progress);

  /// Sie verblasst erst auf der zweiten Hälfte — sonst ist sie weg,
  /// bevor man sie gelesen hat.
  double get opacity {
    final p = progress;
    if (p < 0.5) return 1;
    return (1 - (p - 0.5) * 2).clamp(0.0, 1.0);
  }

  void update(double dt) => age += dt;
}

/// Ein Ring, der aufgeht und verblasst — für alles, was knallt.
///
/// Drei Anlässe, drei Farben: ein gefallener Gegner, der Rundumschlag,
/// und der Endgegner, der grösser platzt als sein Fussvolk.
class Burst {
  Burst({
    required this.at,
    required this.color,
    required this.maxRadius,
    required this.lifetime,
    required this.strokeWidth,
  });

  /// Wie lange ein Treffer aufblitzt.
  static const double flashTime = 0.12;

  factory Burst.death(Vec2 at, EnemyKind kind) {
    final gross = kind == EnemyKind.endgegner;
    return Burst(
      at: at,
      color: gross ? Palette.enemy : Palette.enemyOnDark,
      maxRadius: gross ? 90 : 26,
      lifetime: gross ? 0.7 : 0.3,
      strokeWidth: gross ? 5 : 3,
    );
  }

  factory Burst.cleave(Vec2 at) {
    return Burst(
      at: at,
      color: Palette.goldOnDark,
      maxRadius: ActionBalance.abilities[ActionAbility.rundumschlag]!.radius,
      lifetime: 0.28,
      strokeWidth: 4,
    );
  }

  final Vec2 at;
  final Color color;
  final double maxRadius;
  final double lifetime;
  final double strokeWidth;

  double age = 0;

  bool get isAlive => age < lifetime;

  double get progress => (age / lifetime).clamp(0.0, 1.0);

  double get radius => maxRadius * progress;

  double get opacity => (1 - progress).clamp(0.0, 1.0);

  void update(double dt) => age += dt;
}

/// Ein kurzer Bogen dort, wo jemand zugeschlagen hat.
///
/// Ohne ihn sieht ein Kampf aus wie zwei Würfel, die sich berühren.
class SwingMark {
  SwingMark({
    required this.origin,
    required this.direction,
    required this.isHero,
  });

  static const double lifetime = 0.16;

  final Vec2 origin;
  final Vec2 direction;
  final bool isHero;

  double age = 0;

  bool get isAlive => age < lifetime;

  double get progress => (age / lifetime).clamp(0.0, 1.0);

  void update(double dt) => age += dt;
}

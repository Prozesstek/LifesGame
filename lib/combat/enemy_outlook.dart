import 'package:combat/combat.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Eine grobe Einschätzung vor dem Kampf — kein Versprechen.
///
/// Bewusst aus denselben zwei Größen gebildet, die der Spieler sieht: Wie
/// viele Runden brauche ich für seine HP, wie viele braucht er für meine?
/// Wer nachrechnen will, soll es können. Die echte Antwort gibt nur der
/// Kampf — deshalb steht hier „vermutlich" und keine Prozentzahl, die es
/// nicht gibt.
enum EnemyOutlook {
  gut('sollte gut ausgehen', Palette.success),
  knapp('wird knapp', Palette.gold),
  zuStark('vermutlich noch zu stark', Palette.enemy);

  const EnemyOutlook(this.label, this.color);

  final String label;
  final Color color;
}

/// Wie ein Kampf gegen [enemy] voraussichtlich ausgeht.
///
/// **Eine reine Funktion, und das ist der Grund für diese Datei.** Sie
/// stand bis Issue #36 als privates Getter in der Gegnerwahl — an einem
/// Bildschirm, den es nicht mehr gibt. Herausgelöst ist sie in drei
/// Zeilen prüfbar, statt nur mit einem gestarteten Bildschirm. Dieselbe
/// Trennung wie bei `damageReadoutFor` und `tree_layout`.
EnemyOutlook outlookFor(
  EnemyBlueprint enemy, {
  required int playerAttack,
  required int playerHp,
}) {
  // Ohne Angriff gibt es nichts zu rechnen — und ohne diesen Zweig eine
  // Division durch null.
  if (playerAttack <= 0) return EnemyOutlook.zuStark;

  final meineRunden = enemy.maxHp / playerAttack;
  final seineRunden = enemy.attack <= 0
      ? double.infinity
      : playerHp / enemy.attack;

  if (meineRunden < seineRunden * 0.7) return EnemyOutlook.gut;
  if (meineRunden < seineRunden * 1.05) return EnemyOutlook.knapp;
  return EnemyOutlook.zuStark;
}

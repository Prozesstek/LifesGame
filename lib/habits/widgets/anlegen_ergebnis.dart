/// Was beim Anlegen einer Gewohnheit herauskommt (`GewohnheitAnlegen`).
library;

import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

/// Wann, an welchen Tagen und was danach — was jede neue Gewohnheit am
/// Ende gefragt wird (ADR-0052, -0064, -0065, -0066).
class Einrichtung {
  const Einrichtung({
    required this.weekdays,
    this.cue = '',
    this.anchorId,
    this.treat = '',
  });

  /// Wochentage wie bei `Day.weekday`, nie leer.
  final Set<int> weekdays;

  /// Leer heißt „keiner“. Mit Anker immer leer: Satz **oder** Anker.
  final String cue;

  /// Die Gewohnheit, nach der diese drankommt — oder null.
  final String? anchorId;

  /// Leer heißt „nichts“.
  final String treat;
}

/// Was beim Anlegen herauskommt. Das Blatt kennt **keine** Provider:
/// Angelegt und gestartet wird im Bildschirm, damit die Regel, ob noch
/// eine dazu darf, an einer Stelle bleibt — im Controller.
sealed class Angelegt {
  const Angelegt({this.einrichtung});

  /// Null, wenn nicht danach gefragt wurde: Die Liste ist voll, oder
  /// eine pausierte Gewohnheit hat ihren Auslöser schon.
  final Einrichtung? einrichtung;
}

/// Eine eigene, neu geschrieben.
final class EigeneAngelegt extends Angelegt {
  const EigeneAngelegt({
    required this.name,
    required this.area,
    required this.difficulty,
    this.goal,
    super.einrichtung,
  });

  final String name;

  /// Bestimmt Skill **und** Kampfwert (ADR-0085, ADR-0088).
  final SkillArea area;
  final HabitDifficulty difficulty;
  final HabitGoal? goal;
}

/// Eine Vorlage der App oder eine pausierte eigene, wieder gestartet.
final class VorlageGestartet extends Angelegt {
  const VorlageGestartet(this.habitId, {super.einrichtung});

  final String habitId;
}

/// Wie ein Tagesziel gemessen wird.
enum ZielArt {
  keins('Nur abhaken', Icons.check_circle_outline),
  menge('Eine Menge', Icons.format_list_numbered_rounded),
  zeit('Eine Zeit', Icons.timer_outlined);

  const ZielArt(this.label, this.icon);

  final String label;
  final IconData icon;
}

import 'package:flutter/material.dart';

/// Übersetzt die Icon-Id eines Theorieknotens in ein Symbol.
///
/// **Warum die Zuordnung hier steht und nicht im Package.**
/// `packages/theory` kennt Flutter nicht (ADR-0004) und darf deshalb
/// kein `IconData` halten. Der Knoten trägt nur eine Id; was daraus
/// wird, entscheidet die Oberfläche — dieselbe Trennung wie bei den
/// Move-Ids und ihren Animationen (ADR-0015).
///
/// Eine unbekannte Id ist kein Absturz, sondern ein Punkt. Ein neuer
/// Knoten funktioniert also auch, bevor jemand ein Symbol dafür
/// ausgesucht hat.
IconData iconForNode(String iconId) {
  return _icons[iconId] ?? Icons.circle_outlined;
}

const Map<String, IconData> _icons = <String, IconData>{
  // Wurzeln
  'body': Icons.directions_run,
  'mind': Icons.psychology_outlined,
  'science': Icons.science_outlined,
  'society': Icons.groups_outlined,

  // Körper
  'sleep': Icons.bedtime_outlined,
  'run': Icons.fitness_center,
  'food': Icons.restaurant_outlined,
  'pause': Icons.self_improvement_outlined,
  'storm': Icons.thunderstorm_outlined,

  // Geist
  'focus': Icons.center_focus_strong_outlined,
  'thought': Icons.cloud_outlined,
  'endure': Icons.shield_moon_outlined,
  'spark': Icons.bolt_outlined,
  'repeat': Icons.repeat_rounded,

  // Wissenschaft
  'question': Icons.help_outline,
  'link': Icons.link_rounded,
  'flask': Icons.biotech_outlined,
  'dice': Icons.casino_outlined,
  'news': Icons.newspaper_outlined,

  // Gesellschaft
  'people': Icons.people_outline,
  'heart': Icons.favorite_border,
  'hand': Icons.front_hand_outlined,
  'scale': Icons.balance_outlined,
  'ask': Icons.waving_hand_outlined,
};

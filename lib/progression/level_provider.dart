import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progression/progression.dart';

import '../habits/habits_controller.dart';
import '../theory/theory_controller.dart';

/// Gesamte Erfahrung des Spielers.
///
/// Speist sich aus Theorie **und** Gewohnheiten. Erst damit wirkt die
/// Levelsperre des Skillbaums so, wie ADR-0007 sie gemeint hat: Solange
/// nur Lesen Erfahrung brachte, öffnete sich der Baum durchs Lesen.
///
/// Kämpfe zahlen bewusst nicht ein. Das Konzept nennt sie als Ausgabe,
/// nicht als Einnahme — sonst ließe sich der Habit-Teil weggrinden.
final totalXpProvider = Provider<int>((ref) {
  final theory = ref.watch(theoryProgressProvider).totalXp;
  final habits = ref.watch(habitTrackerProvider).totalXp;
  return theory + habits;
});

/// Das Level, das sich aus der Erfahrung ergibt.
///
/// Die Kurve selbst steht in `package:progression` — hier wird nur
/// nachgeschlagen, nicht gerechnet.
final playerLevelProvider = Provider<PlayerLevel>((ref) {
  return LevelCurve.levelFor(ref.watch(totalXpProvider));
});

/// Gold des Spielers, aus denselben beiden Quellen.
final goldProvider = Provider<int>((ref) {
  final theory = ref.watch(theoryProgressProvider).totalGold;
  final habits = ref.watch(habitTrackerProvider).totalGold;
  return theory + habits;
});

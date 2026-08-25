import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progression/progression.dart';

import '../dev/dev_controller.dart';
import '../gear/gear_controller.dart';
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

/// Erfahrung einschließlich Dev-Zuschlag.
///
/// [totalXpProvider] daneben nennt weiterhin nur den **verdienten** Anteil.
/// Beide getrennt zu halten ist der Grund, warum der Charakterbildschirm
/// „davon N aus Dev-Modus" zeigen kann — und warum `DevActions` sich beim
/// Levelschenken nicht über eine Ecke selbst liest (ADR-0021).
///
/// Ohne Entwicklermodus ist der Zuschlag 0 und diese Zahl identisch mit
/// [totalXpProvider].
final effectiveXpProvider = Provider<int>((ref) {
  final int verdient = ref.watch(totalXpProvider);
  final int geschenkt = ref.watch(grantedXpProvider);
  return verdient + geschenkt;
});

/// Das Level, das sich aus der Erfahrung ergibt.
///
/// Die Kurve selbst steht in `package:progression` — hier wird nur
/// nachgeschlagen, nicht gerechnet.
final playerLevelProvider = Provider<PlayerLevel>((ref) {
  return LevelCurve.levelFor(ref.watch(effectiveXpProvider));
});

/// Gold, das eingenommen wurde — vor Ausgaben.
final goldEarnedProvider = Provider<int>((ref) {
  final theory = ref.watch(theoryProgressProvider).totalGold;
  final habits = ref.watch(habitTrackerProvider).totalGold;
  return theory + habits;
});

/// Verfügbares Gold: Zufluss minus Besitz.
///
/// Der Goldstand wird **gerechnet, nicht gezählt** — dieselbe Entscheidung
/// wie bei Erfahrung und Charakterwerten (ADR-0008). Es gibt keinen
/// gespeicherten Kontostand, der von den Buchungen abweichen könnte: Der
/// Zufluss steht in den Häkchen und Lektionen, der Abfluss in der Liste
/// der gekauften Stücke (ADR-0011).
///
/// Deshalb kann diese Zahl nie negativ werden: Gekauft wird nur, was
/// bezahlbar ist, und was gekauft wurde, bleibt gekauft.
final goldProvider = Provider<int>((ref) {
  final int spent = ref.watch(loadoutProvider).spentGold;
  return ref.watch(spendableIncomeProvider) - spent;
});

/// Zufluss einschließlich Dev-Zuschlag, **ohne** Abzug des Besitzes.
///
/// Der `GearController` braucht genau diese Zahl: Er zieht seinen eigenen
/// Besitz selbst ab, weil er ihn sonst über eine Ecke von sich selbst
/// erführe (`gotchas.md`). Sie steht hier und nicht im Dev-Modus, damit
/// `gear_controller` nichts aus `lib/dev/` importieren muss — der
/// Importkreis, der dabei entstünde, lässt die Typinferenz auf `num`
/// zurückfallen.
final spendableIncomeProvider = Provider<int>((ref) {
  final int earned = ref.watch(goldEarnedProvider);
  final int granted = ref.watch(grantedGoldProvider);
  return earned + granted;
});

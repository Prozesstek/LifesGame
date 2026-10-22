import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:haustier/haustier.dart';

import '../habits/habits_controller.dart';
import '../save/save_providers.dart';
import '../skills/skills_provider.dart';

/// Das Haustier (Prototyp, 22.10.2026) — Riverpod-Brücke zu
/// `package:haustier`, **enthält keine Regeln**.
///
/// Gespeichert wird nur, was gewählt wurde ([HaustierStand]); wie weit es
/// gewachsen ist und wie es gelaunt ist, folgt aus den Häkchen
/// ([haustierTageProvider], [haustierLauneProvider]).
final haustierProvider = NotifierProvider<HaustierController, HaustierStand>(
  HaustierController.new,
);

class HaustierController extends Notifier<HaustierStand> {
  @override
  HaustierStand build() => ref.watch(savedGameProvider).haustier;

  /// Wählt das Ei — einmal.
  void waehle(HaustierArt art) => state = state.waehle(art);

  void benenne(String name) => state = state.benenne(name);

  /// Kauft [stueck] für [verfuegbaresGold]. Gibt zurück, ob es geklappt
  /// hat.
  ///
  /// **Das Gold kommt von außen** (`goldProvider`, gelesen im Blatt).
  /// Läse der Controller es selbst, läse er über `goldProvider` sich
  /// selbst — der `CircularDependencyError` aus `gotchas.md` —, und
  /// dieser Datei bliebe der Importkreis über Laden und Level erspart.
  bool kaufe(Zubehoer stueck, {required int verfuegbaresGold}) {
    final neu = state.kaufe(stueck, verfuegbaresGold: verfuegbaresGold);
    if (identical(neu, state)) return false;
    state = neu;
    return true;
  }

  void lege(Zubehoer stueck) {
    state = state.lege(stueck, ref.read(haustierStufeProvider));
  }

  void ablege(ZubehoerPlatz platz) => state = state.ablege(platz);
}

/// **Nur im Entwicklermodus:** wie viele Tage die Vorschau dazurechnet,
/// um spätere Stufen anzusehen, ohne Wochen zu warten. Nie gespeichert.
final haustierVorschauProvider = NotifierProvider<HaustierVorschau, int>(
  HaustierVorschau.new,
);

class HaustierVorschau extends Notifier<int> {
  @override
  int build() => 0;

  void plus(int tage) => state = (state + tage).clamp(0, 2000);

  void zurueck() => state = 0;
}

/// An wie vielen Tagen etwas abgehakt wurde — woran das Tier wächst.
/// Nie weniger als gestern: Ein Tag mit Häkchen bleibt einer.
final haustierTageProvider = Provider<int>((ref) {
  return ref.watch(habitTrackerProvider).daysWithAtLeast(1) +
      ref.watch(haustierVorschauProvider);
});

final haustierStufeProvider = Provider<HaustierStufe>((ref) {
  return HaustierWachstum.stufeFuer(ref.watch(haustierTageProvider));
});

/// Was es gerade tut — aus dem heutigen Tag und der Stunde.
final haustierLauneProvider = Provider<HaustierLaune>((ref) {
  final tracker = ref.watch(habitTrackerProvider);
  final heute = ref.watch(todayProvider);
  return HaustierLaune.aus(
    faellig: tracker.dailyListOn(heute).length,
    erledigt: tracker.completedOn(heute),
    stunde: ref.watch(clockProvider)().hour,
  );
});

/// **Das stärkste Gebiet prägt, wie es ausgewachsen aussieht** — null,
/// solange es jünger ist oder kein Gebiet über Stufe 1 hinaus ist. Bei
/// Gleichstand gewinnt das erste in der Reihenfolge der Gebiete.
final haustierPraegungProvider = Provider<SkillArea?>((ref) {
  final stufe = ref.watch(haustierStufeProvider);
  if (stufe.index < HaustierStufe.ausgewachsen.index) return null;
  final skills = ref.watch(skillsProvider);
  SkillArea? beste;
  var hoechste = 1;
  for (final area in SkillArea.values) {
    final level = skills.of(area).level;
    if (level > hoechste) {
      hoechste = level;
      beste = area;
    }
  }
  return beste;
});

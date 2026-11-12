import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/abilities_controller.dart';
import '../combat/daily_pit_controller.dart';
import '../combat/ladder_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../home/erster_start.dart';
import '../home/erster_start_provider.dart';
import '../lagerfeuer/am_feuer_provider.dart';
import '../progression/level_provider.dart';
import '../save/save_providers.dart';
import '../theory/review_controller.dart';
import '../theory/theory_controller.dart';
import 'neu_gesehen.dart';

/// Wo ein gelber Punkt stehen kann — die Kreise mit etwas Neuem und das
/// Lagerfeuer.
enum NeuOrt { theorie, kampf, faehigkeiten, laden, ausruestung, feuer }

/// Die Marke einer Fähigkeit, innen und am Kreis.
String faehigkeitMarke(String moveId) => 'faehigkeit:$moveId';

/// Die Marke eines Exemplars, innen und am Kreis.
String stueckMarke(String uid) => 'stueck:$uid';

/// **Was es jetzt gibt, je Ort** — reine Rechnung, erzeugt keine Zahl.
///
/// Theorie: die offene Rückfrage, ein freier Talentpunkt (je Level eine
/// Marke). Kampf: der Tagesdungeon, solange heute nicht hinabgestiegen.
/// Fähigkeiten: jede freigeschaltete. Laden: jeder Tag. Ausrüstung: jedes
/// Exemplar. Feuer: was dort heute wartet.
final neuMarkenProvider = Provider<Map<NeuOrt, Set<String>>>((ref) {
  final heute = ref.watch(todayProvider);
  final tag = dayNumberOf(heute);
  final start = ref.watch(ersterStartProvider);
  final feuer = ref.watch(amFeuerProvider);
  final rueckfrageOffen =
      ref.watch(todaysReviewProvider) != null &&
      ref.watch(todaysReviewAnswerProvider) == null;
  return <NeuOrt, Set<String>>{
    NeuOrt.theorie: <String>{
      if (rueckfrageOffen) 'rueckfrage:$tag',
      if (ref.watch(availableTheoryPointsProvider) > 0)
        'talent:${ref.watch(playerLevelProvider).level}',
    },
    NeuOrt.kampf: <String>{
      if (start.zeigtTagesgrube && !ref.watch(dailyPitProvider).hasStarted(tag))
        'tagesdungeon:$tag',
    },
    NeuOrt.faehigkeiten: <String>{
      for (final a in ref.watch(unlockedAbilitiesProvider))
        faehigkeitMarke(a.moveId),
    },
    NeuOrt.laden: <String>{if (start.zeigt(Bereich.laden)) 'laden:$tag'},
    NeuOrt.ausruestung: <String>{
      for (final c in ref.watch(loadoutProvider).ownedCopies)
        stueckMarke(c.uid),
    },
    NeuOrt.feuer: <String>{
      if (start.zeigtTagesaufgaben && feuer.wartet > 0)
        'feuer:$tag:${feuer.rueckfrageOffen}:${feuer.truheWartet}:'
            '${feuer.aufgabenAbholbar}',
    },
  };
});

/// Alles, was innen einen Punkt tragen kann: Fähigkeiten und Stücke.
final neuInnenMarkenProvider = Provider<Set<String>>((ref) {
  final marken = ref.watch(neuMarkenProvider);
  return <String>{
    ...?marken[NeuOrt.faehigkeiten],
    ...?marken[NeuOrt.ausruestung],
  };
});

final neuGesehenProvider = NotifierProvider<NeuGesehenController, NeuGesehen>(
  NeuGesehenController.new,
);

/// Hält, was gesehen ist. **Enthält keine Regeln** — was neu ist, sagt
/// [neuMarkenProvider].
class NeuGesehenController extends Notifier<NeuGesehen> {
  @override
  NeuGesehen build() {
    final gespeichert = ref.watch(savedGameProvider).neu;
    if (gespeichert != null) return gespeichert;
    // **Ein Stand von vor dem Punkt**: Was er schon hat, ist gesehen.
    return NeuGesehen(
      marken: _alle(),
      angetippt: ref.read(neuInnenMarkenProvider),
    );
  }

  Set<String> _alle() => <String>{
    for (final m in ref.read(neuMarkenProvider).values) ...m,
  };

  /// Der Kreis [ort] ist geöffnet.
  void sieh(NeuOrt ort) {
    final neu = ref.read(neuMarkenProvider)[ort] ?? const <String>{};
    if (neu.every(state.marken.contains)) return;
    state = state.sieh(neu, alle: _alle());
  }

  /// [marke] ist innen angetippt.
  void tippe(String marke) {
    if (state.angetippt.contains(marke)) return;
    state = state.tippe(marke, alle: ref.read(neuInnenMarkenProvider));
  }
}

/// Ob der Kreis [ort] einen gelben Punkt trägt. **Nicht im Tutorial**:
/// Dort zeigt der Mentor mit demselben Punkt, wohin es geht.
final neuAmOrtProvider = Provider.family<bool, NeuOrt>((ref, ort) {
  if (ref.watch(ersterStartProvider).schritt != null) return false;
  final gesehen = ref.watch(neuGesehenProvider).marken;
  final marken = ref.watch(neuMarkenProvider)[ort] ?? const <String>{};
  return marken.any((m) => !gesehen.contains(m));
});

/// Ob [marke] innen einen Punkt trägt. Was angelegt ist, kennt man — der
/// Aufrufer fragt nur für Abgelegtes.
final neuInnenProvider = Provider.family<bool, String>((ref, marke) {
  if (ref.watch(ersterStartProvider).schritt != null) return false;
  return !ref.watch(neuGesehenProvider).angetippt.contains(marke);
});

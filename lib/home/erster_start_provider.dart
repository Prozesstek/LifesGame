import 'package:abilities/abilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../achievements/achievements_controller.dart';
import '../character/abilities_controller.dart';
import '../combat/daily_pit_controller.dart';
import '../combat/ladder_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../haustier/haustier_controller.dart';
import '../progression/level_provider.dart';
import '../theory/theory_controller.dart';
import 'erster_start.dart';

/// **Das Geschenk des Mentors** am Ende des Rundgangs: die Fähigkeit, die
/// „Beim Händler" bringt (07.11.2026) — aus dem Katalog gelesen, damit sie
/// nur an einer Stelle steht.
final String geschenkDesMentors = AbilityCatalog.choosable
    .firstWhere(
      (a) => switch (a.source) {
        FromAchievement(:final achievementId) =>
          achievementId == 'beim-haendler',
        _ => false,
      },
    )
    .moveId;

/// Ein Hinweis des Mentors, den man nur lesen muss und wegtippt
/// (06.11.2026) — statt an einer Tat hängt er an diesem Tipp.
enum Hinweis {
  /// Wo die Gewohnheiten wohnen ([Schritt.gewohnheitenZeigen]).
  gewohnheiten,

  /// Was ein Talentpunkt ist ([Schritt.talentpunkt]).
  talentpunkt,

  /// Wo die Fähigkeiten liegen ([Schritt.faehigkeitenZeigen]).
  faehigkeiten,
}

/// Welche [Hinweis]e weggetippt sind — **nur für diese Sitzung**: Wer
/// vor der ersten Seite neu startet, hört sie noch einmal, ein Tipp je
/// Hinweis. Der Spielstand bleibt, wie er ist.
final hinweiseProvider = NotifierProvider<Hinweise, Set<Hinweis>>(Hinweise.new);

class Hinweise extends Notifier<Set<Hinweis>> {
  Hinweise({this.schon = const <Hinweis>{}});

  /// Für Tests, die die Hinweise nicht prüfen.
  final Set<Hinweis> schon;

  @override
  Set<Hinweis> build() => schon;

  void weiter(Hinweis hinweis) => state = <Hinweis>{...state, hinweis};
}

/// Welche Bereiche die Startseite zeigt — **rechnet nichts**, trägt nur
/// zusammen (ADR-0068).
///
/// Die meisten Zahlen kommen aus [achievementStatsProvider]: Dort steht
/// schon, was nur wachsen darf. Tests anderer Bereiche überschreiben
/// diesen Provider mit [ErsterStart.allesOffen].
final ersterStartProvider = Provider<ErsterStart>((ref) {
  final zahlen = ref.watch(achievementStatsProvider);
  final habits = ref.watch(habitTrackerProvider);
  final reihe = ref.watch(ladderProvider);

  return ErsterStart.aus(
    ErsterStartStand(
      hatGewohnheit:
          habits.activeIds.isNotEmpty || habits.customHabits.isNotEmpty,
      haekchen: zahlen.totalChecks,
      // Gewonnen oder verloren — beides ist „war unten“.
      hatGekaempft: reihe.highestDefeated > 0 || reihe.defeats.isNotEmpty,
      stufenGeschafft: reihe.highestDefeated,
      seiten: zahlen.passedLessons,
      grundlagenGelesen: ref.watch(grundlagenGelesenProvider),
      gelernt: ref.watch(unlockedAbilitiesProvider).length,
      // Der erste Eintrag ist immer der Waffenzug.
      angelegt: ref.watch(activeMovesProvider).length - 1,
      goldVerdient: ref.watch(goldEarnedProvider),
      billigstesStueck: GearCatalog.cheapestPrice,
      jeBesessen: zahlen.everOwnedCount,
      level: ref.watch(playerLevelProvider).level,
      // Was je lief: Abgehaktes und alles mit einem Plan (der Plan ist
      // eine Historie, ADR-0064), dazu die eigenen. Fällt nie.
      gewohnheitenJe: <String>{
        ...habits.trackedIds,
        ...habits.activeIds,
        for (final eigene in habits.customHabits) eigene.id,
      }.length,
      // Was ein Stand schon hat, behält er (ADR-0098).
      hatTier: ref.watch(haustierProvider).art != null,
      warAmFeuer: habits.warAmFeuer,
      tagesgrubeVersucht: !ref.watch(dailyPitProvider).isEmpty,
      gewohnheitenGezeigt: ref
          .watch(hinweiseProvider)
          .contains(Hinweis.gewohnheiten),
      talentpunktGezeigt: ref
          .watch(hinweiseProvider)
          .contains(Hinweis.talentpunkt),
      faehigkeitenGezeigt: ref
          .watch(hinweiseProvider)
          .contains(Hinweis.faehigkeiten),
      // Der Rundgang (07.11.2026).
      gekauft: ref.watch(loadoutProvider).boughtCount,
      etwasGesperrt: ref.watch(loadoutProvider).hatGesperrtes,
      geschenkAngelegt: ref
          .watch(chosenAbilitiesProvider)
          .contains(geschenkDesMentors),
    ),
  );
});

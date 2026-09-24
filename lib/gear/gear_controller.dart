import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievements/achievements.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';

import '../combat/ladder_controller.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../achievements/achievement_stats.dart';
import '../save/save_providers.dart';
import '../theory/review_controller.dart';
import '../theory/theory_controller.dart';

/// Bindeglied zwischen Ausrüstung und Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Was etwas kostet, was es bringt und ob
/// ein Kauf zulässig ist, steht in `package:gear`. Dieser Controller reicht
/// durch und hält den laufenden Zustand (ADR-0011).
class GearController extends Notifier<Loadout> {
  @override
  Loadout build() => ref.watch(savedGameProvider).loadout;

  /// Kauft ein Angebot des Tagesladens. Gibt zurück, warum es nicht ging
  /// — oder null bei Erfolg, damit die Oberfläche eine Rückmeldung geben
  /// kann.
  ///
  /// **Warum hier `incomeWithoutAchievementsProvider` und nicht
  /// `goldProvider` steht.** Das verfügbare Gold ist Zufluss minus
  /// Ausgaben — und die Ausgaben sind genau dieser Controller.
  /// `goldProvider` zu lesen hieße, dass sich der Controller über eine Ecke
  /// selbst liest; Riverpod bricht das zu Recht als Zirkelbezug ab. Seit
  /// ADR-0033 gilt dasselbe für die Errungenschaften im Laden: Ihr Gold
  /// wird aus dem eigenen `state` gerechnet.
  PurchaseBlock? buy(GearCopy offer) {
    final ausErrungenschaften = AchievementCatalog.goldFor(
      achievementStatsWithLoadout(ref, state),
    );
    final income =
        ref.read(incomeWithoutAchievementsProvider) + ausErrungenschaften;
    final available = income - state.spentGold;
    // Die hoechste geschlagene Sprosse entscheidet ueber Episches und
    // Legendaeres (ADR-0034). Gelesen, nicht beobachtet: Ein Sieg waehrend
    // des Einkaufens soll den Laden nicht neu aufsetzen.
    final rung = ref.read(ladderProvider).highestDefeated;
    final block = state.blockFor(
      offer,
      availableGold: available,
      highestRung: rung,
    );
    if (block != null) return block;

    state = state.buy(offer, availableGold: available, highestRung: rung);
    return null;
  }

  /// Legt ein Stück ins Inventar, ohne auf den Kontostand zu sehen.
  ///
  /// **Nur für den Entwicklermodus** (ADR-0021). Ein Exemplar mit genau
  /// 100 % und ohne Preis — seit ADR-0048 kostet ein Geschenk nichts, also
  /// braucht es auch keinen Gold-Zuschlag mehr, der den Preis ausgleicht.
  void grant(String itemId) {
    final item = GearCatalog.byId(itemId);
    if (item == null || state.ownsItem(itemId)) return;
    state = state.addFree(
      GearCopy(
        uid: 'dev-$itemId',
        itemId: itemId,
        bonus: item.bonus.scaled,
        paid: 0,
      ),
    );
  }

  /// Nimmt die Beute des Wächters auf (ADR-0048).
  ///
  /// [useKey] heißt: dafür wird ein Schlüssel eingesetzt. Der erste Sieg
  /// auf einer Stufe kostet keinen. Gibt das Exemplar zurück, oder null,
  /// wenn ein Schlüssel nötig war und keiner da ist.
  GearCopy? takeLoot({required int stage, required bool useKey}) {
    if (useKey) {
      final verdient = ref.read(earnedKeysProvider);
      final da = GearKeys.available(
        earned: verdient,
        consumed: state.keysConsumed,
      );
      if (da <= 0) return null;
      state = state.useKey(earned: verdient);
    }
    final beute = GearLoot.drop(
      stage: stage,
      dayIndex: ref.read(dayIndexProvider),
      nth: state.lootCount + 1,
    );
    state = state.addFree(beute);
    return beute;
  }

  /// Verkauft ein Exemplar für ein Viertel seines Katalogpreises
  /// (ADR-0048). Gibt den Erlös zurück, oder null, wenn nichts verkauft
  /// wurde.
  ///
  /// **Kein Gold-Provider im Spiel.** Verkaufen prüft keinen Kontostand,
  /// also entsteht auch nicht der Kreis, den [buy] umgehen muss.
  int? sell(String uid) {
    final item = state.copyByUid(uid)?.item;
    if (item == null) return null;
    state = state.sell(uid);
    return Loadout.refundFor(item);
  }

  /// Verkauft alles Schlechtere auf einmal (`Loadout.junk`). Gibt den
  /// Erlös zurück.
  int sellJunk() {
    final weg = state.junk;
    var erloes = 0;
    for (final copy in weg) {
      final item = copy.item;
      if (item != null) erloes += Loadout.refundFor(item);
    }
    state = state.sellAll(weg.map((c) => c.uid));
    return erloes;
  }

  void equip(String uid) {
    state = state.equip(uid);
  }

  void unequip(GearSlot slot) {
    state = state.unequip(slot);
  }
}

final loadoutProvider = NotifierProvider<GearController, Loadout>(
  GearController.new,
);

/// Die Kampfwerte des Spielers: Gewohnheiten plus Ausrüstung.
///
/// **Die zweite Naht des Kern-Loops.** `package:habits` liefert die Werte
/// aus dem Alltag, `package:gear` den Zuschlag aus dem Laden; beide kennen
/// einander nicht. Hier werden sie addiert — und nur hier. Sobald an einer
/// zweiten Stelle Ausrüstung auf Charakterwerte gerechnet wird, laufen die
/// Zahlen auseinander.
///
/// Addieren ist dabei keine Spielregel im Sinne der Schichtregel aus
/// `CLAUDE.md`: Die Kurven stehen in `habits/rewards.dart` und die Boni in
/// `gear/catalog.dart`. Hier steht nur das Pluszeichen.
final equippedStatsProvider = Provider<EquippedStats>((ref) {
  return EquippedStats(
    base: ref.watch(characterStatsProvider),
    bonus: ref.watch(loadoutProvider).bonus,
  );
});

/// Welcher Tag heute ist, als Zahl seit dem 1.1.1970 — so würfeln
/// Tagesladen und Beute (`package:gear` kennt `Day` nicht).
final dayIndexProvider = Provider<int>((ref) {
  return dayNumberOf(ref.watch(todayProvider));
});

/// Die sechs Angebote des Tagesladens (ADR-0048).
///
/// Gewürfelt in `package:gear` aus dem Datum und der tiefsten
/// geschafften Stufe; hier steht nur, woher beides kommt.
final dailyOffersProvider = Provider<List<GearCopy>>((ref) {
  return DailyShop.offersFor(
    ref.watch(dayIndexProvider),
    highestRung: ref.watch(ladderProvider).highestDefeated,
  );
});

/// Wie viele Schlüssel je verdient wurden: jedes Häkchen, jede bestandene
/// Seite, jede richtige Rückfrage (ADR-0048).
///
/// **Rechnet nicht, zählt nur zusammen** — die drei Zahlen stehen in
/// ihren Packages. Wer eine vierte Quelle dazunimmt, trägt sie hier ein.
final earnedKeysProvider = Provider<int>((ref) {
  // Ausdrücklich getypt: Über den Importkreis zu `theory_controller`
  // fiele die Inferenz sonst auf `num` zurück (`gotchas.md`).
  final int haekchen = ref.watch(habitTrackerProvider).totalChecks;
  final int seiten = ref.watch(passedPagesProvider);
  final int rueckfragen = ref.watch(reviewLogProvider).correctCount;
  return haekchen + seiten + rueckfragen;
});

/// Wie viele Schlüssel gerade da sind — höchstens `GearKeys.cap`.
final availableKeysProvider = Provider<int>((ref) {
  return GearKeys.available(
    earned: ref.watch(earnedKeysProvider),
    consumed: ref.watch(loadoutProvider).keysConsumed,
  );
});

/// Welche Ausrüstungs-Sets gerade wirken.
///
/// **Eine Frage, eine Stelle** (`docs/context/gotchas.md`). Der
/// Charakterbildschirm zeigt sie, der Laden weist darauf hin, und der
/// Kampf rechnet damit — alle drei fragen hier.
final activeSetsProvider = Provider<List<ActiveSet>>((ref) {
  return ref.watch(loadoutProvider).activeSets;
});

/// Charakterwerte einschließlich Ausrüstung, mit Blick auf beide Anteile.
///
/// **Seit ADR-0048 im Kampfmassstab.** Die Werte aus dem Alltag stehen in
/// `package:habits` klein (Angriff 13 bis 20), die Ausrüstung gross (+11).
/// Hier wird beides auf denselben Massstab gebracht, damit „180 Alltag ·
/// +11 Ausrüstung" zusammenpasst. Für den Kampf selbst gehen beide
/// getrennt in `PitPower.hero` — dort ist die Ausrüstung ein eigener
/// Summand, sonst ginge der Wurf in der Rundung verloren.
class EquippedStats {
  const EquippedStats({required this.base, required this.bonus});

  /// Aus dem Alltag, im kleinen Massstab.
  final CharacterStats base;

  /// Aus der Ausrüstung, im Kampfmassstab.
  final GearBonus bonus;

  /// Der Anteil aus dem Alltag, im Kampfmassstab.
  int baseFor(HabitStat stat) => base.valueFor(stat) * GearBonus.combatScale;

  /// Der Anteil aus der Ausrüstung, im Kampfmassstab.
  int bonusFor(HabitStat stat) {
    return switch (stat) {
      HabitStat.staerke => bonus.attack,
      HabitStat.ausdauer => bonus.maxHp,
      HabitStat.disziplin => bonus.defense,
      HabitStat.klarheit => bonus.maxEnergy,
    };
  }

  int totalFor(HabitStat stat) => baseFor(stat) + bonusFor(stat);

  int get attack => totalFor(HabitStat.staerke);
  int get maxHp => totalFor(HabitStat.ausdauer);
  int get defense => totalFor(HabitStat.disziplin);
  int get maxEnergy => totalFor(HabitStat.klarheit);
}

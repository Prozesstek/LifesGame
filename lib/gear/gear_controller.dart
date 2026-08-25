import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';

import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../save/save_providers.dart';

/// Bindeglied zwischen Ausrüstung und Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Was etwas kostet, was es bringt und ob
/// ein Kauf zulässig ist, steht in `package:gear`. Dieser Controller reicht
/// durch und hält den laufenden Zustand (ADR-0011).
class GearController extends Notifier<Loadout> {
  @override
  Loadout build() => ref.watch(savedGameProvider).loadout;

  /// Kauft ein Stück. Gibt zurück, warum es nicht ging — oder null bei
  /// Erfolg, damit die Oberfläche eine Rückmeldung geben kann.
  ///
  /// **Warum hier `goldEarnedProvider` und nicht `goldProvider` steht.**
  /// Das verfügbare Gold ist Zufluss minus Besitz — und der Besitz ist
  /// genau dieser Controller. `goldProvider` zu lesen hieße, dass sich der
  /// Controller über eine Ecke selbst liest; Riverpod bricht das zu Recht
  /// als Zirkelbezug ab. Deshalb wird hier der reine Zufluss geholt und
  /// der eigene Stand direkt abgezogen. Das Ergebnis ist dasselbe, nur
  /// ohne Kreis.
  PurchaseBlock? buy(String itemId) {
    final available = ref.read(spendableIncomeProvider) - state.spentGold;
    final block = state.blockFor(itemId, availableGold: available);
    if (block != null) return block;

    state = state.buy(itemId, availableGold: available);
    return null;
  }

  /// Legt ein Stück ins Inventar, ohne auf den Kontostand zu sehen.
  ///
  /// **Nur für den Entwicklermodus** (ADR-0021). Der Preis wird trotzdem
  /// gebucht — `spentGold` bleibt die Wahrheit über den Besitz. Dass sich
  /// das Geschenk nicht als Minus auswirkt, regelt der Dev-Modus, indem er
  /// den Preis als Zuschlag dazugibt. So bleibt der Goldstand eine
  /// Rechnung und wird nicht zur Ausnahme (ADR-0011).
  void grant(String itemId) {
    if (state.isOwned(itemId)) return;
    state = state.buy(itemId, availableGold: _unlimitedGold);
  }

  /// Genug, um jedes Stück im Katalog zu decken. Steht hier und nicht in
  /// `package:gear`: Es ist kein Preis, sondern das Abschalten der Prüfung.
  static const int _unlimitedGold = 1 << 30;

  void equip(String itemId) {
    state = state.equip(itemId);
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

/// Charakterwerte einschließlich Ausrüstung, mit Blick auf beide Anteile.
///
/// Die Aufteilung bleibt sichtbar, weil der Charakterbildschirm sie zeigen
/// soll: „18 Angriff, davon 3 aus Ausrüstung" sagt dem Spieler, welcher
/// Hebel noch zieht. Nur die Summe zu zeigen verschweigt das.
class EquippedStats {
  const EquippedStats({required this.base, required this.bonus});

  final CharacterStats base;
  final GearBonus bonus;

  int get attack => base.attack + bonus.attack;

  int get maxHp => base.maxHp + bonus.maxHp;

  int get defense => base.defense + bonus.defense;

  int get maxEnergy => base.maxEnergy + bonus.maxEnergy;

  /// Der Anteil aus dem Alltag, ohne Ausrüstung.
  int baseFor(HabitStat stat) => base.valueFor(stat);

  /// Der Anteil aus der Ausrüstung.
  int bonusFor(HabitStat stat) {
    return switch (stat) {
      HabitStat.staerke => bonus.attack,
      HabitStat.ausdauer => bonus.maxHp,
      HabitStat.disziplin => bonus.defense,
      HabitStat.klarheit => bonus.maxEnergy,
    };
  }

  int totalFor(HabitStat stat) => baseFor(stat) + bonusFor(stat);
}

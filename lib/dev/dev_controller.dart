import 'package:abilities/abilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../save/save_providers.dart';
import 'debug_grants.dart';
import 'save_slot.dart';

/// Ob der Entwicklermodus überhaupt existiert.
///
/// **Im Release-Build ist er nicht vorhanden**, nicht bloß versteckt: Jede
/// Stelle, die ihn anbietet, fragt diesen Wert ab, und der Baumschnitt von
/// Dart entfernt den Rest. Damit kann er den 30-Tage-Nachweis aus
/// `ziele.md` nicht beeinflussen, auch nicht versehentlich.
const bool devModeAvailable = kDebugMode;

/// Welcher Spielstand geladen ist. Wird in `main.dart` überschrieben.
final activeSlotProvider = Provider<SaveSlot>((ref) => SaveSlot.real);

/// Hält die Dev-Zuschläge — und **nur** die.
///
/// **Diese Datei importiert bewusst weder `level_provider` noch die
/// übrigen Controller.** Die abgeleiteten Werte rechnen die Zuschläge ein,
/// hängen also von hier ab; würde hier zurückgegriffen, entstünde ein
/// Importkreis und — schlimmer — der `CircularDependencyError` aus
/// `gotchas.md`. Alles, was mehrere Bereiche zugleich anfasst oder eine
/// abgeleitete Zahl braucht, steht in `dev_actions.dart`.
class DevController extends Notifier<DebugGrants> {
  @override
  DebugGrants build() => ref.watch(savedGameProvider).grants;

  void addXp(int amount) => state = state.plus(xp: amount);

  void addGold(int amount) => state = state.plus(gold: amount);

  void addTheoryPoints(int amount) => state = state.plus(theoryPoints: amount);

  void addAbilityPoints(int amount) =>
      state = state.plus(abilityPoints: amount);

  /// Schaltet eine Fähigkeit frei, ohne ihre Bedingung zu erfüllen.
  ///
  /// Bewusst nur freischalten, nicht anlegen: Welche Fähigkeit auf welchem
  /// Platz liegt, bleibt eine Entscheidung des Spielers.
  void grantAbility(String moveId) {
    state = state.withUnlockedAbilities(<String>[moveId]);
  }

  void grantAllAbilities() {
    state = state.withUnlockedAbilities(
      AbilityCatalog.choosable.map((ability) => ability.moveId),
    );
  }

  /// Bucht den Preis eines geschenkten Stücks als Zuschlag.
  ///
  /// Nötig, weil Gold Zufluss minus Besitz ist (ADR-0011): Ohne diese
  /// Gutschrift würde ein geschenktes Stück den Kontostand **senken**.
  void coverPrice(int price) => state = state.plus(gold: price);

  /// Setzt nur die Zuschläge zurück, nicht den Spielstand.
  void resetGrants() => state = const DebugGrants.none();
}

final devGrantsProvider = NotifierProvider<DevController, DebugGrants>(
  DevController.new,
);

final grantedXpProvider = Provider<int>((ref) {
  return ref.watch(devGrantsProvider).bonusXp;
});

final grantedGoldProvider = Provider<int>((ref) {
  return ref.watch(devGrantsProvider).bonusGold;
});

final grantedTheoryPointsProvider = Provider<int>((ref) {
  return ref.watch(devGrantsProvider).bonusTheoryPoints;
});

final grantedAbilityPointsProvider = Provider<int>((ref) {
  return ref.watch(devGrantsProvider).bonusAbilityPoints;
});

/// Fähigkeiten, die per Dev-Modus offen sind — als Move-Ids.
final grantedAbilityIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(devGrantsProvider).unlockedAbilityIds;
});

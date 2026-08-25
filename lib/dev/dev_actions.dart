import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:progression/progression.dart';

import '../gear/gear_controller.dart';
import '../progression/level_provider.dart';
import '../theory/theory_controller.dart';
import 'dev_controller.dart';

/// Alles, was mehrere Bereiche zugleich anfasst oder eine abgeleitete Zahl
/// braucht.
///
/// **Warum das keine Methoden auf [DevController] sind.** Ein Notifier, der
/// einen abgeleiteten Wert liest, in den sein eigener Zustand eingeht,
/// erzeugt einen `CircularDependencyError` — genau der Fall, der bei
/// `goldProvider` schon einmal zugeschlagen hat (`gotchas.md`). Als
/// Funktionen über `ref` gibt es diese Kante nicht: Sie rufen nacheinander
/// auf, statt voneinander abzuhängen.
class DevActions {
  const DevActions(this._ref);

  final WidgetRef _ref;

  DevController get _grants => _ref.read(devGrantsProvider.notifier);

  /// Schenkt genau so viel Erfahrung, wie bis zur nächsten Stufe fehlt.
  ///
  /// **Es gibt keinen Knopf, der eine Stufe direkt setzt**, weil es kein
  /// gespeichertes Level gibt: Die Stufe folgt aus der Kurve. Der Umweg
  /// über die Erfahrung ist deshalb nicht umständlich, sondern der einzige
  /// ehrliche Weg.
  ///
  /// Auf der letzten Stufe passiert nichts — die Kurve endet dort.
  void addLevels(int count) {
    var xp = _ref.read(effectiveXpProvider);
    var gained = 0;

    for (var i = 0; i < count; i++) {
      final level = LevelCurve.levelFor(xp);
      if (level.isMaxLevel) break;

      final missing = LevelCurve.totalXpFor(level.level + 1) - xp;
      gained += missing;
      xp += missing;
    }

    if (gained > 0) _grants.addXp(gained);
  }

  /// Legt ein Stück ins Inventar und schenkt den Preis gleich mit.
  void grantItem(String itemId) {
    final item = GearCatalog.byId(itemId);
    if (item == null) return;
    if (_ref.read(loadoutProvider).isOwned(item.id)) return;

    _ref.read(loadoutProvider.notifier).grant(item.id);
    _grants.coverPrice(item.price);
  }

  void grantAllItems() {
    for (final item in GearCatalog.all) {
      grantItem(item.id);
    }
  }

  /// Öffnet alles: jeden Baumknoten, jede Seite bestanden, jedes Stück im
  /// Besitz, jede Fähigkeit freigeschaltet, reichlich Punkte.
  ///
  /// Der Zustand „Endgame", um späte Bildschirme anzusehen, ohne dreißig
  /// Tage zu spielen.
  void unlockAll() {
    _ref.read(theoryProgressProvider.notifier).unlockEverything();
    grantAllItems();
    _grants
      ..grantAllAbilities()
      ..addTheoryPoints(TheoryPoints.lifetimeTotal)
      ..addAbilityPoints(LevelCurve.maxLevel);
  }
}

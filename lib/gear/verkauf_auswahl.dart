import 'package:gear/gear.dart';

/// **Verkaufen mit Häkchen** (ADR-0083, Issue #136) — reine Rechnung.
///
/// Wie in AktivesBretts Bild aus Summoners War: eine Auswahl einschalten,
/// Stücke anhaken, gesammelt verkaufen. Dieselbe Regel im Siegerblatt
/// und im Rucksack: **Gesperrtes und Getragenes lässt sich nicht
/// anhaken** — das eine soll bleiben, das andere hat man gerade an.
abstract final class VerkaufAuswahl {
  /// Ob [copy] in eine Auswahl darf.
  static bool waehlbar(Loadout loadout, GearCopy copy) =>
      loadout.canSell(copy.uid) && !loadout.isEquipped(copy.uid);

  /// Was die Auswahl beim Verkauf bringt — nur, was davon wählbar ist.
  static int erloes(Loadout loadout, Iterable<String> uids) {
    var summe = 0;
    for (final uid in uids) {
      final copy = loadout.copyByUid(uid);
      final item = copy?.item;
      if (copy == null || item == null) continue;
      if (!waehlbar(loadout, copy)) continue;
      summe += Loadout.refundFor(item);
    }
    return summe;
  }

  /// Die Auswahl ohne das, was inzwischen nicht mehr wählbar ist —
  /// verkauft, gesperrt oder angelegt.
  static Set<String> bereinigt(
    Loadout loadout,
    Set<String> auswahl,
  ) => <String>{
    for (final uid in auswahl)
      if (loadout.copyByUid(uid) case final copy? when waehlbar(loadout, copy))
        uid,
  };
}

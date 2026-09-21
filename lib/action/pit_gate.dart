import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/abilities_controller.dart';

/// Wie viele Plätze belegt sein müssen, damit die Grube offensteht: der
/// Waffenplatz und eine Fähigkeit.
///
/// **Die Kette ist geblieben, der Anlass nicht** (ADR-0039). Gemessen
/// wurde die Zahl im Rundenkampf, wo ein einzelner Zug den ersten Gegner
/// unschlagbar machte (ADR-0018). In der Grube ist Stufe 1 mit den Werten
/// von Tag 0 schlagbar; die Sperre bleibt trotzdem, weil sie die Kette
/// trägt: ohne Handbuch kein Baum, ohne Baum keine Fähigkeit, ohne
/// Fähigkeit kein Kampf. Ob sie das soll, ist in ADR-0039 als offen
/// vermerkt.
const int minMovesForCombat = 2;

/// Ob die Grube offensteht.
///
/// **Eine Bedingung, seit ADR-0025: das Moveset.** Das Handbuch sperrt den
/// Baum, der Baum bringt die Fähigkeiten — die Kette steht damit nur an
/// einer Stelle.
final combatUnlockedProvider = Provider<bool>((ref) {
  return ref.watch(activeMovesProvider).length >= minMovesForCombat;
});

/// Warum die Grube zu ist — oder null, wenn sie offen ist.
///
/// Steht als Satz da und nicht als Fehlerzustand: Ein Kreis, der den Weg
/// nennt, ist besser als einer, der verschwindet (ADR-0018).
final combatBlockReasonProvider = Provider<String?>((ref) {
  if (ref.watch(activeMovesProvider).length >= minMovesForCombat) return null;

  // **Gelernt und angelegt sind zwei verschiedene Dinge.** Wer eine
  // Fähigkeit hat, sie aber auf keinem Platz liegen hat, braucht einen
  // anderen Hinweis als jemand, der noch keine besitzt — sonst schickt
  // der Kreis ihn zurück in die Theorie, wo er nichts mehr zu tun hat.
  final gelernt = ref.watch(unlockedAbilitiesProvider);
  if (gelernt.isEmpty) {
    return 'Erst eine Fähigkeit lernen — sie hängen in der Theorie';
  }

  return 'Leg eine Fähigkeit auf einen freien Platz (Charakter)';
});

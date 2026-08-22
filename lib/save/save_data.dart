import 'dart:convert';

import 'package:abilities/abilities.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:identity/identity.dart';
import 'package:theory/theory.dart';

/// Der komplette Spielstand als ein Wert.
///
/// **Was hier steht und was nicht.** Gespeichert wird ausschließlich, was
/// der Nutzer getan hat: bestandene Lektionen, laufende Gewohnheiten,
/// Häkchen, gekaufte und getragene Ausrüstung. Erfahrung, Gold, Level und
/// Charakterwerte stehen **nicht** hier — sie werden daraus gerechnet
/// (ADR-0008, ADR-0011). Zwei Wahrheiten über denselben Goldstand wären
/// eine Fehlerquelle, die sich nie ganz schließen lässt.
///
/// Daraus folgt auch: Der Stand ist klein. Drei Objekte, ein JSON-String.
/// Genau das war der Grund, Drift zu verschieben (ADR-0010).
class SaveData {
  const SaveData({
    this.theory = const TheoryProgress.empty(),
    this.habits = const HabitTracker.empty(),
    this.loadout = const Loadout.empty(),
    this.identity = const Identity.empty(),
    this.abilities = const ChosenAbilities.empty(),
  });

  const SaveData.empty() : this();

  /// Version des Formats.
  ///
  /// Steht mit im Stand, damit eine spätere Änderung erkennen kann, was
  /// sie vor sich hat. Wird die Zahl erhöht, gehört in [fromJson] ein
  /// Zweig für die alte Form — **nicht** ein Verwerfen des Standes.
  static const int schemaVersion = 1;

  final TheoryProgress theory;
  final HabitTracker habits;
  final Loadout loadout;

  /// Name und gewählter Titel. Die einzige Ausnahme von „gespeichert wird,
  /// was der Nutzer *getan* hat" — ein Name ist eine Eingabe, kein
  /// Ergebnis. Welche Titel verdient sind, steht weiterhin nicht hier,
  /// sondern ergibt sich aus dem Fortschritt (ADR-0013).
  final Identity identity;

  /// Was auf den freien Fähigkeitsslots liegt. Slot 1 steht nicht hier —
  /// der folgt aus der getragenen Waffe (ADR-0017).
  final ChosenAbilities abilities;

  bool get isEmpty {
    return theory.totalXp == 0 &&
        habits.totalChecks == 0 &&
        habits.activeIds.isEmpty &&
        loadout.owned.isEmpty &&
        !identity.hasName &&
        abilities.isEmpty;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': schemaVersion,
      'theory': theory.toJson(),
      'habits': habits.toJson(),
      'gear': loadout.toJson(),
      'identity': identity.toJson(),
      'abilities': abilities.toJson(),
    };
  }

  /// Liest einen Stand. Was nicht lesbar ist, fehlt einfach.
  ///
  /// Die Nachsicht ist hier keine Bequemlichkeit, sondern die Regel: Der
  /// teuerste Fehler, den diese Schicht machen kann, ist eine Streak zu
  /// verlieren. Ein halb lesbarer Stand ist immer besser als keiner.
  factory SaveData.fromJson(Map<String, Object?> json) {
    final theory = json['theory'];
    final habits = json['habits'];
    final gear = json['gear'];
    final identity = json['identity'];
    final abilities = json['abilities'];

    return SaveData(
      theory: theory is Map<String, Object?>
          ? TheoryProgress.fromJson(theory)
          : const TheoryProgress.empty(),
      habits: habits is Map<String, Object?>
          ? HabitTracker.fromJson(habits)
          : const HabitTracker.empty(),
      loadout: gear is Map<String, Object?>
          ? Loadout.fromJson(gear)
          : const Loadout.empty(),
      identity: identity is Map<String, Object?>
          ? Identity.fromJson(identity)
          : const Identity.empty(),
      abilities: abilities is Map<String, Object?>
          ? ChosenAbilities.fromJson(abilities)
          : const ChosenAbilities.empty(),
    );
  }

  String encode() => jsonEncode(toJson());

  /// Liest die Textform. Gibt einen leeren Stand zurück, wenn der Text
  /// kein brauchbares JSON ist — ein beschädigter Eintrag darf die App
  /// nicht am Starten hindern.
  static SaveData decode(String? raw) {
    if (raw == null || raw.isEmpty) return const SaveData.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return const SaveData.empty();
      return SaveData.fromJson(decoded);
    } on FormatException {
      return const SaveData.empty();
    }
  }

  SaveData copyWith({
    TheoryProgress? theory,
    HabitTracker? habits,
    Loadout? loadout,
    Identity? identity,
    ChosenAbilities? abilities,
  }) {
    return SaveData(
      theory: theory ?? this.theory,
      habits: habits ?? this.habits,
      loadout: loadout ?? this.loadout,
      identity: identity ?? this.identity,
      abilities: abilities ?? this.abilities,
    );
  }
}
